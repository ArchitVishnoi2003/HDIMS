import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutterapp/services/encryption_service.dart';

class AccessRequestService {
  static final _db = FirebaseFirestore.instance;

  /// Doctor sends a request to access a patient's encrypted health records.
  /// No-ops if a pending request from this doctor already exists.
  static Future<void> requestAccess({
    required String patientUid,
    required String doctorName,
  }) async {
    final doctor = FirebaseAuth.instance.currentUser;
    if (doctor == null) return;

    final existing = await _db
        .collection('access_requests')
        .where('patientUid', isEqualTo: patientUid)
        .where('doctorUid', isEqualTo: doctor.uid)
        .where('status', isEqualTo: 'pending')
        .limit(1)
        .get();
    if (existing.docs.isNotEmpty) return;

    await _db.collection('access_requests').add({
      'patientUid': patientUid,
      'doctorUid': doctor.uid,
      'doctorEmail': doctor.email,
      'doctorName': doctorName,
      'status': 'pending', // pending | approved | denied
      'requestedAt': FieldValue.serverTimestamp(),
      'expiresAt': null,
    });
  }

  /// Patient approves a request.
  /// Decrypts all subcollection records and writes a time-limited session doc
  /// at `users/{patientUid}/access_sessions/{requestId}`.
  static Future<void> approveRequest({
    required String requestId,
    required String patientUid,
    required String doctorUid,
  }) async {
    const subs = ['medications', 'allergies', 'checkups', 'appointments'];
    final sessionData = <String, dynamic>{'doctorUid': doctorUid};

    for (final sub in subs) {
      final snap = await _db
          .collection('users')
          .doc(patientUid)
          .collection(sub)
          .get();
      final records = <Map<String, dynamic>>[];
      for (final doc in snap.docs) {
        final decrypted =
            await EncryptionService.decryptMap(patientUid, doc.data());
        records.add({'id': doc.id, ...decrypted});
      }
      sessionData[sub] = records;
    }

    final expiresAt = DateTime.now().add(const Duration(hours: 4));
    sessionData['expiresAt'] = Timestamp.fromDate(expiresAt);

    await _db
        .collection('users')
        .doc(patientUid)
        .collection('access_sessions')
        .doc(requestId)
        .set(sessionData);

    await _db.collection('access_requests').doc(requestId).update({
      'status': 'approved',
      'expiresAt': Timestamp.fromDate(expiresAt),
    });
  }

  /// Patient denies a request.
  static Future<void> denyRequest(String requestId) async {
    await _db
        .collection('access_requests')
        .doc(requestId)
        .update({'status': 'denied'});
  }

  /// Doctor reads session data. Returns null if not found or expired.
  static Future<Map<String, dynamic>?> readSession(
      String requestId, String patientUid) async {
    final doc = await _db
        .collection('users')
        .doc(patientUid)
        .collection('access_sessions')
        .doc(requestId)
        .get();
    if (!doc.exists) return null;
    final data = doc.data()!;
    final expiresAt = (data['expiresAt'] as Timestamp?)?.toDate();
    if (expiresAt != null && expiresAt.isBefore(DateTime.now())) {
      await doc.reference.delete();
      return null;
    }
    return data;
  }
}
