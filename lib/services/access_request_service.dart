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

  /// Patient revokes an already-approved request.
  static Future<void> revokeAccess(
      String requestId, String patientUid) async {
    // Delete the decrypted session
    await _db
        .collection('users')
        .doc(patientUid)
        .collection('access_sessions')
        .doc(requestId)
        .delete();
    // Mark the request as revoked
    await _db
        .collection('access_requests')
        .doc(requestId)
        .update({'status': 'revoked'});
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

  /// Checks if a doctor currently has approved (non-expired) access to a patient.
  static Future<bool> hasAccess({
    required String doctorUid,
    required String patientUid,
  }) async {
    final snap = await _db
        .collection('access_requests')
        .where('patientUid', isEqualTo: patientUid)
        .where('doctorUid', isEqualTo: doctorUid)
        .where('status', isEqualTo: 'approved')
        .get();
    for (final doc in snap.docs) {
      final expiresAt = (doc.data()['expiresAt'] as Timestamp?)?.toDate();
      if (expiresAt != null && expiresAt.isAfter(DateTime.now())) {
        return true;
      }
    }
    return false;
  }

  /// Enriches a list of patients (from the `patients` collection) with
  /// up-to-date data from the `users` collection where a linked account exists.
  /// Each enriched patient gets a `_userUid` key so callers know it's linked.
  static Future<List<Map<String, dynamic>>> enrichWithUserData(
      List<Map<String, dynamic>> patients) async {
    for (int i = 0; i < patients.length; i++) {
      final email = patients[i]['email'] as String?;
      if (email == null || email.isEmpty) continue;
      final userQuery = await _db
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();
      if (userQuery.docs.isNotEmpty) {
        final ud = userQuery.docs.first.data();
        patients[i]['_userUid'] = userQuery.docs.first.id;
        patients[i]['_privacyMode'] = ud['privacyModeEnabled'] == true;
        // Overwrite shared fields with user-doc values (patient's own data)
        if (ud['name'] != null && (ud['name'] as String).isNotEmpty) {
          patients[i]['name'] = ud['name'];
        }
        if (ud['phone'] != null && (ud['phone'] as String).isNotEmpty) {
          patients[i]['phone'] = ud['phone'];
        }
        if (ud['address'] != null && (ud['address'] as String).isNotEmpty) {
          patients[i]['address'] = ud['address'];
        }
        if (ud['age'] != null) {
          patients[i]['age'] = ud['age'].toString();
        }
        if (ud['bloodGroup'] != null &&
            (ud['bloodGroup'] as String).isNotEmpty) {
          patients[i]['blood'] = ud['bloodGroup'];
        }
      }
    }
    return patients;
  }

  // ── Doctor-Patient Linking ─────────────────────────────────────────────────

  /// Doctor sends a link request to a patient by email.
  /// Returns an error message or null on success.
  static Future<String?> requestLink({
    required String patientEmail,
    required String doctorName,
  }) async {
    final doctor = FirebaseAuth.instance.currentUser;
    if (doctor == null) return 'Not authenticated';

    // Find patient user account
    final userQuery = await _db
        .collection('users')
        .where('email', isEqualTo: patientEmail)
        .where('userType', isEqualTo: 'patient')
        .limit(1)
        .get();
    if (userQuery.docs.isEmpty) {
      return 'No patient account found with this email.';
    }
    final patientUid = userQuery.docs.first.id;

    // Check if already linked to this doctor
    final existingPatient = await _db
        .collection('patients')
        .where('email', isEqualTo: patientEmail)
        .where('doctorId', isEqualTo: doctor.uid)
        .limit(1)
        .get();
    if (existingPatient.docs.isNotEmpty) {
      return 'This patient is already linked to you.';
    }

    // Check for existing pending link request
    final existingReq = await _db
        .collection('link_requests')
        .where('patientUid', isEqualTo: patientUid)
        .where('doctorUid', isEqualTo: doctor.uid)
        .where('status', isEqualTo: 'pending')
        .limit(1)
        .get();
    if (existingReq.docs.isNotEmpty) {
      return 'A pending link request already exists for this patient.';
    }

    await _db.collection('link_requests').add({
      'doctorUid': doctor.uid,
      'doctorEmail': doctor.email,
      'doctorName': doctorName,
      'patientEmail': patientEmail,
      'patientUid': patientUid,
      'status': 'pending',
      'requestedAt': FieldValue.serverTimestamp(),
    });
    return null; // success
  }

  /// Patient accepts a link request. Creates a patients doc and sets linkedPatientId.
  static Future<void> acceptLink({
    required String requestId,
    required String patientUid,
    required String doctorUid,
  }) async {
    // Read patient's user doc
    final userDoc = await _db.collection('users').doc(patientUid).get();
    final userData = userDoc.data() ?? {};

    // Create a patients collection record for the doctor
    final patientDocRef = await _db.collection('patients').add({
      'name': userData['name'] ?? '',
      'email': userData['email'] ?? '',
      'phone': userData['phone'] ?? '',
      'age': (userData['age'] ?? '').toString(),
      'gender': userData['gender'] ?? '',
      'address': userData['address'] ?? '',
      'pin': '',
      'blood': userData['bloodGroup'] ?? '',
      'medical history': '',
      'vaccination': '',
      'current medication': '',
      'family history': '',
      'allergies': '',
      'doctorId': doctorUid,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // Set linkedPatientId on the patient's user doc
    await _db.collection('users').doc(patientUid).update({
      'linkedPatientId': patientDocRef.id,
    });

    // Mark link request as accepted
    await _db.collection('link_requests').doc(requestId).update({
      'status': 'accepted',
    });
  }

  /// Patient denies a link request.
  static Future<void> denyLink(String requestId) async {
    await _db
        .collection('link_requests')
        .doc(requestId)
        .update({'status': 'denied'});
  }

  /// Returns the first valid (non-expired) approved request ID for a doctor+patient pair.
  static Future<String?> getApprovedRequestId({
    required String doctorUid,
    required String patientUid,
  }) async {
    final snap = await _db
        .collection('access_requests')
        .where('patientUid', isEqualTo: patientUid)
        .where('doctorUid', isEqualTo: doctorUid)
        .where('status', isEqualTo: 'approved')
        .get();
    for (final doc in snap.docs) {
      final expiresAt = (doc.data()['expiresAt'] as Timestamp?)?.toDate();
      if (expiresAt != null && expiresAt.isAfter(DateTime.now())) {
        return doc.id;
      }
    }
    return null;
  }
}
