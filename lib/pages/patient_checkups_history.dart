import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class PatientCheckupsHistory extends StatefulWidget {
  const PatientCheckupsHistory({super.key});

  @override
  State<PatientCheckupsHistory> createState() => _PatientCheckupsHistoryState();
}

class _PatientCheckupsHistoryState extends State<PatientCheckupsHistory> {
  User? get _user => FirebaseAuth.instance.currentUser;

  CollectionReference get _checkupsRef => FirebaseFirestore.instance
      .collection('users')
      .doc(_user!.uid)
      .collection('checkups');

  // ─── Add/Edit checkup ─────────────────────────────────────────────────────
  void _showCheckupSheet({Map<String, dynamic>? existing, String? docId}) {
    final dateC = TextEditingController(text: existing?['date'] ?? '');
    final diseaseC = TextEditingController(text: existing?['disease'] ?? '');
    final treatmentC =
        TextEditingController(text: existing?['treatment'] ?? '');
    final doctorC = TextEditingController(text: existing?['doctor'] ?? '');
    final hospitalC =
        TextEditingController(text: existing?['hospital'] ?? '');
    final bpC = TextEditingController(text: existing?['bp'] ?? '');
    final sugarC = TextEditingController(text: existing?['sugar'] ?? '');
    final tempC = TextEditingController(text: existing?['temp'] ?? '');
    final weightC = TextEditingController(text: existing?['weight'] ?? '');
    final medicinesC =
        TextEditingController(text: existing?['medicines'] ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => _BottomSheet(
        title: docId == null ? 'Add Checkup Record' : 'Edit Checkup Record',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _field(dateC, 'Date (YYYY-MM-DD)', Icons.calendar_today),
            const SizedBox(height: 12),
            _field(diseaseC, 'Condition / Disease', Icons.sick),
            const SizedBox(height: 12),
            _field(treatmentC, 'Treatment / Notes', Icons.healing),
            const SizedBox(height: 12),
            _field(doctorC, 'Doctor Name', Icons.person),
            const SizedBox(height: 12),
            _field(hospitalC, 'Hospital / Clinic', Icons.local_hospital),
            const SizedBox(height: 16),
            const Text('Vitals',
                style:
                    TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: _field(bpC, 'Blood Pressure', Icons.favorite)),
              const SizedBox(width: 10),
              Expanded(
                  child: _field(sugarC, 'Blood Sugar', Icons.water_drop)),
            ]),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(
                  child: _field(tempC, 'Temperature', Icons.thermostat)),
              const SizedBox(width: 10),
              Expanded(
                  child: _field(
                      weightC, 'Weight (e.g. 70 kg)', Icons.monitor_weight)),
            ]),
            const SizedBox(height: 12),
            _field(medicinesC, 'Medicines (comma separated)',
                Icons.medication),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6C5CE7),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () async {
                  if (dateC.text.trim().isEmpty ||
                      diseaseC.text.trim().isEmpty) { return; }
                  final data = {
                    'date': dateC.text.trim(),
                    'disease': diseaseC.text.trim(),
                    'treatment': treatmentC.text.trim(),
                    'doctor': doctorC.text.trim(),
                    'hospital': hospitalC.text.trim(),
                    'bp': bpC.text.trim(),
                    'sugar': sugarC.text.trim(),
                    'temp': tempC.text.trim(),
                    'weight': weightC.text.trim(),
                    'medicines': medicinesC.text.trim(),
                  };
                  if (docId == null) {
                    await _checkupsRef.add(data);
                  } else {
                    await _checkupsRef.doc(docId).update(data);
                  }
                  if (sheetCtx.mounted) Navigator.pop(sheetCtx);
                },
                child: Text(
                    docId == null ? 'Add Record' : 'Save Changes',
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteCheckup(String docId) async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            title: const Text('Delete Record'),
            content:
                const Text('Remove this checkup record permanently?'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel')),
              ElevatedButton(
                style:
                    ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Delete',
                    style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ) ??
        false;
    if (confirmed) await _checkupsRef.doc(docId).delete();
  }

  // ─── Build ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCheckupSheet,
        backgroundColor: const Color(0xFF6C5CE7),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add Record',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header
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
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Medical History',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Your complete medical checkup records',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ),

            // Checkup list
            StreamBuilder<QuerySnapshot>(
              stream: _checkupsRef.orderBy('date', descending: true).snapshots(),
              builder: (_, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Center(
                        child: CircularProgressIndicator(
                            color: Color(0xFF6C5CE7))),
                  );
                }
                final docs = snap.data?.docs ?? [];
                if (docs.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 50),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(Icons.history_edu,
                              size: 56, color: Colors.grey[400]),
                          const SizedBox(height: 14),
                          Text('No checkup records yet',
                              style: TextStyle(
                                  color: Colors.grey[500], fontSize: 15)),
                          const SizedBox(height: 8),
                          Text('Tap + Add Record to begin',
                              style: TextStyle(
                                  color: Colors.grey[400], fontSize: 13)),
                        ],
                      ),
                    ),
                  );
                }
                return Column(
                  children: docs.map((doc) {
                    final d = doc.data() as Map<String, dynamic>;
                    return _CheckupCard(
                      data: d,
                      onEdit: () =>
                          _showCheckupSheet(existing: d, docId: doc.id),
                      onDelete: () => _deleteCheckup(doc.id),
                    );
                  }).toList(),
                );
              },
            ),

            const SizedBox(height: 100), // FAB clearance
          ],
        ),
      ),
    );
  }
}

