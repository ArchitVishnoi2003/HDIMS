import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutterapp/services/encryption_service.dart';
import 'package:flutterapp/services/access_request_service.dart';

class PatientPrivacySecurity extends StatefulWidget {
  const PatientPrivacySecurity({super.key});

  @override
  State<PatientPrivacySecurity> createState() =>
      _PatientPrivacySecurityState();
}

class _PatientPrivacySecurityState extends State<PatientPrivacySecurity> {
  bool _privacyModeEnabled = false;
  bool _privacyLoading = false;

  @override
  void initState() {
    super.initState();
    _loadPrivacyMode();
  }

  Future<void> _loadPrivacyMode() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final enabled = await EncryptionService.isEnabled(uid);
    if (mounted) setState(() => _privacyModeEnabled = enabled);
  }

  // ── Enable privacy mode ───────────────────────────────────────────────────

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
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
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
                const Row(children: [
                  Icon(Icons.lock, color: Color(0xFF6C5CE7)),
                  SizedBox(width: 10),
                  Text('Set Privacy PIN',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
                    prefixIcon:
                        const Icon(Icons.pin, color: Color(0xFF6C5CE7)),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide:
                          const BorderSide(color: Color(0xFF6C5CE7), width: 2),
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
                    prefixIcon:
                        const Icon(Icons.pin, color: Color(0xFF6C5CE7)),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide:
                          const BorderSide(color: Color(0xFF6C5CE7), width: 2),
                    ),
                  ),
                ),
                if (error != null) ...[
                  const SizedBox(height: 4),
                  Text(error!,
                      style: const TextStyle(color: Colors.red, fontSize: 13)),
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
                    onPressed: () {
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
                            color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );

    if (pin == null || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _privacyLoading = true);
    try {
      await EncryptionService.enablePrivacyMode(uid, pin as String);
      await EncryptionService.encryptAllRecords(uid);
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .update({'privacyModeEnabled': true});
      if (mounted) setState(() => _privacyModeEnabled = true);
      messenger.showSnackBar(const SnackBar(
          content: Text('Privacy Mode enabled. Records encrypted.')));
    } catch (e) {
      messenger.showSnackBar(
          SnackBar(content: Text('Error enabling Privacy Mode: $e')));
    } finally {
      if (mounted) setState(() => _privacyLoading = false);
    }
  }

  // ── Disable privacy mode ──────────────────────────────────────────────────

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
            style:
                ElevatedButton.styleFrom(backgroundColor: Colors.red[600]),
            child: const Text('Disable',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    setState(() => _privacyLoading = true);
    try {
      await EncryptionService.decryptAllRecords(uid);
      await EncryptionService.disablePrivacyMode(uid);
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .update({'privacyModeEnabled': false});
      if (mounted) setState(() => _privacyModeEnabled = false);
      messenger.showSnackBar(const SnackBar(
          content: Text('Privacy Mode disabled. Records decrypted.')));
    } catch (e) {
      messenger.showSnackBar(
          SnackBar(content: Text('Error disabling Privacy Mode: $e')));
    } finally {
      if (mounted) setState(() => _privacyLoading = false);
    }
  }

  // ── Revoke access ─────────────────────────────────────────────────────────

  Future<void> _revokeAccess(String requestId, String patientUid) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Revoke Access'),
        content: const Text(
            'This doctor will immediately lose access to your decrypted records. Continue?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style:
                ElevatedButton.styleFrom(backgroundColor: Colors.red[600]),
            child: const Text('Revoke',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await AccessRequestService.revokeAccess(requestId, patientUid);
      messenger.showSnackBar(
          const SnackBar(content: Text('Access revoked successfully.')));
    } catch (e) {
      messenger.showSnackBar(
          SnackBar(content: Text('Error revoking access: $e')));
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Privacy & Security',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF6C5CE7),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // ── Header ───────────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6C5CE7), Color(0xFF74B9FF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6C5CE7).withValues(alpha: 0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      _privacyModeEnabled ? Icons.shield : Icons.shield_outlined,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Privacy & Security',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(
                          _privacyModeEnabled
                              ? 'Your records are encrypted'
                              : 'Encryption is off',
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── Privacy Mode toggle ──────────────────────────────────
            _buildPrivacyModeCard(),

            const SizedBox(height: 20),

            // ── Pending access requests ──────────────────────────────
            if (uid != null) _buildPendingRequestsCard(uid),

            const SizedBox(height: 20),

            // ── Active access sessions ───────────────────────────────
            if (_privacyModeEnabled && uid != null)
              _buildActiveAccessCard(uid),
          ],
        ),
      ),
    );
  }

  // ── Privacy Mode card ─────────────────────────────────────────────────────

  Widget _buildPrivacyModeCard() {
    return Container(
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
                child:
                    const Icon(Icons.lock, color: Color(0xFF6C5CE7), size: 20),
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
                        style: TextStyle(fontSize: 12, color: Colors.black54)),
                  ],
                ),
              ),
              _privacyLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Color(0xFF6C5CE7)))
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
          const SizedBox(height: 12),
          if (_privacyModeEnabled)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
                border:
                    Border.all(color: Colors.green.withValues(alpha: 0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green, size: 16),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Your health records are encrypted. Doctors must request your approval to view them.',
                      style: TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                  ),
                ],
              ),
            )
          else
            const Text(
              'When enabled, health records are encrypted with AES-256 before upload. Only you hold the key.',
              style: TextStyle(fontSize: 12, color: Colors.black45),
            ),
        ],
      ),
    );
  }

  // ── Pending access requests card ──────────────────────────────────────────

  Widget _buildPendingRequestsCard(String uid) {
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

        return Container(
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
                      color: Colors.amber.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.notifications_active,
                        color: Colors.amber, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Pending Requests',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.amber)),
                        Text(
                            '${snapshot.data!.docs.length} doctor(s) waiting for approval',
                            style: const TextStyle(
                                fontSize: 12, color: Colors.black54)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              ...snapshot.data!.docs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final doctorName =
                    data['doctorName'] as String? ?? 'A doctor';
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: Colors.amber.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.person_outline,
                          color: Colors.amber, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '$doctorName wants access to your records',
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                      TextButton(
                        style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: const Size(0, 32)),
                        onPressed: () async {
                          await AccessRequestService.denyRequest(doc.id);
                        },
                        child: const Text('Deny',
                            style:
                                TextStyle(color: Colors.red, fontSize: 12)),
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
                            style: TextStyle(
                                color: Colors.white, fontSize: 12)),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  // ── Active access sessions card ───────────────────────────────────────────

  Widget _buildActiveAccessCard(String uid) {
    return Container(
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
                child: const Icon(Icons.people,
                    color: Color(0xFF6C5CE7), size: 20),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Doctor Access',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF6C5CE7))),
                    Text('Doctors who can currently view your records',
                        style: TextStyle(fontSize: 12, color: Colors.black54)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('access_requests')
                .where('patientUid', isEqualTo: uid)
                .where('status', isEqualTo: 'approved')
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(
                    child: Padding(
                  padding: EdgeInsets.all(12),
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Color(0xFF6C5CE7)),
                ));
              }

              final docs = snapshot.data!.docs.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final expiresAt =
                    (data['expiresAt'] as Timestamp?)?.toDate();
                return expiresAt != null &&
                    expiresAt.isAfter(DateTime.now());
              }).toList();

              if (docs.isEmpty) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.check_circle_outline,
                          color: Colors.grey, size: 16),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'No doctors currently have access to your records.',
                          style:
                              TextStyle(fontSize: 12, color: Colors.black54),
                        ),
                      ),
                    ],
                  ),
                );
              }

              return Column(
                children: docs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final doctorName =
                      data['doctorName'] as String? ?? 'Unknown Doctor';
                  final expiresAt =
                      (data['expiresAt'] as Timestamp?)?.toDate();
                  final remaining = expiresAt != null
                      ? expiresAt.difference(DateTime.now())
                      : Duration.zero;
                  final hours = remaining.inHours;
                  final mins = remaining.inMinutes % 60;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: Colors.orange.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.person,
                            color: Colors.orange, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(doctorName,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13)),
                              Text(
                                'Expires in ${hours}h ${mins}m',
                                style: const TextStyle(
                                    fontSize: 11, color: Colors.black54),
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red[50],
                            foregroundColor: Colors.red,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            minimumSize: const Size(0, 32),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: BorderSide(
                                  color: Colors.red.withValues(alpha: 0.3)),
                            ),
                          ),
                          onPressed: () => _revokeAccess(doc.id, uid),
                          child: const Text('Revoke',
                              style: TextStyle(fontSize: 12)),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}
