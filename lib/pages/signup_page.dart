import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; 

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _nameController = TextEditingController(); 
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isSignUp = true;
  bool _isLoading = false;
  bool _consentGiven = false;
  String _selectedUserType = 'patient';
  String _selectedLoginType = 'patient'; // For login mode

  Future<void> _handleAuth() async {
    if (_emailController.text.trim().isEmpty || _passwordController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    if (_isSignUp && _nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your name')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // Store context before async operations
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      if (_isSignUp) {
        // Sign up
        UserCredential userCredential = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(
              email: _emailController.text.trim(),
              password: _passwordController.text.trim(),
            );

        // Save user data to Firestore
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredential.user!.uid)
            .set({
          'name': _nameController.text.trim(),
          'email': _emailController.text.trim(),
          'userType': _selectedUserType,
          'createdAt': FieldValue.serverTimestamp(),
          'privacyConsentAt': FieldValue.serverTimestamp(),
          'privacyConsentVersion': '1.0',
        });

        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('Account created successfully!')),
        );
        
        // Navigate to appropriate dashboard based on user type
        _navigateToDashboard(_selectedUserType);
      } else {
        // Sign in
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        // Verify that the selected login type matches the stored userType
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
              // Legacy account with no type — stamp it now
              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(currentUser.uid)
                  .update({'userType': _selectedLoginType});
              storedType = _selectedLoginType;
            }
          }

          // Block cross-type login
          if (storedType != null && storedType != _selectedLoginType) {
            await FirebaseAuth.instance.signOut();
            final typeLabel = storedType == 'hospital' ? 'Hospital/Doctor' : 'Patient';
            scaffoldMessenger.showSnackBar(
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

        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('Signed in successfully!')),
        );

        // Navigate to appropriate dashboard based on stored userType
        _navigateToDashboard(_selectedLoginType);
      }
    } on FirebaseAuthException catch (e) {
      String message = 'An error occurred';
      switch (e.code) {
        case 'weak-password':
          message = 'The password provided is too weak.';
          break;
        case 'email-already-in-use':
          message = 'The account already exists for that email.';
          break;
        case 'user-not-found':
          message = 'No user found for that email.';
          break;
        case 'wrong-password':
          message = 'Wrong password provided for that user.';
          break;
        case 'invalid-email':
          message = 'The email address is not valid.';
          break;
      }
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text(message)),
      );
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }

    setState(() {
      _isLoading = false;
    });
  }

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
                  // Handle bar
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 10),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[400],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  // Header
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
                        Text('Privacy Policy & Terms',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  // Scrollable content
                  Expanded(
                    child: Scrollbar(
                      controller: scrollCtrl,
                      child: SingleChildScrollView(
                        controller: scrollCtrl,
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _privacySection('1. What We Collect',
                                'HDIMSS collects personal and health information including your name, email address, contact details, medical history, allergies, medications, appointment records, vital signs, and AI-generated health recommendations. This information is collected when you create an account or enter records in the app.'),
                            _privacySection('2. How We Use Your Data',
                                'Your data is used solely to provide health record management features, to allow authorized healthcare providers to view your records, and to personalize AI-driven health recommendations. We do not sell, rent, or share your personal information with third parties for marketing purposes.'),
                            _privacySection('3. Data Storage & Security',
                                'All data is stored in Google Firebase (Firestore), a HIPAA-compliant cloud platform. You may optionally enable Privacy Mode, which encrypts your health records using AES-256 on your device before they are uploaded. In Privacy Mode your doctor must request and receive your explicit approval to view your records.'),
                            _privacySection('4. AI Health Assistant',
                                'When you use the AI diet and health assistant, your messages are sent to Google\'s Gemini AI service for processing. Do not include personal identifiers such as your full name, national ID, or date of birth in these messages. AI responses are stored both locally and in your account history.'),
                            _privacySection('5. Your Rights',
                                'You have the right to access, correct, and delete your personal health data at any time from within the app. You may disable Privacy Mode and reset your encryption PIN at any time. To request full account deletion, contact support@hdims.com.'),
                            _privacySection('6. Doctor Access',
                                'Healthcare providers who add you as a patient can view the medical records they have entered on your behalf. If you enable Privacy Mode, doctors must send an access request that you must explicitly approve before they can view your self-entered health records.'),
                            _privacySection('7. Data Retention',
                                'Your data is retained as long as your account is active. You may delete your records at any time from within the app. For account deletion requests email support@hdims.com.'),
                            _privacySection('8. Contact',
                                'For privacy-related questions contact our Data Protection Officer at privacy@hdims.com. For technical support contact support@hdims.com.'),
                            const SizedBox(height: 8),
                            Text(
                              'Last updated: March 2026  •  Version 1.0',
                              style: TextStyle(
                                  color: Colors.grey[500],
                                  fontSize: 12,
                                  fontStyle: FontStyle.italic),
                            ),
                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Consent action bar
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
                                Icon(Icons.arrow_downward,
                                    size: 14, color: Colors.orange[700]),
                                const SizedBox(width: 5),
                                Text('Scroll down to read the full policy',
                                    style: TextStyle(
                                        color: Colors.orange[700], fontSize: 12)),
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
                            onPressed: localConsent
                                ? () => Navigator.of(ctx).pop(true)
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF6C5CE7),
                              disabledBackgroundColor: Colors.grey[300],
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text('Confirm & Continue',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold)),
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
          Text(title,
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF6C5CE7))),
          const SizedBox(height: 5),
          Text(body,
              style: const TextStyle(
                  fontSize: 13, color: Colors.black87, height: 1.6)),
        ],
      ),
    );
  }

  void _navigateToDashboard(String userType) {
    // Add a small delay to ensure the success message is shown
    Future.delayed(const Duration(milliseconds: 1500), () {
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
                const SizedBox(height: 40),
                
                // Logo/Header section
                Container(
                  padding: const EdgeInsets.all(30),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6C5CE7), Color(0xFF74B9FF)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF6C5CE7).withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: const Icon(
                          Icons.health_and_safety,
                          size: 40,
                          color: Color(0xFF6C5CE7),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        "HDIMS Health",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
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
                
                const SizedBox(height: 40),
                
                // Form section
                Container(
                  padding: const EdgeInsets.all(30),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
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
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _isSignUp 
                            ? 'Please enter your details to create an account'
                            : 'Please enter your details to sign in',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 30),
                      
                      if (_isSignUp) ...[
                        _buildTextField(_nameController, 'Full Name', Icons.person),
                        const SizedBox(height: 20),
                        _buildUserTypeSelector(),
                        const SizedBox(height: 20),
                      ],
                      
                      _buildTextField(_emailController, 'Email Address', Icons.email),
                      const SizedBox(height: 20),
                      
                      _buildTextField(_passwordController, 'Password', Icons.lock, isPassword: true),
                      
                      if (!_isSignUp) ...[
                        const SizedBox(height: 20),
                        _buildLoginTypeSelector(),
                        const SizedBox(height: 15),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {
                              // TODO: Implement forgot password
                            },
                            child: const Text(
                              'Forgot Password?',
                              style: TextStyle(
                                color: Color(0xFF6C5CE7),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                      
                      const SizedBox(height: 30),
                      
                      if (_isSignUp) ...[
                        const SizedBox(height: 4),
                        InkWell(
                          onTap: _showPrivacyModal,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 10),
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

                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton(
                          onPressed: (_isLoading || (_isSignUp && !_consentGiven))
                              ? null
                              : _handleAuth,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6C5CE7),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            elevation: 5,
                          ),
                          child: _isLoading
                              ? const CircularProgressIndicator(color: Colors.white)
                              : Text(
                                  _isSignUp ? 'Create Account' : 'Sign In',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),
                      
                      if (!_isSignUp) ...[
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            const Expanded(child: Divider()),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                'OR',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ),
                            const Expanded(child: Divider()),
                          ],
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          height: 55,
                          child: OutlinedButton.icon(
                            onPressed: () {
                              // TODO: Implement Google sign in
                            },
                            icon: const Icon(Icons.g_mobiledata, color: Color(0xFF6C5CE7)),
                            label: const Text(
                              'Continue with Google',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF6C5CE7),
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFF6C5CE7)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                            ),
                          ),
                        ),
                      ],
                      
                      const SizedBox(height: 30),
                      
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

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {bool isPassword = false}) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      decoration: InputDecoration(
        filled: true,
        fillColor: const Color(0xFFF8F9FA),
        contentPadding: const EdgeInsets.all(20),
        hintText: 'Enter $label',
        hintStyle: const TextStyle(
          color: Colors.grey,
          fontSize: 16,
        ),
        prefixIcon: Icon(icon, color: const Color(0xFF6C5CE7)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Color(0xFF6C5CE7), width: 2),
        ),
      ),
    );
  }

  Widget _buildUserTypeSelector() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFF6C5CE7).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.person_outline, color: const Color(0xFF6C5CE7)),
              const SizedBox(width: 8),
              const Text(
                'Account Type',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF6C5CE7),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedUserType = 'patient';
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(15),
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
                          size: 30,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Patient',
                          style: TextStyle(
                            color: _selectedUserType == 'patient' 
                                ? Colors.white 
                                : const Color(0xFF6C5CE7),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedUserType = 'hospital';
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(15),
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
                          size: 30,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Hospital',
                          style: TextStyle(
                            color: _selectedUserType == 'hospital' 
                                ? Colors.white 
                                : const Color(0xFF6C5CE7),
                            fontWeight: FontWeight.bold,
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFF6C5CE7).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.login, color: const Color(0xFF6C5CE7)),
              const SizedBox(width: 8),
              const Text(
                'Login As',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF6C5CE7),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedLoginType = 'patient';
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(15),
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
                          size: 30,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Patient',
                          style: TextStyle(
                            color: _selectedLoginType == 'patient' 
                                ? Colors.white 
                                : const Color(0xFF6C5CE7),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedLoginType = 'hospital';
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(15),
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
                          size: 30,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Hospital',
                          style: TextStyle(
                            color: _selectedLoginType == 'hospital' 
                                ? Colors.white 
                                : const Color(0xFF6C5CE7),
                            fontWeight: FontWeight.bold,
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
