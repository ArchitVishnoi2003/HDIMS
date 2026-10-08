import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutterapp/services/auth_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();

  bool _isSignUp = true;
  bool _isLoading = false;
  bool _consentGiven = false;
  String _selectedUserType = 'patient';
  String _selectedLoginType = 'patient';

  // Auth method: 'email' or 'phone'
  String _authMethod = 'email';

  // OTP state
  String? _verificationId;
  int? _resendToken;
  int _timerSeconds = 60;
  Timer? _timer;

  void _startTimer() {
    _timerSeconds = 60;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_timerSeconds > 0) {
        setState(() => _timerSeconds--);
      } else {
        timer.cancel();
      }
    });
  }

  // ── Handle Email/Password Auth ───────────────────────────────────────────
  Future<void> _handleEmailAuth() async {
    if (_emailController.text.trim().isEmpty || _passwordController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all email and password fields')),
      );
      return;
    }

    if (_isSignUp && _nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your full name')),
      );
      return;
    }

    setState(() => _isLoading = true);
    final messenger = ScaffoldMessenger.of(context);

    try {
      if (_isSignUp) {
        await AuthService.signUpWithEmail(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
          name: _nameController.text.trim(),
          userType: _selectedUserType,
        );
        messenger.showSnackBar(
          const SnackBar(content: Text('Account created successfully!')),
        );
        _navigateToDashboard(_selectedUserType);
      } else {
        await AuthService.signInWithEmail(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        User? currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser != null) {
          DocumentSnapshot userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(currentUser.uid)
              .get();

          String? storedType;
          if (userDoc.exists) {
            final userData = userDoc.data() as Map<String, dynamic>;
            storedType = userData['userType'] as String?;

            if (storedType == null) {
              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(currentUser.uid)
                  .update({'userType': _selectedLoginType});
              storedType = _selectedLoginType;
            }
          }

          if (storedType != null && storedType != _selectedLoginType) {
            await FirebaseAuth.instance.signOut();
            final typeLabel = storedType == 'hospital' ? 'Hospital/Doctor' : 'Patient';
            messenger.showSnackBar(
              SnackBar(
                content: Text(
                  'This account is registered as a $typeLabel account. '
                  'Please select the correct login type.',
                ),
                backgroundColor: Colors.red[700],
                duration: const Duration(seconds: 4),
              ),
            );
            setState(() => _isLoading = false);
            return;
          }
        }

        messenger.showSnackBar(
          const SnackBar(content: Text('Signed in successfully!')),
        );
        _navigateToDashboard(_selectedLoginType);
      }
    } on FirebaseAuthException catch (e) {
      String message = 'An error occurred';
      switch (e.code) {
        case 'weak-password':
          message = 'The password provided is too weak.';
          break;
        case 'email-already-in-use':
          message = 'An account already exists for that email.';
          break;
        case 'user-not-found':
          message = 'No user found for that email.';
          break;
        case 'wrong-password':
        case 'invalid-credential':
          message = 'Invalid email or password.';
          break;
        case 'invalid-email':
          message = 'The email address is not valid.';
          break;
        default:
          message = e.message ?? e.code;
      }
      messenger.showSnackBar(SnackBar(content: Text(message)));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Handle Phone Send OTP ────────────────────────────────────────────────
  String _formatPhoneNumber(String input) {
    String trimmed = input.trim();
    if (trimmed.startsWith('+')) {
      return trimmed;
    }
    // Default country code if not specified (+91 for India, customizable)
    return '+91$trimmed';
  }

  Future<void> _handleSendOtp() async {
    String rawPhone = _phoneController.text.trim();
    if (rawPhone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid phone number')),
      );
      return;
    }

    if (_isSignUp && _nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your full name')),
      );
      return;
    }

    String formattedPhone = _formatPhoneNumber(rawPhone);

    setState(() => _isLoading = true);
    final messenger = ScaffoldMessenger.of(context);

    try {
      await AuthService.verifyPhoneNumber(
        phoneNumber: formattedPhone,
        resendToken: _resendToken,
        onCodeSent: (String verificationId, int? resendToken) {
          if (!mounted) return;
          setState(() {
            _verificationId = verificationId;
            _resendToken = resendToken;
            _isLoading = false;
          });
          _startTimer();
          messenger.showSnackBar(
            SnackBar(content: Text('OTP sent to $formattedPhone')),
          );
          _showOtpModal(formattedPhone);
        },
        onVerificationCompleted: (PhoneAuthCredential credential) async {
          if (!mounted) return;
          final nav = Navigator.of(context);
          messenger.showSnackBar(
            const SnackBar(content: Text('Phone number automatically verified!')),
          );
          try {
            UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
            if (userCredential.user != null) {
              await AuthService.syncUserFirestoreData(
                userCredential.user!,
                name: _isSignUp ? _nameController.text.trim() : null,
                userType: _isSignUp ? _selectedUserType : _selectedLoginType,
                phone: formattedPhone,
              );
            }
            if (mounted && nav.canPop()) {
              nav.pop(); // Close sheet if open
            }
            _navigateToDashboard(_isSignUp ? _selectedUserType : _selectedLoginType);
          } catch (e) {
            debugPrint('Auto verification sign-in error: $e');
          }
        },
        onVerificationFailed: (FirebaseAuthException e) {
          if (!mounted) return;
          setState(() => _isLoading = false);
          messenger.showSnackBar(
            SnackBar(content: Text('OTP verification failed: ${e.message}')),
          );
        },
        onAutoRetrievalTimeout: (String verificationId) {
          if (!mounted) return;
          _verificationId = verificationId;
        },
      );
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      messenger.showSnackBar(
        SnackBar(content: Text('Failed to send OTP: ${e.toString()}')),
      );
    }
  }

  // ── Handle Verify OTP ─────────────────────────────────────────────────────
  Future<void> _handleVerifyOtp(StateSetter setModalState, String formattedPhone) async {
    final smsCode = _otpController.text.trim();
    if (smsCode.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter 6-digit OTP code')),
      );
      return;
    }

    if (_verificationId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Verification ID missing. Please resend OTP.')),
      );
      return;
    }

    setModalState(() => _isLoading = true);
    final messenger = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context);

    try {
      await AuthService.signInWithPhoneCredential(
        verificationId: _verificationId!,
        smsCode: smsCode,
        name: _isSignUp ? _nameController.text.trim() : null,
        userType: _isSignUp ? _selectedUserType : _selectedLoginType,
        rawPhone: formattedPhone,
      );

      if (mounted) {
        nav.pop(); // Close OTP modal
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              _isSignUp ? 'Account created & verified!' : 'Phone signed in successfully!',
            ),
          ),
        );
        _navigateToDashboard(_isSignUp ? _selectedUserType : _selectedLoginType);
      }
    } on FirebaseAuthException catch (e) {
      setModalState(() => _isLoading = false);
      String msg = 'Invalid OTP code.';
      if (e.code == 'invalid-verification-code') {
        msg = 'Invalid OTP code entered. Please try again.';
      } else if (e.code == 'credential-already-in-use') {
        msg = 'This phone number is already linked to another account.';
      }
      messenger.showSnackBar(SnackBar(content: Text(msg)));
    } catch (e) {
      setModalState(() => _isLoading = false);
      messenger.showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    }
  }

  // ── Show OTP Bottom Sheet ─────────────────────────────────────────────────
  void _showOtpModal(String formattedPhone) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(modalCtx).viewInsets.bottom,
              ),
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
                ),
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF6C5CE7).withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.phonelink_ring, color: Color(0xFF6C5CE7)),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Verify Phone Number',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Code sent to $formattedPhone',
                              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: _otpController,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 24,
                        letterSpacing: 8,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF6C5CE7),
                      ),
                      decoration: InputDecoration(
                        counterText: '',
                        hintText: '000000',
                        hintStyle: TextStyle(
                          color: Colors.grey[300],
                          letterSpacing: 8,
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF8F9FA),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF6C5CE7), width: 2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _timerSeconds > 0
                              ? 'Resend code in ${_timerSeconds}s'
                              : 'Didn\'t receive code?',
                          style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                        ),
                        TextButton(
                          onPressed: _timerSeconds == 0
                              ? () {
                                  Navigator.of(modalCtx).pop();
                                  _handleSendOtp();
                                }
                              : null,
                          child: Text(
                            'Resend OTP',
                            style: TextStyle(
                              color: _timerSeconds == 0
                                  ? const Color(0xFF6C5CE7)
                                  : Colors.grey,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isLoading
                            ? null
                            : () => _handleVerifyOtp(setModalState, formattedPhone),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6C5CE7),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text(
                                'Verify & Continue',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ── Handle Google Sign In ─────────────────────────────────────────────────
  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);
    final messenger = ScaffoldMessenger.of(context);

    try {
      UserCredential? credential = await AuthService.signInWithGoogle(
        userType: _isSignUp ? _selectedUserType : _selectedLoginType,
      );

      if (credential == null) {
        // User cancelled Google sign in
        setState(() => _isLoading = false);
        return;
      }

      messenger.showSnackBar(
        const SnackBar(content: Text('Signed in with Google successfully!')),
      );

      // Determine user type from Firestore
      User? user = credential.user;
      String userTypeToNavigate = _isSignUp ? _selectedUserType : _selectedLoginType;

      if (user != null) {
        DocumentSnapshot doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        if (doc.exists) {
          final data = doc.data() as Map<String, dynamic>;
          userTypeToNavigate = data['userType'] ?? userTypeToNavigate;
        }
      }

      _navigateToDashboard(userTypeToNavigate);
    } on FirebaseAuthException catch (e) {
      String msg = e.message ?? 'Google Sign-In failed';
      if (e.code == 'credential-already-in-use') {
        msg = 'This Google account is already linked with another user.';
      }
      messenger.showSnackBar(SnackBar(content: Text(msg)));
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Google Sign-In Error: ${e.toString()}')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Privacy Modal ────────────────────────────────────────────────────────
  Future<void> _showPrivacyModal() async {
    final ScrollController scrollCtrl = ScrollController();
    bool scrolledToBottom = false;
    bool localConsent = _consentGiven;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setModal) {
          scrollCtrl.addListener(() {
            if (!scrolledToBottom &&
                scrollCtrl.position.pixels >=
                    scrollCtrl.position.maxScrollExtent - 60) {
              setModal(() => scrolledToBottom = true);
            }
          });
          return DraggableScrollableSheet(
            initialChildSize: 0.92,
            maxChildSize: 0.95,
            minChildSize: 0.5,
            builder: (_, __) => Container(
              decoration: const BoxDecoration(
                color: Color(0xFFF8F9FA),
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 10),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[400],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF6C5CE7), Color(0xFF74B9FF)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.privacy_tip, color: Colors.white, size: 22),
                        SizedBox(width: 10),
                        Text(
                          'Privacy Policy & Terms',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Scrollbar(
                      controller: scrollCtrl,
                      child: SingleChildScrollView(
                        controller: scrollCtrl,
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _privacySection(
                              '1. What We Collect',
                              'HDIMS collects personal and health information including your name, email address, phone number, contact details, medical history, allergies, medications, appointment records, vital signs, and AI-generated health recommendations. This information is collected when you create an account or enter records in the app.',
                            ),
                            _privacySection(
                              '2. How We Use Your Data',
                              'Your data is used solely to provide health record management features, to allow authorized healthcare providers to view your records, and to personalize AI-driven health recommendations. We do not sell, rent, or share your personal information with third parties for marketing purposes.',
                            ),
                            _privacySection(
                              '3. Data Storage & Security',
                              'All data is stored in Google Firebase (Firestore), a HIPAA-compliant cloud platform. You may optionally enable Privacy Mode, which encrypts your health records using AES-256 on your device before they are uploaded.',
                            ),
                            _privacySection(
                              '4. AI Health Assistant',
                              'When you use the AI diet and health assistant, your messages are sent to Google\'s Gemini AI service for processing.',
                            ),
                            _privacySection(
                              '5. Your Rights',
                              'You have the right to access, correct, and delete your personal health data at any time from within the app.',
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Last updated: March 2026 • Version 1.0',
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 12,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 8,
                          offset: const Offset(0, -2),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (!scrolledToBottom)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              children: [
                                Icon(Icons.arrow_downward, size: 14, color: Colors.orange[700]),
                                const SizedBox(width: 5),
                                Text(
                                  'Scroll down to read the full policy',
                                  style: TextStyle(color: Colors.orange[700], fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        Row(
                          children: [
                            Checkbox(
                              value: localConsent,
                              activeColor: const Color(0xFF6C5CE7),
                              onChanged: scrolledToBottom
                                  ? (v) => setModal(() => localConsent = v ?? false)
                                  : null,
                            ),
                            const Expanded(
                              child: Text(
                                'I have read and agree to the Privacy Policy and Terms of Use',
                                style: TextStyle(fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: localConsent ? () => Navigator.of(ctx).pop(true) : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF6C5CE7),
                              disabledBackgroundColor: Colors.grey[300],
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Confirm & Continue',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        });
      },
    ).then((result) {
      if (result == true) {
        setState(() => _consentGiven = true);
      }
      scrollCtrl.dispose();
    });
  }

  Widget _privacySection(String title, String body) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF6C5CE7),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            body,
            style: const TextStyle(fontSize: 13, color: Colors.black87, height: 1.6),
          ),
        ],
      ),
    );
  }

  void _navigateToDashboard(String userType) {
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        if (userType == 'hospital') {
          Navigator.of(context).pushReplacementNamed('/dashboard');
        } else {
          Navigator.of(context).pushReplacementNamed('/patient-dashboard');
        }
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _otpController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                const SizedBox(height: 20),

                // Header Section
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6C5CE7), Color(0xFF74B9FF)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF6C5CE7).withValues(alpha: 0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: const Icon(
                          Icons.health_and_safety,
                          size: 36,
                          color: Color(0xFF6C5CE7),
                        ),
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        "HDIMS Health",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        "Smart & Secure Health Ledger",
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 25),

                // Form Section Card
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        _isSignUp ? 'Create Account' : 'Welcome Back!',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _isSignUp
                            ? 'Select preferred method to register'
                            : 'Select preferred method to sign in',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Auth Method Switcher Tabs (Email vs Phone)
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8F9FA),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() => _authMethod = 'email'),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  decoration: BoxDecoration(
                                    color: _authMethod == 'email'
                                        ? const Color(0xFF6C5CE7)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.email_outlined,
                                        size: 18,
                                        color: _authMethod == 'email'
                                            ? Colors.white
                                            : Colors.grey[700],
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Email & Pass',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                          color: _authMethod == 'email'
                                              ? Colors.white
                                              : Colors.grey[700],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() => _authMethod = 'phone'),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  decoration: BoxDecoration(
                                    color: _authMethod == 'phone'
                                        ? const Color(0xFF6C5CE7)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.phone_android,
                                        size: 18,
                                        color: _authMethod == 'phone'
                                            ? Colors.white
                                            : Colors.grey[700],
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Phone OTP',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                          color: _authMethod == 'phone'
                                              ? Colors.white
                                              : Colors.grey[700],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Name Field for Sign Up
                      if (_isSignUp) ...[
                        _buildTextField(_nameController, 'Full Name', Icons.person),
                        const SizedBox(height: 16),
                        _buildUserTypeSelector(),
                        const SizedBox(height: 16),
                      ],

                      // Method-specific input fields
                      if (_authMethod == 'email') ...[
                        _buildTextField(_emailController, 'Email Address', Icons.email,
                            keyboardType: TextInputType.emailAddress),
                        const SizedBox(height: 16),
                        _buildTextField(_passwordController, 'Password', Icons.lock,
                            isPassword: true),
                      ] else ...[
                        _buildTextField(
                          _phoneController,
                          'Phone Number (e.g. +91 9876543210)',
                          Icons.phone,
                          keyboardType: TextInputType.phone,
                        ),
                      ],

                      // Login Type Selector for Sign In
                      if (!_isSignUp) ...[
                        const SizedBox(height: 16),
                        _buildLoginTypeSelector(),
                      ],

                      const SizedBox(height: 24),

                      // Consent check box for Sign Up
                      if (_isSignUp) ...[
                        InkWell(
                          onTap: _showPrivacyModal,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: _consentGiven
                                  ? const Color(0xFF6C5CE7).withValues(alpha: 0.08)
                                  : Colors.orange.withValues(alpha: 0.07),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: _consentGiven
                                    ? const Color(0xFF6C5CE7).withValues(alpha: 0.4)
                                    : Colors.orange.withValues(alpha: 0.5),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  _consentGiven
                                      ? Icons.check_circle
                                      : Icons.privacy_tip_outlined,
                                  color: _consentGiven
                                      ? const Color(0xFF6C5CE7)
                                      : Colors.orange[700],
                                  size: 20,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    _consentGiven
                                        ? 'Privacy Policy accepted'
                                        : 'Read & accept Privacy Policy (required)',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: _consentGiven
                                          ? const Color(0xFF6C5CE7)
                                          : Colors.orange[800],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                Icon(
                                  Icons.chevron_right,
                                  color: _consentGiven
                                      ? const Color(0xFF6C5CE7)
                                      : Colors.orange[700],
                                  size: 18,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],

                      // Primary Auth Button
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: (_isLoading || (_isSignUp && !_consentGiven))
                              ? null
                              : () {
                                  if (_authMethod == 'email') {
                                    _handleEmailAuth();
                                  } else {
                                    _handleSendOtp();
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6C5CE7),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 4,
                          ),
                          child: _isLoading
                              ? const CircularProgressIndicator(color: Colors.white)
                              : Text(
                                  _authMethod == 'phone'
                                      ? 'Send OTP Verification Code'
                                      : (_isSignUp ? 'Create Account' : 'Sign In'),
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),

                      const SizedBox(height: 20),
                      Row(
                        children: [
                          const Expanded(child: Divider()),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            child: Text(
                              'OR',
                              style: TextStyle(color: Colors.grey[500], fontSize: 12),
                            ),
                          ),
                          const Expanded(child: Divider()),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Google Sign In Button
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: OutlinedButton.icon(
                          onPressed: _isLoading ? null : _handleGoogleSignIn,
                          icon: const Icon(Icons.g_mobiledata, color: Color(0xFF6C5CE7), size: 28),
                          label: const Text(
                            'Continue with Google',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF6C5CE7),
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFF6C5CE7), width: 1.5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Toggle Sign In vs Sign Up
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _isSignUp
                                ? 'Already have an account? '
                                : 'Don\'t have an account? ',
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 14,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _isSignUp = !_isSignUp;
                              });
                            },
                            child: Text(
                              _isSignUp ? 'Sign In' : 'Sign Up',
                              style: const TextStyle(
                                color: Color(0xFF6C5CE7),
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool isPassword = false,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        filled: true,
        fillColor: const Color(0xFFF8F9FA),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        hintText: label,
        hintStyle: const TextStyle(
          color: Colors.grey,
          fontSize: 14,
        ),
        prefixIcon: Icon(icon, color: const Color(0xFF6C5CE7), size: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF6C5CE7), width: 2),
        ),
      ),
    );
  }

  Widget _buildUserTypeSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF6C5CE7).withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.person_outline, color: Color(0xFF6C5CE7), size: 18),
              SizedBox(width: 8),
              Text(
                'Account Type',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF6C5CE7),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedUserType = 'patient'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: _selectedUserType == 'patient'
                          ? const Color(0xFF6C5CE7)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: _selectedUserType == 'patient'
                            ? const Color(0xFF6C5CE7)
                            : Colors.grey[300]!,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.person,
                          color: _selectedUserType == 'patient'
                              ? Colors.white
                              : const Color(0xFF6C5CE7),
                          size: 24,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Patient',
                          style: TextStyle(
                            color: _selectedUserType == 'patient'
                                ? Colors.white
                                : const Color(0xFF6C5CE7),
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedUserType = 'hospital'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: _selectedUserType == 'hospital'
                          ? const Color(0xFF6C5CE7)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: _selectedUserType == 'hospital'
                            ? const Color(0xFF6C5CE7)
                            : Colors.grey[300]!,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.local_hospital,
                          color: _selectedUserType == 'hospital'
                              ? Colors.white
                              : const Color(0xFF6C5CE7),
                          size: 24,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Hospital',
                          style: TextStyle(
                            color: _selectedUserType == 'hospital'
                                ? Colors.white
                                : const Color(0xFF6C5CE7),
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLoginTypeSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF6C5CE7).withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.login, color: Color(0xFF6C5CE7), size: 18),
              SizedBox(width: 8),
              Text(
                'Login As',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF6C5CE7),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedLoginType = 'patient'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: _selectedLoginType == 'patient'
                          ? const Color(0xFF6C5CE7)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: _selectedLoginType == 'patient'
                            ? const Color(0xFF6C5CE7)
                            : Colors.grey[300]!,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.person,
                          color: _selectedLoginType == 'patient'
                              ? Colors.white
                              : const Color(0xFF6C5CE7),
                          size: 24,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Patient',
                          style: TextStyle(
                            color: _selectedLoginType == 'patient'
                                ? Colors.white
                                : const Color(0xFF6C5CE7),
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedLoginType = 'hospital'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: _selectedLoginType == 'hospital'
                          ? const Color(0xFF6C5CE7)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: _selectedLoginType == 'hospital'
                            ? const Color(0xFF6C5CE7)
                            : Colors.grey[300]!,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.local_hospital,
                          color: _selectedLoginType == 'hospital'
                              ? Colors.white
                              : const Color(0xFF6C5CE7),
                          size: 24,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Hospital',
                          style: TextStyle(
                            color: _selectedLoginType == 'hospital'
                                ? Colors.white
                                : const Color(0xFF6C5CE7),
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
