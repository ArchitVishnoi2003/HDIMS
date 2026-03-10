import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class PatientAppointments extends StatefulWidget {
  const PatientAppointments({super.key});

  @override
  State<PatientAppointments> createState() => _PatientAppointmentsState();
}

class _PatientAppointmentsState extends State<PatientAppointments> {
  User? get _user => FirebaseAuth.instance.currentUser;

  CollectionReference get _aptsRef => FirebaseFirestore.instance
      .collection('users')
      .doc(_user!.uid)
      .collection('appointments');

  // ─── Add/Edit appointment ─────────────────────────────────────────────────
  void _showAppointmentSheet({Map<String, dynamic>? existing, String? docId}) {
    final doctorC = TextEditingController(text: existing?['doctor'] ?? '');
    final hospitalC =
        TextEditingController(text: existing?['hospital'] ?? '');
    final deptC =
        TextEditingController(text: existing?['department'] ?? '');
    final dateC = TextEditingController(text: existing?['date'] ?? '');
    final timeC = TextEditingController(text: existing?['time'] ?? '');
    final typeC = TextEditingController(text: existing?['type'] ?? '');
    final notesC = TextEditingController(text: existing?['notes'] ?? '');
    String status = existing?['status'] ?? 'Upcoming';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => StatefulBuilder(
        builder: (ctx, setSheet) => _BottomSheet(
          title:
              docId == null ? 'Book Appointment' : 'Edit Appointment',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _field(doctorC, 'Doctor Name', Icons.person),
              const SizedBox(height: 12),
              _field(hospitalC, 'Hospital / Clinic', Icons.local_hospital),
              const SizedBox(height: 12),
              _field(deptC, 'Department', Icons.medical_services),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                    child:
                        _field(dateC, 'Date (YYYY-MM-DD)', Icons.calendar_today)),
                const SizedBox(width: 10),
                Expanded(
                    child: _field(
                        timeC, 'Time (e.g. 10:30 AM)', Icons.access_time)),
              ]),
              const SizedBox(height: 12),
              _field(typeC, 'Type (e.g. Regular Checkup)', Icons.category),
              const SizedBox(height: 12),
              _field(notesC, 'Notes', Icons.notes),
              const SizedBox(height: 14),
              const Text('Status',
                  style: TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 14)),
              const SizedBox(height: 8),
              Row(
                children:
                    ['Upcoming', 'Completed', 'Cancelled'].map((s) {
                  final sel = status == s;
                  Color c = s == 'Upcoming'
                      ? Colors.green
                      : s == 'Completed'
                          ? Colors.blue
                          : Colors.red;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(s,
                          style: TextStyle(
                              color:
                                  sel ? Colors.white : Colors.black87,
                              fontSize: 12)),
                      selected: sel,
                      selectedColor: c,
                      onSelected: (_) => setSheet(() => status = s),
                    ),
                  );
                }).toList(),
              ),
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
                    if (doctorC.text.trim().isEmpty ||
                        dateC.text.trim().isEmpty) { return; }
                    final data = {
                      'doctor': doctorC.text.trim(),
                      'hospital': hospitalC.text.trim(),
                      'department': deptC.text.trim(),
                      'date': dateC.text.trim(),
                      'time': timeC.text.trim(),
                      'type': typeC.text.trim(),
                      'notes': notesC.text.trim(),
                      'status': status,
                    };
                    if (docId == null) {
                      await _aptsRef.add(data);
                    } else {
                      await _aptsRef.doc(docId).update(data);
                    }
                    if (ctx.mounted) { Navigator.pop(ctx); }
                  },
                  child: Text(
                      docId == null
                          ? 'Book Appointment'
                          : 'Save Changes',
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _deleteAppointment(String docId) async {
    final ok = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            title: const Text('Delete Appointment'),
            content:
                const Text('Remove this appointment permanently?'),
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
    if (ok) { await _aptsRef.doc(docId).delete(); }
  }

  // ─── Build ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAppointmentSheet,
        backgroundColor: const Color(0xFF6C5CE7),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Book',
            style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _aptsRef.orderBy('date', descending: false).snapshots(),
        builder: (_, snap) {
          final docs = snap.data?.docs ?? [];
          final upcoming = docs
              .where((d) =>
                  (d.data() as Map<String, dynamic>)['status'] ==
                  'Upcoming')
              .toList();
          final past = docs
              .where((d) =>
                  (d.data() as Map<String, dynamic>)['status'] !=
                  'Upcoming')
              .toList();

          return SingleChildScrollView(
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
                        color: const Color(0xFF6C5CE7)
                            .withValues(alpha: 0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Appointments',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold)),
                      SizedBox(height: 8),
                      Text('Manage your upcoming and past appointments',
                          style: TextStyle(
                              color: Colors.white70, fontSize: 14)),
                    ],
                  ),
                ),

                // Stats row
                if (snap.connectionState != ConnectionState.waiting)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        Expanded(
                            child: _statCard('Upcoming',
                                upcoming.length.toString(),
                                Icons.schedule, Colors.green)),
                        const SizedBox(width: 15),
                        Expanded(
                            child: _statCard('Past', past.length.toString(),
                                Icons.history, Colors.blue)),
                      ],
                    ),
                  ),

                const SizedBox(height: 20),

                if (snap.connectionState == ConnectionState.waiting)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Center(
                        child: CircularProgressIndicator(
                            color: Color(0xFF6C5CE7))),
                  )
                else if (docs.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 50),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(Icons.calendar_today,
                              size: 56, color: Colors.grey[400]),
                          const SizedBox(height: 14),
                          Text('No appointments yet',
                              style: TextStyle(
                                  color: Colors.grey[500], fontSize: 15)),
                          const SizedBox(height: 8),
                          Text('Tap Book to schedule one',
                              style: TextStyle(
                                  color: Colors.grey[400], fontSize: 13)),
                        ],
                      ),
                    ),
                  )
                else ...[
                  if (upcoming.isNotEmpty)
                    _section(
                      icon: Icons.schedule,
                      iconColor: Colors.green[600]!,
                      title: 'Upcoming',
                      docs: upcoming,
                    ),
                  if (past.isNotEmpty)
                    _section(
                      icon: Icons.history,
                      iconColor: Colors.blue[600]!,
                      title: 'Past',
                      docs: past,
                    ),
                ],

                const SizedBox(height: 100),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _section({
    required IconData icon,
    required Color iconColor,
    required String title,
    required List<QueryDocumentSnapshot> docs,
  }) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
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
          Row(children: [
            Icon(icon, color: iconColor),
            const SizedBox(width: 8),
            Text('$title Appointments',
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF6C5CE7))),
          ]),
          const SizedBox(height: 16),
          ...docs.map((doc) {
            final d = doc.data() as Map<String, dynamic>;
            return _AppointmentCard(
              data: d,
              onEdit: () =>
                  _showAppointmentSheet(existing: d, docId: doc.id),
              onDelete: () => _deleteAppointment(doc.id),
            );
          }),
        ],
      ),
    );
  }

  Widget _statCard(
      String label, String value, IconData icon, Color color) {
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
          Text(value,
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: color)),
          Text(label,
              style: const TextStyle(fontSize: 13, color: Colors.grey)),
        ],
      ),
    );
  }
}

