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
import 'patient_privacy_security.dart';
import 'package:flutterapp/services/access_request_service.dart';

class PatientDashboard extends StatefulWidget {
  const PatientDashboard({super.key});

  @override
  _PatientDashboardState createState() => _PatientDashboardState();
}

class _PatientDashboardState extends State<PatientDashboard> {
  int _selectedIndex = 0;
  String? userName;
  String? _linkedPatientId;

  List<Widget> get _pages => [
    PatientHome(linkedPatientId: _linkedPatientId),
    PatientPersonalDetails(linkedPatientId: _linkedPatientId),
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
      if (currentUser == null) return;

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();

      if (!mounted) return;

      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        final existingLink = userData['linkedPatientId'] as String?;

        setState(() {
          userName = userData['name'] as String? ??
              currentUser.email?.split('@')[0] ??
              'Patient';
          _linkedPatientId = existingLink;
        });

        // If not yet linked, try to find a matching patients doc by email
        if (existingLink == null || existingLink.isEmpty) {
          _tryAutoLink(currentUser);
        }
      } else {
        setState(() {
          userName = currentUser.email?.split('@')[0] ?? 'Patient';
        });
        _tryAutoLink(currentUser);
      }
    } catch (_) {}
  }

  Future<void> _tryAutoLink(User currentUser) async {
    try {
      final email = currentUser.email;
      if (email == null || email.isEmpty) return;

      final query = await FirebaseFirestore.instance
          .collection('patients')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (query.docs.isEmpty) return;

      final linkedId = query.docs.first.id;
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .update({'linkedPatientId': linkedId});

      if (mounted) setState(() => _linkedPatientId = linkedId);
    } catch (_) {}
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
          IconButton(
            icon: const Icon(Icons.shield, color: Colors.white),
            tooltip: 'Privacy & Security',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const PatientPrivacySecurity()),
              );
            },
          ),
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
      body: Column(
        children: [
          _buildAccessRequestBanner(),
          _buildLinkRequestBanner(),
          Expanded(child: _pages[_selectedIndex]),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
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

  Widget _buildAccessRequestBanner() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const SizedBox.shrink();
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('access_requests')
          .where('patientUid', isEqualTo: uid)
          .where('status', isEqualTo: 'pending')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const SizedBox.shrink();
        }
        return Column(
          children: snapshot.data!.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final doctorName = data['doctorName'] as String? ?? 'A doctor';
            return Container(
              margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF6C5CE7).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: const Color(0xFF6C5CE7).withValues(alpha: 0.35)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.lock_open,
                      color: Color(0xFF6C5CE7), size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '$doctorName is requesting access to your health records.',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(0, 32)),
                    onPressed: () async {
                      await AccessRequestService.denyRequest(doc.id);
                    },
                    child: const Text('Deny',
                        style: TextStyle(color: Colors.red, fontSize: 12)),
                  ),
                  const SizedBox(width: 4),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6C5CE7),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      minimumSize: const Size(0, 32),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () async {
                      final doctorUid =
                          data['doctorUid'] as String? ?? '';
                      await AccessRequestService.approveRequest(
                        requestId: doc.id,
                        patientUid: uid,
                        doctorUid: doctorUid,
                      );
                    },
                    child: const Text('Approve',
                        style:
                            TextStyle(color: Colors.white, fontSize: 12)),
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildLinkRequestBanner() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const SizedBox.shrink();
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('link_requests')
          .where('patientUid', isEqualTo: uid)
          .where('status', isEqualTo: 'pending')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const SizedBox.shrink();
        }
        return Column(
          children: snapshot.data!.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final doctorName = data['doctorName'] as String? ?? 'A doctor';
            return Container(
              margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: Colors.green.withValues(alpha: 0.35)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.link, color: Colors.green, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '$doctorName wants to link you as their patient.',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(0, 32)),
                    onPressed: () async {
                      await AccessRequestService.denyLink(doc.id);
                    },
                    child: const Text('Deny',
                        style: TextStyle(color: Colors.red, fontSize: 12)),
                  ),
                  const SizedBox(width: 4),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      minimumSize: const Size(0, 32),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () async {
                      final doctorUid =
                          data['doctorUid'] as String? ?? '';
                      await AccessRequestService.acceptLink(
                        requestId: doc.id,
                        patientUid: uid,
                        doctorUid: doctorUid,
                      );
                      // Refresh linked patient ID
                      _fetchUserName();
                    },
                    child: const Text('Accept',
                        style:
                            TextStyle(color: Colors.white, fontSize: 12)),
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
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
            leading: const Icon(Icons.shield, color: Color(0xFF6C5CE7)),
            title: const Text('Privacy & Security'),
            onTap: () {
              Navigator.of(context).pop();
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const PatientPrivacySecurity()),
              );
            },
          ),
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
                if (context.mounted) Navigator.of(context).pushReplacementNamed('/auth');
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

