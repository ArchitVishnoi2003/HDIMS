import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// Top-level function — must be top-level to run in a background isolate.
Uint8List _runDerive(List<String> args) {
  final input = utf8.encode('${args[0]}_${args[1]}_hdimss_v1');
  List<int> current = sha256.convert(input).bytes;
  for (int i = 0; i < 50000; i++) {
    current = sha256.convert([...current, ...input]).bytes;
  }
  return Uint8List.fromList(current);
}

class EncryptionService {
  static const _storage = FlutterSecureStorage();
  static const _keyPrefix = 'priv_enc_';
  static const _prefix = 'enc:';

  // ── Key management ─────────────────────────────────────────────────────────

  /// Derives a 256-bit AES key from [pin]+[uid] in a background isolate and
  /// stores it in the device secure enclave (Android Keystore / iOS Keychain).
  static Future<void> enablePrivacyMode(String uid, String pin) async {
    final keyBytes = await compute(_runDerive, [pin, uid]);
    await _storage.write(
      key: '$_keyPrefix$uid',
      value: base64.encode(keyBytes),
    );
  }

  /// True when a key exists in secure storage for [uid].
  static Future<bool> isEnabled(String uid) =>
      _storage.containsKey(key: '$_keyPrefix$uid');

  /// Removes the key — effectively disables Privacy Mode.
  static Future<void> disablePrivacyMode(String uid) =>
      _storage.delete(key: '$_keyPrefix$uid');

  static Future<enc.Key?> _loadKey(String uid) async {
    final b64 = await _storage.read(key: '$_keyPrefix$uid');
    if (b64 == null) return null;
    return enc.Key(base64.decode(b64));
  }

  // ── Field-level encrypt / decrypt ──────────────────────────────────────────

  /// Returns `'enc:<base64(iv+ciphertext)>'`, or [value] if key is missing.
  static Future<String> encrypt(String uid, String value) async {
    if (value.isEmpty) return value;
    final key = await _loadKey(uid);
    if (key == null) return value;

    final iv = enc.IV.fromSecureRandom(16);
    final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
    final encrypted = encrypter.encrypt(value, iv: iv);
    final combined = Uint8List.fromList([...iv.bytes, ...encrypted.bytes]);
    return '$_prefix${base64.encode(combined)}';
  }

  /// Decrypts `'enc:<base64>'` → original string.
  /// Returns [value] unchanged if it is not prefixed or key is missing.
  static Future<String> decrypt(String uid, String value) async {
    if (!value.startsWith(_prefix)) return value;
    final key = await _loadKey(uid);
    if (key == null) return value;
    try {
      final combined = base64.decode(value.substring(_prefix.length));
      final iv = enc.IV(combined.sublist(0, 16));
      final cipherBytes = enc.Encrypted(combined.sublist(16));
      final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
      return encrypter.decrypt(cipherBytes, iv: iv);
    } catch (_) {
      return value;
    }
  }

  // ── Map helpers ─────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> encryptMap(
      String uid, Map<String, dynamic> data) async {
    final result = <String, dynamic>{};
    for (final entry in data.entries) {
      if (entry.value is String &&
          !(entry.value as String).startsWith(_prefix)) {
        result[entry.key] = await encrypt(uid, entry.value as String);
      } else {
        result[entry.key] = entry.value;
      }
    }
    return result;
  }

  static Future<Map<String, dynamic>> decryptMap(
      String uid, Map<String, dynamic> data) async {
    final result = <String, dynamic>{};
    for (final entry in data.entries) {
      if (entry.value is String &&
          (entry.value as String).startsWith(_prefix)) {
        result[entry.key] = await decrypt(uid, entry.value as String);
      } else {
        result[entry.key] = entry.value;
      }
    }
    return result;
  }

  // ── Bulk transform all four subcollections ──────────────────────────────────

  /// Encrypts all existing records. Called once when Privacy Mode is enabled.
  static Future<void> encryptAllRecords(String uid) =>
      _bulkTransform(uid, doEncrypt: true);

  /// Decrypts all records back to plaintext. Called when Privacy Mode is off.
  static Future<void> decryptAllRecords(String uid) =>
      _bulkTransform(uid, doEncrypt: false);

  // ── List helpers ──────────────────────────────────────────────────────────

  static Future<List<String>> encryptList(String uid, List<String> items) =>
      Future.wait(items.map((s) => encrypt(uid, s)));

  static Future<List<String>> decryptList(String uid, List<String> items) =>
      Future.wait(items.map((s) => decrypt(uid, s)));

  // ── Bulk transform subcollections + user-doc fields ─────────────────────

  static Future<void> _bulkTransform(String uid,
      {required bool doEncrypt}) async {
    const subs = ['medications', 'allergies', 'checkups', 'appointments'];
    final db = FirebaseFirestore.instance;
    for (final sub in subs) {
      final snap =
          await db.collection('users').doc(uid).collection(sub).get();
      for (final doc in snap.docs) {
        final transformed = doEncrypt
            ? await encryptMap(uid, doc.data())
            : await decryptMap(uid, doc.data());
        await doc.reference.update(transformed);
      }
    }

    // Also encrypt/decrypt sensitive user-doc fields
    final userRef = db.collection('users').doc(uid);
    final userDoc = await userRef.get();
    if (!userDoc.exists) return;
    final data = userDoc.data()!;
    final updates = <String, dynamic>{};

    // Insurance string fields
    for (final f in [
      'insuranceProvider', 'policyNumber', 'coverageType', 'validUntil'
    ]) {
      final val = data[f] as String?;
      if (val == null || val.isEmpty) continue;
      if (doEncrypt && !val.startsWith(_prefix)) {
        updates[f] = await encrypt(uid, val);
      } else if (!doEncrypt && val.startsWith(_prefix)) {
        updates[f] = await decrypt(uid, val);
      }
    }

    // Chronic conditions list
    final conditions =
        List<String>.from(data['chronicConditions'] as List? ?? []);
    if (conditions.isNotEmpty) {
      final transformed = <String>[];
      for (final c in conditions) {
        if (doEncrypt && !c.startsWith(_prefix)) {
          transformed.add(await encrypt(uid, c));
        } else if (!doEncrypt && c.startsWith(_prefix)) {
          transformed.add(await decrypt(uid, c));
        } else {
          transformed.add(c);
        }
      }
      updates['chronicConditions'] = transformed;
    }

    if (updates.isNotEmpty) await userRef.update(updates);
  }
}
