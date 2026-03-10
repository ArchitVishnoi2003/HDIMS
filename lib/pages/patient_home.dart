import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class PatientHome extends StatelessWidget {
  final String? linkedPatientId;
  const PatientHome({super.key, this.linkedPatientId});

  User? get _user => FirebaseAuth.instance.currentUser;

  DocumentReference get _userDoc => FirebaseFirestore.instance
      .collection('users')
      .doc(_user!.uid);

  CollectionReference get _allergiesRef =>
      _userDoc.collection('allergies');

  CollectionReference get _appointmentsRef =>
      _userDoc.collection('appointments');

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: _userDoc.snapshots(),
      builder: (_, userSnap) {
        final user = userSnap.data?.data() as Map<String, dynamic>? ?? {};
        final name = user['name'] as String? ?? 'Patient';

        return SingleChildScrollView(
          child: Column(
            children: [
              // Welcome header
              Container(
                width: double.infinity,
                margin: const EdgeInsets.all(20),
                padding: const EdgeInsets.all(25),
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome back, $name!',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Here's your health overview",
                      style:
                          TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ],
                ),
              ),

              // Quick stats
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Expanded(
                        child: _statCard(
                            'Weight',
                            user['weight'] as String? ?? '—',
                            Icons.monitor_weight,
                            const Color(0xFF4CAF50))),
                    const SizedBox(width: 15),
                    Expanded(
                        child: _statCard(
                            'Height',
                            user['height'] as String? ?? '—',
                            Icons.height,
                            const Color(0xFF2196F3))),
                  ],
                ),
              ),
              const SizedBox(height: 15),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Expanded(
                        child: _statCard(
                            'Blood Group',
                            user['bloodGroup'] as String? ?? '—',
                            Icons.bloodtype,
                            const Color(0xFFE91E63))),
                    const SizedBox(width: 15),
                    Expanded(
                        child: _statCard(
                            'Age',
                            user['age'] != null
                                ? '${user['age']} yrs'
                                : '—',
                            Icons.cake,
                            const Color(0xFFFF9800))),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Allergy alerts
              StreamBuilder<QuerySnapshot>(
                stream: _allergiesRef.snapshots(),
                builder: (_, allergySnap) {
                  final docs = allergySnap.data?.docs ?? [];
                  if (docs.isEmpty) { return const SizedBox.shrink(); }
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.red[200]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Icon(Icons.warning, color: Colors.red[600]),
                          const SizedBox(width: 8),
                          Text(
                            'Allergy Alerts',
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.red[600]),
                          ),
                        ]),
                        const SizedBox(height: 10),
                        ...docs.map((doc) {
                          final d = doc.data() as Map<String, dynamic>;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 5),
                            child: Row(children: [
                              Icon(Icons.close,
                                  color: Colors.red[600], size: 16),
                              const SizedBox(width: 8),
                              Text(
                                d['allergen'] ?? '',
                                style: TextStyle(
                                    color: Colors.red[600],
                                    fontWeight: FontWeight.w500),
                              ),
                              if ((d['severity'] as String? ?? '')
                                  .isNotEmpty) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                      color: _severityColor(
                                          d['severity'] as String),
                                      borderRadius:
                                          BorderRadius.circular(8)),
                                  child: Text(d['severity'],
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ]),
                          );
                        }),
                        const SizedBox(height: 8),
                        Text(
                          'Avoid medicines containing these substances',
                          style: TextStyle(
                              color: Colors.red[600],
                              fontSize: 12,
                              fontStyle: FontStyle.italic),
                        ),
                      ],
                    ),
                  );
                },
              ),

              const SizedBox(height: 24),

              // Doctor's record card (only shown when linked)
              if (linkedPatientId != null)
                StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('patients')
                      .doc(linkedPatientId)
                      .snapshots(),
                  builder: (_, drSnap) {
                    if (!drSnap.hasData || !drSnap.data!.exists) {
                      return const SizedBox.shrink();
                    }
                    final dr = drSnap.data!.data() as Map<String, dynamic>;
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: const Color(0xFF6C5CE7).withValues(alpha: 0.3)),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF6C5CE7).withValues(alpha: 0.07),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF6C5CE7),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.medical_services,
                                  color: Colors.white, size: 18),
                            ),
                            const SizedBox(width: 10),
                            const Text(
                              "Doctor's Record",
                              style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF6C5CE7)),
                            ),
                          ]),
                          const SizedBox(height: 14),
                          if ((dr['blood'] as String? ?? '').isNotEmpty)
                            _drRow(Icons.bloodtype, 'Blood Group', dr['blood']),
                          if ((dr['allergies'] as String? ?? '').isNotEmpty)
                            _drRow(Icons.warning_amber, 'Allergies (Doctor)', dr['allergies']),
                          if ((dr['current medication'] as String? ?? '').isNotEmpty)
                            _drRow(Icons.medication, 'Current Medications', dr['current medication']),
                          const SizedBox(height: 8),
                          Text(
                            'Data provided by your doctor. Edit from Doctor Settings.',
                            style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[500],
                                fontStyle: FontStyle.italic),
                          ),
                        ],
                      ),
                    );
                  },
                ),

              const SizedBox(height: 24),

              // Quick access
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
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
                    const Text('Quick Access',
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF6C5CE7))),
                    const SizedBox(height: 20),
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      crossAxisSpacing: 15,
                      mainAxisSpacing: 15,
                      childAspectRatio: 1.3,
                      children: [
                        _askAICard(context),
                        _quickLinkCard('Medical History',
                            Icons.history, const Color(0xFF4CAF50)),
                        _quickLinkCard('Appointments',
                            Icons.calendar_today, const Color(0xFF2196F3)),
                        _quickLinkCard('Medicines', Icons.medication,
                            const Color(0xFFE91E63)),
                        _quickLinkCard('Daily Routine', Icons.schedule,
                            const Color(0xFFFF9800)),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Upcoming appointments preview
              StreamBuilder<QuerySnapshot>(
                stream: _appointmentsRef
                    .where('status', isEqualTo: 'Upcoming')
                    .orderBy('date')
                    .limit(3)
                    .snapshots(),
                builder: (_, aptSnap) {
                  final docs = aptSnap.data?.docs ?? [];
                  if (docs.isEmpty) { return const SizedBox.shrink(); }
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color:
                              Colors.black.withValues(alpha: 0.08),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Upcoming Appointments',
                            style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF6C5CE7))),
                        const SizedBox(height: 15),
                        ...docs.map((doc) {
                          final d =
                              doc.data() as Map<String, dynamic>;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _appointmentPreview(
                              d['doctor'] ?? '',
                              d['hospital'] ?? '',
                              d['date'] ?? '',
                              d['time'] ?? '',
                            ),
                          );
                        }),
                      ],
                    ),
                  );
                },
              ),

              const SizedBox(height: 30),
            ],
          ),
        );
      },
    );
  }

  Color _severityColor(String s) {
    switch (s.toLowerCase()) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      default:
        return Colors.yellow[700]!;
    }
  }

  Widget _drRow(IconData icon, String label, String? value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: const Color(0xFF6C5CE7)),
          const SizedBox(width: 8),
          SizedBox(
            width: 130,
            child: Text('$label:',
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87)),
          ),
          Expanded(
            child: Text(value ?? '',
                style: const TextStyle(fontSize: 13, color: Colors.black54)),
          ),
        ],
      ),
    );
  }

  Widget _statCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(title,
              style: const TextStyle(
                  fontSize: 13,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: color)),
        ],
      ),
    );
  }

  Widget _quickLinkCard(String title, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 6),
          Text(
            title,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _askAICard(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/ask-ai'),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF6C5CE7), Color(0xFF74B9FF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6C5CE7).withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.psychology, color: Colors.white, size: 28),
            SizedBox(height: 6),
            Text(
              'Ask AI',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _appointmentPreview(
      String doctor, String hospital, String date, String time) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF6C5CE7).withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: const Color(0xFF6C5CE7).withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: const Color(0xFF6C5CE7),
                borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.calendar_today,
                color: Colors.white, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(doctor,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15)),
                if (hospital.isNotEmpty)
                  Text(hospital,
                      style: const TextStyle(
                          color: Colors.grey, fontSize: 13)),
                Text(
                  '$date${time.isNotEmpty ? ' at $time' : ''}',
                  style: const TextStyle(
                      color: Color(0xFF6C5CE7),
                      fontSize: 12,
                      fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
