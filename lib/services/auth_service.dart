import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ── Sync user document in Firestore ─────────────────────────────────────
  static Future<void> syncUserFirestoreData(
    User user, {
    String? name,
    String? userType,
    String? phone,
  }) async {
    final userDocRef = _firestore.collection('users').doc(user.uid);
    final docSnapshot = await userDocRef.get();

    final List<String> providers = user.providerData
        .map((info) => info.providerId)
        .toList();

    // Map provider IDs to clean provider names ('password', 'phone', 'google')
    final List<String> cleanProviders = providers.map((p) {
      if (p == 'google.com') return 'google';
      if (p == 'phone') return 'phone';
      if (p == 'password') return 'password';
      return p;
    }).toSet().toList();

    Map<String, dynamic> updateData = {
      'updatedAt': FieldValue.serverTimestamp(),
      'authProviders': cleanProviders,
    };

    if (user.email != null && user.email!.isNotEmpty) {
      updateData['email'] = user.email;
    }
    if (user.phoneNumber != null && user.phoneNumber!.isNotEmpty) {
      updateData['phone'] = user.phoneNumber;
    } else if (phone != null && phone.isNotEmpty) {
      updateData['phone'] = phone;
    }

    if (!docSnapshot.exists) {
      // New User
      updateData['name'] = name ?? user.displayName ?? 'User';
      updateData['userType'] = userType ?? 'patient';
      updateData['createdAt'] = FieldValue.serverTimestamp();
      updateData['privacyConsentAt'] = FieldValue.serverTimestamp();
      updateData['privacyConsentVersion'] = '1.0';
      await userDocRef.set(updateData);
    } else {
      // Existing User - update missing fields without overwriting userType unless provided
      final existingData = docSnapshot.data() as Map<String, dynamic>;
      if (name != null && name.isNotEmpty && (existingData['name'] == null || existingData['name'].toString().isEmpty)) {
        updateData['name'] = name;
      }
      if (userType != null && existingData['userType'] == null) {
        updateData['userType'] = userType;
      }
      await userDocRef.update(updateData);
    }
  }

  // ── Phone OTP Verification ────────────────────────────────────────────────
  static Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required Function(String verificationId, int? resendToken) onCodeSent,
    required Function(PhoneAuthCredential credential) onVerificationCompleted,
    required Function(FirebaseAuthException e) onVerificationFailed,
    required Function(String verificationId) onAutoRetrievalTimeout,
    int? resendToken,
  }) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: onVerificationCompleted,
      verificationFailed: onVerificationFailed,
      codeSent: onCodeSent,
      codeAutoRetrievalTimeout: onAutoRetrievalTimeout,
      forceResendingToken: resendToken,
      timeout: const Duration(seconds: 60),
    );
  }

  // ── Sign in or Sign up with Phone OTP Credential ────────────────────────
  static Future<UserCredential> signInWithPhoneCredential({
    required String verificationId,
    required String smsCode,
    String? name,
    String? userType,
    String? rawPhone,
  }) async {
    PhoneAuthCredential credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );

    User? currentUser = _auth.currentUser;
    UserCredential userCredential;

    if (currentUser != null && !currentUser.isAnonymous) {
      // User is already signed in -> link phone credential
      userCredential = await currentUser.linkWithCredential(credential);
    } else {
      // Sign in with phone credential
      userCredential = await _auth.signInWithCredential(credential);
    }

    if (userCredential.user != null) {
      await syncUserFirestoreData(
        userCredential.user!,
        name: name,
        userType: userType,
        phone: rawPhone ?? userCredential.user!.phoneNumber,
      );
    }

    return userCredential;
  }

  // ── Email/Password Authentication ─────────────────────────────────────────
  static Future<UserCredential> signUpWithEmail({
    required String email,
    required String password,
    required String name,
    required String userType,
  }) async {
    UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    if (userCredential.user != null) {
      await syncUserFirestoreData(
        userCredential.user!,
        name: name,
        userType: userType,
      );
    }

    return userCredential;
  }

  static Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) async {
    UserCredential userCredential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    if (userCredential.user != null) {
      await syncUserFirestoreData(userCredential.user!);
    }

    return userCredential;
  }

  // ── Google Sign In ────────────────────────────────────────────────────────
  static Future<UserCredential?> signInWithGoogle({String? userType}) async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn();
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        // User cancelled Google sign-in
        return null;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      User? currentUser = _auth.currentUser;
      UserCredential userCredential;

      if (currentUser != null && !currentUser.isAnonymous) {
        // Link Google credential to existing user
        userCredential = await currentUser.linkWithCredential(credential);
      } else {
        userCredential = await _auth.signInWithCredential(credential);
      }

      if (userCredential.user != null) {
        await syncUserFirestoreData(
          userCredential.user!,
          name: googleUser.displayName,
          userType: userType,
        );
      }

      return userCredential;
    } catch (e) {
      debugPrint('Google Sign-In Error: $e');
      rethrow;
    }
  }

  // ── Link Phone Credential to Existing Logged-In Account ───────────────────
  static Future<UserCredential> linkPhoneCredential({
    required String verificationId,
    required String smsCode,
  }) async {
    User? currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw FirebaseAuthException(
        code: 'no-current-user',
        message: 'No user is currently signed in to link phone credential.',
      );
    }

    PhoneAuthCredential credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );

    UserCredential userCredential = await currentUser.linkWithCredential(credential);
    await syncUserFirestoreData(userCredential.user!);
    return userCredential;
  }

  // ── Link Google Credential to Existing Account ────────────────────────────
  static Future<UserCredential> linkGoogleAccount() async {
    User? currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw FirebaseAuthException(
        code: 'no-current-user',
        message: 'No user is currently signed in to link Google account.',
      );
    }

    final GoogleSignIn googleSignIn = GoogleSignIn();
    final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
    if (googleUser == null) {
      throw Exception('Google sign in was cancelled');
    }

    final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
    final OAuthCredential credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    UserCredential userCredential = await currentUser.linkWithCredential(credential);
    await syncUserFirestoreData(userCredential.user!);
    return userCredential;
  }

  // ── Link Email/Password Credential to Existing Account ─────────────────────
  static Future<UserCredential> linkEmailPasswordCredential({
    required String email,
    required String password,
  }) async {
    User? currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw FirebaseAuthException(
        code: 'no-current-user',
        message: 'No user is currently signed in to link Email credential.',
      );
    }

    AuthCredential credential = EmailAuthProvider.credential(
      email: email,
      password: password,
    );

    UserCredential userCredential = await currentUser.linkWithCredential(credential);
    await syncUserFirestoreData(userCredential.user!);
    return userCredential;
  }

  // ── Fetch Currently Linked Provider IDs for Current User ─────────────────
  static List<String> getLinkedProviders() {
    User? user = _auth.currentUser;
    if (user == null) return [];
    return user.providerData.map((p) => p.providerId).toList();
  }
}