// ─── Appointment card ─────────────────────────────────────────────────────────
class _AppointmentCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _AppointmentCard(
      {required this.data, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final status = data['status'] as String? ?? 'Upcoming';
    final isUpcoming = status == 'Upcoming';
    final Color statusColor = isUpcoming
        ? Colors.green
        : status == 'Completed'
            ? Colors.blue
            : Colors.red;
    final Color bg = isUpcoming
        ? Colors.green[50]!
        : status == 'Completed'
            ? Colors.blue[50]!
            : Colors.red[50]!;
    final Color border = isUpcoming
        ? Colors.green[200]!
        : status == 'Completed'
            ? Colors.blue[200]!
            : Colors.red[200]!;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(8)),
                child: Icon(
                    isUpcoming ? Icons.schedule : Icons.check_circle,
                    color: Colors.white,
                    size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(data['doctor'] ?? '',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: statusColor)),
                    if ((data['hospital'] as String? ?? '').isNotEmpty)
                      Text(data['hospital'],
                          style: const TextStyle(
                              color: Colors.grey, fontSize: 12)),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(10)),
                child: Text(status,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 4),
              IconButton(
                icon: const Icon(Icons.edit,
                    size: 16, color: Color(0xFF6C5CE7)),
                onPressed: onEdit,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 4),
              IconButton(
                icon: Icon(Icons.delete, size: 16, color: Colors.red[400]),
                onPressed: onDelete,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(children: [
            Icon(Icons.calendar_today, color: statusColor, size: 14),
            const SizedBox(width: 6),
            Text(data['date'] ?? '',
                style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.w500,
                    fontSize: 13)),
            if ((data['time'] as String? ?? '').isNotEmpty) ...[
              const SizedBox(width: 16),
              Icon(Icons.access_time, color: statusColor, size: 14),
              const SizedBox(width: 6),
              Text(data['time'],
                  style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.w500,
                      fontSize: 13)),
            ],
          ]),
          if ((data['department'] as String? ?? '').isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(children: [
              Icon(Icons.medical_services, color: statusColor, size: 14),
              const SizedBox(width: 6),
              Text(data['department'],
                  style: TextStyle(color: statusColor, fontSize: 13)),
            ]),
          ],
          if ((data['type'] as String? ?? '').isNotEmpty) ...[
            const SizedBox(height: 4),
            Text('Type: ${data['type']}',
                style:
                    const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
          if ((data['notes'] as String? ?? '').isNotEmpty) ...[
            const SizedBox(height: 4),
            Text('Notes: ${data['notes']}',
                style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    fontStyle: FontStyle.italic)),
          ],
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
