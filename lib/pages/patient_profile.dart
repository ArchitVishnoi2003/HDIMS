import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutterapp/services/encryption_service.dart';

class PatientProfile extends StatefulWidget {
  const PatientProfile({super.key});

  @override
  _PatientProfileState createState() => _PatientProfileState();
}

class _PatientProfileState extends State<PatientProfile> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _bloodGroupController = TextEditingController();
  
  bool _isLoading = false;
  bool _isEditing = false;
  bool _privacyModeEnabled = false;
  bool _privacyLoading = false;
  String? _userName;
  String? _userEmail;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
    _loadPrivacyMode();
  }

  Future<void> _loadPrivacyMode() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final enabled = await EncryptionService.isEnabled(uid);
    if (mounted) setState(() => _privacyModeEnabled = enabled);
  }

  Future<void> _showPinSetupSheet() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final pin1Ctrl = TextEditingController();
    final pin2Ctrl = TextEditingController();
    String? error;

    final pin = await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setSheet) {
        return Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  const Icon(Icons.lock, color: Color(0xFF6C5CE7)),
                  const SizedBox(width: 10),
                  const Text('Set Privacy PIN',
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                ]),
                const SizedBox(height: 8),
                const Text(
                  'Choose a 6-digit PIN to encrypt your health records. '
                  'If you forget this PIN your encrypted records cannot be recovered.',
                  style: TextStyle(fontSize: 13, color: Colors.black54),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: pin1Ctrl,
                  keyboardType: TextInputType.number,
                  obscureText: true,
                  maxLength: 6,
                  decoration: InputDecoration(
                    labelText: 'Enter PIN (6 digits)',
                    prefixIcon: const Icon(Icons.pin,
                        color: Color(0xFF6C5CE7)),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                          color: Color(0xFF6C5CE7), width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: pin2Ctrl,
                  keyboardType: TextInputType.number,
                  obscureText: true,
                  maxLength: 6,
                  decoration: InputDecoration(
                    labelText: 'Confirm PIN',
                    prefixIcon: const Icon(Icons.pin,
                        color: Color(0xFF6C5CE7)),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                          color: Color(0xFF6C5CE7), width: 2),
                    ),
                  ),
                ),
                if (error != null) ...[
                  const SizedBox(height: 4),
                  Text(error!,
                      style: const TextStyle(
                          color: Colors.red, fontSize: 13)),
                ],
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6C5CE7),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () async {
                      final p1 = pin1Ctrl.text.trim();
                      final p2 = pin2Ctrl.text.trim();
                      if (p1.length != 6 ||
                          !RegExp(r'^\d{6}$').hasMatch(p1)) {
                        setSheet(
                            () => error = 'PIN must be exactly 6 digits.');
                        return;
                      }
                      if (p1 != p2) {
                        setSheet(() => error = 'PINs do not match.');
                        return;
                      }
                      Navigator.of(ctx).pop(p1);
                    },
                    child: const Text('Enable Privacy Mode',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
    pin1Ctrl.dispose();
    pin2Ctrl.dispose();
    if (pin == null || !mounted) return;
    setState(() => _privacyLoading = true);
    try {
      await EncryptionService.enablePrivacyMode(uid, pin as String);
      await EncryptionService.encryptAllRecords(uid);
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .update({'privacyModeEnabled': true});
      if (mounted) {
        setState(() => _privacyModeEnabled = true);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Privacy Mode enabled. Records encrypted.')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error enabling Privacy Mode: $e')));
      }
    } finally {
      if (mounted) setState(() => _privacyLoading = false);
    }
  }

  Future<void> _disablePrivacyMode() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Disable Privacy Mode'),
        content: const Text(
            'Your health records will be decrypted and stored as plaintext in the cloud. '
            'Doctors will be able to view them without your approval. Continue?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[600]),
            child: const Text('Disable',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _privacyLoading = true);
    try {
      await EncryptionService.decryptAllRecords(uid);
      await EncryptionService.disablePrivacyMode(uid);
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .update({'privacyModeEnabled': false});
      setState(() => _privacyModeEnabled = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Privacy Mode disabled. Records decrypted.')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error disabling Privacy Mode: $e')));
      }
    } finally {
      if (mounted) setState(() => _privacyLoading = false);
    }
  }

  Future<void> _fetchUserData() async {
    try {
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .get();

        if (userDoc.exists) {
          Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
          setState(() {
            _userName = userData['name'] ?? '';
            _userEmail = userData['email'] ?? currentUser.email ?? '';
            _nameController.text = _userName ?? '';
            _emailController.text = _userEmail ?? '';
            _phoneController.text = userData['phone'] ?? '';
            _addressController.text = userData['address'] ?? '';
            _ageController.text = userData['age']?.toString() ?? '';
            _bloodGroupController.text = userData['bloodGroup'] ?? '';
          });
        }
      }
    } catch (e) {
      print('Error fetching user data: $e');
    }
  }

  Future<void> _updateProfile() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your name')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .update({
          'name': _nameController.text.trim(),
          'phone': _phoneController.text.trim(),
          'address': _addressController.text.trim(),
          'age': int.tryParse(_ageController.text.trim()) ?? 0,
          'bloodGroup': _bloodGroupController.text.trim(),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        setState(() {
          _isEditing = false;
          _userName = _nameController.text.trim();
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating profile: ${e.toString()}')),
      );
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _ageController.dispose();
    _bloodGroupController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Profile',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF6C5CE7),
        elevation: 0,
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.white),
              onPressed: () {
                setState(() {
                  _isEditing = true;
                });
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Profile Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6C5CE7), Color(0xFF74B9FF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6C5CE7).withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.white,
                    child: Text(
                      _userName?.substring(0, 1).toUpperCase() ?? 'P',
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF6C5CE7),
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  Text(
                    _userName ?? 'Patient',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    _userEmail ?? '',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // Profile Form
            Container(
              padding: const EdgeInsets.all(25),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Personal Information',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF6C5CE7),
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  _buildTextField(
                    controller: _nameController,
                    label: 'Full Name',
                    icon: Icons.person,
                    enabled: _isEditing,
                  ),
                  const SizedBox(height: 15),
                  
                  _buildTextField(
                    controller: _emailController,
                    label: 'Email',
                    icon: Icons.email,
                    enabled: false, // Email cannot be changed
                  ),
                  const SizedBox(height: 15),
                  
                  _buildTextField(
                    controller: _phoneController,
                    label: 'Phone Number',
                    icon: Icons.phone,
                    enabled: _isEditing,
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 15),
                  
                  _buildTextField(
                    controller: _addressController,
                    label: 'Address',
                    icon: Icons.location_on,
                    enabled: _isEditing,
                    maxLines: 2,
                  ),
                  const SizedBox(height: 15),
                  
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          controller: _ageController,
                          label: 'Age',
                          icon: Icons.cake,
                          enabled: _isEditing,
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: _buildTextField(
                          controller: _bloodGroupController,
                          label: 'Blood Group',
                          icon: Icons.bloodtype,
                          enabled: _isEditing,
                        ),
                      ),
                    ],
                  ),
                  
                  if (_isEditing) ...[
                    const SizedBox(height: 30),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _updateProfile,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF6C5CE7),
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: _isLoading
                                ? const CircularProgressIndicator(color: Colors.white)
                                : const Text(
                                    'Save Changes',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              setState(() {
                                _isEditing = false;
                              });
                              _fetchUserData(); // Reset to original values
                            },
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFF6C5CE7)),
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: const Text(
                              'Cancel',
                              style: TextStyle(
                                color: Color(0xFF6C5CE7),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Privacy Mode card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6C5CE7).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.lock,
                            color: Color(0xFF6C5CE7), size: 20),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Privacy Mode',
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF6C5CE7))),
                            Text('Encrypt health records on-device',
                                style: TextStyle(
                                    fontSize: 12, color: Colors.black54)),
                          ],
                        ),
                      ),
                      _privacyLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Color(0xFF6C5CE7)))
                          : Switch(
                              value: _privacyModeEnabled,
                              activeThumbColor: const Color(0xFF6C5CE7),
                              onChanged: (val) {
                                if (val) {
                                  _showPinSetupSheet();
                                } else {
                                  _disablePrivacyMode();
                                }
                              },
                            ),
                    ],
                  ),
                  if (_privacyModeEnabled) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: Colors.green.withValues(alpha: 0.3)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.check_circle,
                              color: Colors.green, size: 16),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Your health records are encrypted. Doctors must request your approval to view them.',
                              style: TextStyle(
                                  fontSize: 12, color: Colors.black54),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    const SizedBox(height: 10),
                    const Text(
                      'When enabled, health records are encrypted with AES-256 before upload. Only you hold the key.',
                      style: TextStyle(fontSize: 12, color: Colors.black45),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool enabled,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      enabled: enabled,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        filled: true,
        fillColor: enabled ? const Color(0xFFF8F9FA) : Colors.grey[100],
        contentPadding: const EdgeInsets.all(15),
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF6C5CE7)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF6C5CE7), width: 2),
        ),
        labelStyle: TextStyle(
          color: enabled ? const Color(0xFF6C5CE7) : Colors.grey,
        ),
      ),
    );
  }
}