// ─── Checkup card ─────────────────────────────────────────────────────────────
class _CheckupCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _CheckupCard(
      {required this.data, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final medicines = (data['medicines'] as String? ?? '')
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
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
        children: [
          // Card header
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFF6C5CE7).withValues(alpha: 0.08),
              borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6C5CE7),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.medical_services,
                      color: Colors.white, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data['disease'] ?? '',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 17,
                            color: Color(0xFF6C5CE7)),
                      ),
                      Text(
                        data['date'] ?? '',
                        style: const TextStyle(
                            color: Colors.grey, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit,
                      size: 18, color: Color(0xFF6C5CE7)),
                  onPressed: onEdit,
                ),
                IconButton(
                  icon: Icon(Icons.delete,
                      size: 18, color: Colors.red[400]),
                  onPressed: onDelete,
                ),
              ],
            ),
          ),

          // Card body
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if ((data['doctor'] as String? ?? '').isNotEmpty)
                  _infoRow('Doctor', data['doctor']),
                if ((data['hospital'] as String? ?? '').isNotEmpty)
                  _infoRow('Hospital', data['hospital']),
                if ((data['treatment'] as String? ?? '').isNotEmpty)
                  _infoRow('Treatment', data['treatment']),

                // Vitals
                if (_hasVitals(data)) ...[
                  const SizedBox(height: 14),
                  const Text('Vital Signs',
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF6C5CE7))),
                  const SizedBox(height: 10),
                  Row(children: [
                    if ((data['bp'] as String? ?? '').isNotEmpty)
                      Expanded(
                          child: _vitalCard(
                              'Blood Pressure', data['bp'], Icons.favorite)),
                    if ((data['sugar'] as String? ?? '').isNotEmpty) ...[
                      const SizedBox(width: 10),
                      Expanded(
                          child: _vitalCard(
                              'Blood Sugar', data['sugar'], Icons.water_drop)),
                    ],
                  ]),
                  const SizedBox(height: 10),
                  Row(children: [
                    if ((data['temp'] as String? ?? '').isNotEmpty)
                      Expanded(
                          child: _vitalCard(
                              'Temperature', data['temp'], Icons.thermostat)),
                    if ((data['weight'] as String? ?? '').isNotEmpty) ...[
                      const SizedBox(width: 10),
                      Expanded(
                          child: _vitalCard('Weight', data['weight'],
                              Icons.monitor_weight)),
                    ],
                  ]),
                ],

                // Medicines
                if (medicines.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  const Text('Medicines Prescribed',
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF6C5CE7))),
                  const SizedBox(height: 10),
                  ...medicines.map((m) => Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green[200]!),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.medication,
                                color: Colors.green[600], size: 16),
                            const SizedBox(width: 8),
                            Text(m,
                                style: TextStyle(
                                    color: Colors.green[700], fontSize: 13)),
                          ],
                        ),
                      )),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool _hasVitals(Map<String, dynamic> d) =>
      (d['bp'] as String? ?? '').isNotEmpty ||
      (d['sugar'] as String? ?? '').isNotEmpty ||
      (d['temp'] as String? ?? '').isNotEmpty ||
      (d['weight'] as String? ?? '').isNotEmpty;

  Widget _infoRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 78,
            child: Text('$label:',
                style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: Colors.black87)),
          ),
          Expanded(
            child: Text(value ?? '',
                style: const TextStyle(
                    fontSize: 13, color: Colors.black54)),
          ),
        ],
      ),
    );
  }

  Widget _vitalCard(String title, String? value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.blue[600], size: 18),
          const SizedBox(height: 4),
          Text(title,
              style: TextStyle(
                  fontSize: 11,
                  color: Colors.blue[600],
                  fontWeight: FontWeight.w500),
              textAlign: TextAlign.center),
          const SizedBox(height: 2),
          Text(value ?? '',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[700]),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

// ─── Reusable bottom sheet container ─────────────────────────────────────────
class _BottomSheet extends StatelessWidget {
  final String title;
  final Widget child;

  const _BottomSheet({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(4)),
              ),
            ),
            const SizedBox(height: 16),
            Text(title,
                style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF6C5CE7))),
            const SizedBox(height: 20),
            child,
          ],
        ),
      ),
    );
  }
}

// ─── Field helper ─────────────────────────────────────────────────────────────
Widget _field(TextEditingController c, String label, IconData icon) {
  return TextField(
    controller: c,
    decoration: InputDecoration(
      filled: true,
      fillColor: const Color(0xFFF8F9FA),
      contentPadding: const EdgeInsets.all(14),
      labelText: label,
      labelStyle: const TextStyle(color: Color(0xFF6C5CE7)),
      prefixIcon: Icon(icon, color: const Color(0xFF6C5CE7)),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:
              const BorderSide(color: Color(0xFF6C5CE7), width: 2)),
    ),
  );
}
