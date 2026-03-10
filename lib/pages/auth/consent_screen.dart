import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ConsentScreen extends StatefulWidget {
  const ConsentScreen({super.key});

  @override
  State<ConsentScreen> createState() => _ConsentScreenState();
}

class _ConsentScreenState extends State<ConsentScreen> {
  final _scrollController = ScrollController();
  bool _scrolledToBottom = false;
  bool _agreed = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (!_scrolledToBottom &&
          _scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent - 60) {
        setState(() => _scrolledToBottom = true);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _accept() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    setState(() => _saving = true);
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .update({
      'privacyConsentAt': FieldValue.serverTimestamp(),
      'privacyConsentVersion': '1.0',
    });
    // UserTypeWrapper's stream will pick up the change and re-route automatically.
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──────────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF6C5CE7), Color(0xFF74B9FF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.privacy_tip,
                        color: Colors.white, size: 26),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Privacy Policy & Terms',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold)),
                        SizedBox(height: 4),
                        Text('Please read before continuing',
                            style: TextStyle(
                                color: Colors.white70, fontSize: 13)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── Scrollable policy text ───────────────────────────────────────
            Expanded(
              child: Scrollbar(
                controller: _scrollController,
                child: SingleChildScrollView(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _section('1. What We Collect',
                          'HDIMSS collects personal and health information including your name, email address, contact details, medical history, allergies, medications, appointment records, vital signs, and AI-generated health recommendations. This information is collected when you create an account or enter records in the app.'),
                      _section('2. How We Use Your Data',
                          'Your data is used solely to provide health record management features, to allow authorized healthcare providers to view your records, and to personalize AI-driven health recommendations. We do not sell, rent, or share your personal information with third parties for marketing purposes.'),
                      _section('3. Data Storage & Security',
                          'All data is stored in Google Firebase (Firestore), a HIPAA-compliant cloud platform. You may optionally enable Privacy Mode, which encrypts your health records using AES-256 on your device before they are uploaded. In Privacy Mode your doctor must request and receive your explicit approval to view your records.'),
                      _section('4. AI Health Assistant',
                          'When you use the AI diet and health assistant, your messages are sent to Google\'s Gemini AI service for processing. Do not include personal identifiers such as your full name, national ID, or date of birth in these messages. AI responses are stored both locally and in your account history.'),
                      _section('5. Your Rights',
                          'You have the right to access, correct, and delete your personal health data at any time from within the app. You may disable Privacy Mode and reset your encryption PIN at any time. To request full account deletion, contact support@hdims.com.'),
                      _section('6. Doctor Access',
                          'Healthcare providers who add you as a patient can view the medical records they have entered on your behalf. If you enable Privacy Mode, doctors must send an access request that you must explicitly approve before they can view your self-entered health records.'),
                      _section('7. Data Retention',
                          'Your data is retained as long as your account is active. You may delete your records at any time from within the app. For account deletion requests email support@hdims.com.'),
                      _section('8. Contact',
                          'For privacy-related questions contact our Data Protection Officer at privacy@hdims.com. For technical support contact support@hdims.com.'),
                      const SizedBox(height: 8),
                      Text(
                        'Last updated: March 2026  •  Version 1.0',
                        style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 12,
                            fontStyle: FontStyle.italic),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ── Consent action bar ───────────────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 10,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!_scrolledToBottom)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        children: [
                          Icon(Icons.arrow_downward,
                              size: 15, color: Colors.orange[700]),
                          const SizedBox(width: 6),
                          Text('Scroll down to read the full policy',
                              style: TextStyle(
                                  color: Colors.orange[700], fontSize: 13)),
                        ],
                      ),
                    ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Checkbox(
                        value: _agreed,
                        activeColor: const Color(0xFF6C5CE7),
                        onChanged: _scrolledToBottom
                            ? (v) => setState(() => _agreed = v ?? false)
                            : null,
                      ),
                      const Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(top: 11),
                          child: Text(
                            'I have read and agree to the Privacy Policy and Terms of Use',
                            style: TextStyle(fontSize: 13),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: (_agreed && !_saving) ? _accept : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6C5CE7),
                        disabledBackgroundColor: Colors.grey[300],
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      child: _saving
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2))
                          : const Text('I Agree & Continue',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
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
  }

  Widget _section(String title, String body) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF6C5CE7))),
          const SizedBox(height: 6),
          Text(body,
              style: const TextStyle(
                  fontSize: 13, color: Colors.black87, height: 1.6)),
        ],
      ),
    );
  }
}
