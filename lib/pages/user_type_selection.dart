import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dashboard.dart';
import 'patient_dashboard.dart';

class UserTypeSelection extends StatefulWidget {
  const UserTypeSelection({super.key});

  @override
  _UserTypeSelectionState createState() => _UserTypeSelectionState();
}

class _UserTypeSelectionState extends State<UserTypeSelection> {
  String? _selectedUserType;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Header
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
                child: const Column(
                  children: [
                    Icon(
                      Icons.person_add,
                      color: Colors.white,
                      size: 60,
                    ),
                    SizedBox(height: 20),
                    Text(
                      "Select Your Account Type",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      "Please choose your account type to continue",
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              // User Type Selection
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
                        padding: const EdgeInsets.all(30),
                        decoration: BoxDecoration(
                          color: _selectedUserType == 'patient' 
                              ? const Color(0xFF6C5CE7) 
                              : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _selectedUserType == 'patient' 
                                ? const Color(0xFF6C5CE7) 
                                : Colors.grey[300]!,
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.person,
                              color: _selectedUserType == 'patient' 
                                  ? Colors.white 
                                  : const Color(0xFF6C5CE7),
                              size: 50,
                            ),
                            const SizedBox(height: 15),
                            Text(
                              'Patient',
                              style: TextStyle(
                                color: _selectedUserType == 'patient' 
                                    ? Colors.white 
                                    : const Color(0xFF6C5CE7),
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Access your health records, appointments, and medical history',
                              style: TextStyle(
                                color: _selectedUserType == 'patient' 
                                    ? Colors.white70 
                                    : Colors.grey[600],
                                fontSize: 12,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedUserType = 'hospital';
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(30),
                        decoration: BoxDecoration(
                          color: _selectedUserType == 'hospital' 
                              ? const Color(0xFF6C5CE7) 
                              : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _selectedUserType == 'hospital' 
                                ? const Color(0xFF6C5CE7) 
                                : Colors.grey[300]!,
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.local_hospital,
                              color: _selectedUserType == 'hospital' 
                                  ? Colors.white 
                                  : const Color(0xFF6C5CE7),
                              size: 50,
                            ),
                            const SizedBox(height: 15),
                            Text(
                              'Hospital',
                              style: TextStyle(
                                color: _selectedUserType == 'hospital' 
                                    ? Colors.white 
                                    : const Color(0xFF6C5CE7),
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Manage patients, view records, and update medical information',
                              style: TextStyle(
                                color: _selectedUserType == 'hospital' 
                                    ? Colors.white70 
                                    : Colors.grey[600],
                                fontSize: 12,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 40),

              // Continue Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _selectedUserType != null && !_isLoading ? _saveUserType : null,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    backgroundColor: const Color(0xFF6C5CE7),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Continue',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveUserType() async {
    if (_selectedUserType == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        // Update user data with userType
        await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .update({
          'userType': _selectedUserType,
        });

        print('User type updated: $_selectedUserType');

        // Navigate to appropriate dashboard
        if (_selectedUserType == 'hospital') {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const Dashboard()),
          );
        } else {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const PatientDashboard()),
          );
        }
      }
    } catch (e) {
      print('Error updating user type: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}

