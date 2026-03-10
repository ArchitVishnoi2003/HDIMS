import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'patient_home.dart';
import 'patient_personal_details.dart';
import 'patient_medicines_allergy.dart';
import 'patient_checkups_history.dart';
import 'patient_appointments.dart';
import 'patient_routine.dart';
import 'patient_profile.dart';

class PatientDashboard extends StatefulWidget {
  const PatientDashboard({super.key});

  @override
  _PatientDashboardState createState() => _PatientDashboardState();
}

class _PatientDashboardState extends State<PatientDashboard> {
  int _selectedIndex = 0;
  String? userName;

  final List<Widget> _pages = [
    const PatientHome(),
    const PatientPersonalDetails(),
    const PatientMedicinesAllergy(),
    const PatientCheckupsHistory(),
    const PatientAppointments(),
    const PatientRoutine(),
  ];

  final List<String> _pageTitles = [
    'Home',
    'Personal Details',
    'Medicines & Allergies',
    'Medical History',
    'Appointments',
    'Daily Routine',
  ];

  @override
  void initState() {
    super.initState();
    _fetchUserName();
  }

  Future<void> _fetchUserName() async {
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
            userName = userData['name'] ?? currentUser.email?.split('@')[0] ?? 'Patient';
          });
        } else {
          setState(() {
            userName = currentUser.email?.split('@')[0] ?? 'Patient';
          });
        }
      }
    } catch (e) {
      print('Error fetching user name: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      drawer: _buildDrawer(),
      appBar: AppBar(
        title: Text(
          _pageTitles[_selectedIndex],
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF6C5CE7),
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onSelected: (value) {
              if (value == 'logout') {
                _showLogoutDialog();
              }
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem<String>(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Logout'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: const Color(0xFF6C5CE7),
          unselectedItemColor: Colors.grey,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: 'Details',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.medication),
              label: 'Medicines',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.history),
              label: 'History',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.calendar_today),
              label: 'Appointments',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.schedule),
              label: 'Routine',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF6C5CE7), Color(0xFF74B9FF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white,
                  child: Text(
                    userName?.substring(0, 1).toUpperCase() ?? 'P',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF6C5CE7),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  userName ?? 'Patient',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(
                  'Patient Account',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home, color: Color(0xFF6C5CE7)),
            title: const Text('Home'),
            onTap: () {
              Navigator.of(context).pop();
              setState(() {
                _selectedIndex = 0;
              });
            },
          ),
          ListTile(
            leading: const Icon(Icons.person, color: Color(0xFF6C5CE7)),
            title: const Text('Personal Details'),
            onTap: () {
              Navigator.of(context).pop();
              setState(() {
                _selectedIndex = 1;
              });
            },
          ),
          ListTile(
            leading: const Icon(Icons.medication, color: Color(0xFF6C5CE7)),
            title: const Text('Medicines & Allergies'),
            onTap: () {
              Navigator.of(context).pop();
              setState(() {
                _selectedIndex = 2;
              });
            },
          ),
          ListTile(
            leading: const Icon(Icons.history, color: Color(0xFF6C5CE7)),
            title: const Text('Medical History'),
            onTap: () {
              Navigator.of(context).pop();
              setState(() {
                _selectedIndex = 3;
              });
            },
          ),
          ListTile(
            leading: const Icon(Icons.calendar_today, color: Color(0xFF6C5CE7)),
            title: const Text('Appointments'),
            onTap: () {
              Navigator.of(context).pop();
              setState(() {
                _selectedIndex = 4;
              });
            },
          ),
          ListTile(
            leading: const Icon(Icons.schedule, color: Color(0xFF6C5CE7)),
            title: const Text('Daily Routine'),
            onTap: () {
              Navigator.of(context).pop();
              setState(() {
                _selectedIndex = 5;
              });
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.account_circle, color: Color(0xFF6C5CE7)),
            title: const Text('Profile Settings'),
            onTap: () {
              Navigator.of(context).pop();
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const PatientProfile()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.help_outline, color: Color(0xFF6C5CE7)),
            title: const Text('Help & Support'),
            onTap: () {
              Navigator.of(context).pop();
              _showHelpDialog();
            },
          ),
          ListTile(
            leading: const Icon(Icons.psychology, color: Color(0xFF6C5CE7)),
            title: const Text('Ask AI'),
            onTap: () {
              Navigator.of(context).pop();
              Navigator.pushNamed(context, '/ask-ai');
            },
          ),
          ListTile(
            leading: const Icon(Icons.info_outline, color: Color(0xFF6C5CE7)),
            title: const Text('About'),
            onTap: () {
              Navigator.of(context).pop();
              _showAboutDialog();
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.exit_to_app, color: Colors.red),
            title: const Text('Sign Out'),
            onTap: () {
              Navigator.of(context).pop();
              _showLogoutDialog();
            },
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await FirebaseAuth.instance.signOut();
                Navigator.of(context).pushReplacementNamed('/auth');
              },
              child: const Text('Logout', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Help & Support'),
          content: const Text(
            'For any assistance or questions, please contact our support team at:\n\n'
            'Email: support@hdims.com\n'
            'Phone: +1-800-HDIMS-HELP\n\n'
            'We are here to help you manage your health effectively.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('About HDIMS'),
          content: const Text(
            'HDIMS Health - Smart & Secure Health Ledger\n\n'
            'Version: 1.0.0\n'
            'Developed for comprehensive health management\n\n'
            '© 2024 HDIMS Health. All rights reserved.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
}

