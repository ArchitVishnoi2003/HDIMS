import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class PatientRoutine extends StatefulWidget {
  const PatientRoutine({super.key});

  @override
  State<PatientRoutine> createState() => _PatientRoutineState();
}

class _PatientRoutineState extends State<PatientRoutine>
    with TickerProviderStateMixin {
  late TabController _tabController;

  User? get _user => FirebaseAuth.instance.currentUser;

  // Each tab has its own subcollection
  CollectionReference _col(String name) => FirebaseFirestore.instance
      .collection('users')
      .doc(_user!.uid)
      .collection(name);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ─── Generic add/edit sheet builder ──────────────────────────────────────
  void _showSheet({
    required String colName,
    required String sheetTitle,
    required List<_FieldDef> fields,
    Map<String, dynamic>? existing,
    String? docId,
  }) {
    final controllers = {
      for (final f in fields)
        f.key: TextEditingController(text: existing?[f.key] ?? '')
    };

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => _BottomSheet(
        title: sheetTitle,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ...fields.map((f) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _field(controllers[f.key]!, f.label, f.icon),
                )),
            const SizedBox(height: 12),
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
                  final data = {
                    for (final f in fields)
                      f.key: controllers[f.key]!.text.trim()
                  };
                  if (docId == null) {
                    await _col(colName).add(data);
                  } else {
                    await _col(colName).doc(docId).update(data);
                  }
                  if (sheetCtx.mounted) { Navigator.pop(sheetCtx); }
                },
                child: Text(
                    docId == null ? 'Add Entry' : 'Save Changes',
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

  Future<void> _delete(String colName, String docId) async {
    final ok = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            title: const Text('Delete Entry'),
            content: const Text('Remove this entry permanently?'),
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
    if (ok) { await _col(colName).doc(docId).delete(); }
  }

  // ─── Build ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Column(
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
              Text('Daily Routine',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Text("Follow your doctor's recommended daily routine",
                  style: TextStyle(color: Colors.white70, fontSize: 14)),
            ],
          ),
        ),

        // Tab bar
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
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
          child: TabBar(
            controller: _tabController,
            indicator: BoxDecoration(
                color: const Color(0xFF6C5CE7),
                borderRadius: BorderRadius.circular(15)),
            labelColor: Colors.white,
            unselectedLabelColor: const Color(0xFF6C5CE7),
            labelStyle: const TextStyle(fontWeight: FontWeight.bold),
            tabs: const [
              Tab(text: 'Daily'),
              Tab(text: 'Exercise'),
              Tab(text: 'Diet'),
            ],
          ),
        ),

        // Tab content
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _DailyTab(
                stream: _col('routine_daily').orderBy('time').snapshots(),
                onAdd: () => _showSheet(
                  colName: 'routine_daily',
                  sheetTitle: 'Add Daily Activity',
                  fields: [
                    _FieldDef('time', 'Time (e.g. 07:00 AM)', Icons.schedule),
                    _FieldDef('activity', 'Activity', Icons.event_note),
                  ],
                ),
                onEdit: (d, id) => _showSheet(
                  colName: 'routine_daily',
                  sheetTitle: 'Edit Activity',
                  fields: [
                    _FieldDef('time', 'Time (e.g. 07:00 AM)', Icons.schedule),
                    _FieldDef('activity', 'Activity', Icons.event_note),
                  ],
                  existing: d,
                  docId: id,
                ),
                onDelete: (id) => _delete('routine_daily', id),
              ),
              _ExerciseTab(
                stream:
                    _col('routine_exercise').orderBy('name').snapshots(),
                onAdd: () => _showSheet(
                  colName: 'routine_exercise',
                  sheetTitle: 'Add Exercise',
                  fields: [
                    _FieldDef('name', 'Exercise Name', Icons.fitness_center),
                    _FieldDef('duration', 'Duration', Icons.timer),
                    _FieldDef('frequency', 'Frequency', Icons.repeat),
                    _FieldDef('benefits', 'Benefits', Icons.thumb_up),
                    _FieldDef('instructions', 'Instructions', Icons.info_outline),
                  ],
                ),
                onEdit: (d, id) => _showSheet(
                  colName: 'routine_exercise',
                  sheetTitle: 'Edit Exercise',
                  fields: [
                    _FieldDef('name', 'Exercise Name', Icons.fitness_center),
                    _FieldDef('duration', 'Duration', Icons.timer),
                    _FieldDef('frequency', 'Frequency', Icons.repeat),
                    _FieldDef('benefits', 'Benefits', Icons.thumb_up),
                    _FieldDef('instructions', 'Instructions', Icons.info_outline),
                  ],
                  existing: d,
                  docId: id,
                ),
                onDelete: (id) => _delete('routine_exercise', id),
              ),
              _DietTab(
                stream: _col('routine_diet').orderBy('time').snapshots(),
                onAdd: () => _showSheet(
                  colName: 'routine_diet',
                  sheetTitle: 'Add Meal',
                  fields: [
                    _FieldDef('meal', 'Meal Name (e.g. Breakfast)', Icons.restaurant),
                    _FieldDef('time', 'Time (e.g. 8:00 AM)', Icons.schedule),
                    _FieldDef('food', 'Food Items', Icons.fastfood),
                    _FieldDef('notes', 'Notes / Restrictions', Icons.notes),
                  ],
                ),
                onEdit: (d, id) => _showSheet(
                  colName: 'routine_diet',
                  sheetTitle: 'Edit Meal',
                  fields: [
                    _FieldDef('meal', 'Meal Name (e.g. Breakfast)', Icons.restaurant),
                    _FieldDef('time', 'Time (e.g. 8:00 AM)', Icons.schedule),
                    _FieldDef('food', 'Food Items', Icons.fastfood),
                    _FieldDef('notes', 'Notes / Restrictions', Icons.notes),
                  ],
                  existing: d,
                  docId: id,
                ),
                onDelete: (id) => _delete('routine_diet', id),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Field definition helper ──────────────────────────────────────────────────
class _FieldDef {
  final String key;
  final String label;
  final IconData icon;
  const _FieldDef(this.key, this.label, this.icon);
}

// ─── Daily tab ────────────────────────────────────────────────────────────────
class _DailyTab extends StatelessWidget {
  final Stream<QuerySnapshot> stream;
  final VoidCallback onAdd;
  final void Function(Map<String, dynamic>, String) onEdit;
  final void Function(String) onDelete;

  const _DailyTab({
    required this.stream,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton(
        onPressed: onAdd,
        backgroundColor: const Color(0xFF6C5CE7),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: stream,
        builder: (_, snap) {
          final docs = snap.data?.docs ?? [];
          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 80),
              child: Container(
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
                    const Text("Today's Schedule",
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF6C5CE7))),
                    const SizedBox(height: 16),
                    if (snap.connectionState == ConnectionState.waiting)
                      const Center(
                          child: CircularProgressIndicator(
                              color: Color(0xFF6C5CE7)))
                    else if (docs.isEmpty)
                      _empty('No activities yet. Tap + to add one.')
                    else
                      ...docs.map((doc) {
                        final d = doc.data() as Map<String, dynamic>;
                        return _RoutineRow(
                          time: d['time'] ?? '',
                          activity: d['activity'] ?? '',
                          onEdit: () => onEdit(d, doc.id),
                          onDelete: () => onDelete(doc.id),
                        );
                      }),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _RoutineRow extends StatelessWidget {
  final String time;
  final String activity;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _RoutineRow({
    required this.time,
    required this.activity,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF6C5CE7).withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: const Color(0xFF6C5CE7).withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF6C5CE7),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.schedule,
                color: Colors.white, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(time,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF6C5CE7),
                        fontSize: 14)),
                Text(activity,
                    style: const TextStyle(
                        fontSize: 13, color: Colors.black87)),
              ],
            ),
          ),
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
    );
  }
}

// ─── Exercise tab ─────────────────────────────────────────────────────────────
class _ExerciseTab extends StatelessWidget {
  final Stream<QuerySnapshot> stream;
  final VoidCallback onAdd;
  final void Function(Map<String, dynamic>, String) onEdit;
  final void Function(String) onDelete;

  const _ExerciseTab({
    required this.stream,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton(
        onPressed: onAdd,
        backgroundColor: Colors.green[600],
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: stream,
        builder: (_, snap) {
          final docs = snap.data?.docs ?? [];
          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 80),
              child: Container(
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
                    const Text('Exercise Routine',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF6C5CE7))),
                    const SizedBox(height: 16),
                    if (snap.connectionState == ConnectionState.waiting)
                      const Center(
                          child: CircularProgressIndicator(
                              color: Color(0xFF6C5CE7)))
                    else if (docs.isEmpty)
                      _empty('No exercises yet. Tap + to add one.')
                    else
                      ...docs.map((doc) {
                        final d = doc.data() as Map<String, dynamic>;
                        return _ExerciseCard(
                          data: d,
                          onEdit: () => onEdit(d, doc.id),
                          onDelete: () => onDelete(doc.id),
                        );
                      }),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ExerciseCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ExerciseCard(
      {required this.data, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.fitness_center, color: Colors.green[600], size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(data['name'] ?? '',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green[700],
                      fontSize: 15)),
            ),
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
          ]),
          if ((data['duration'] as String? ?? '').isNotEmpty ||
              (data['frequency'] as String? ?? '').isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                  '${data['duration'] ?? ''}  •  ${data['frequency'] ?? ''}',
                  style: const TextStyle(fontSize: 13)),
            ),
          if ((data['benefits'] as String? ?? '').isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text('Benefits: ${data['benefits']}',
                  style: const TextStyle(fontSize: 13)),
            ),
          if ((data['instructions'] as String? ?? '').isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(data['instructions'],
                  style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic)),
            ),
        ],
      ),
    );
  }
}

// ─── Diet tab ─────────────────────────────────────────────────────────────────
class _DietTab extends StatelessWidget {
  final Stream<QuerySnapshot> stream;
  final VoidCallback onAdd;
  final void Function(Map<String, dynamic>, String) onEdit;
  final void Function(String) onDelete;

  const _DietTab({
    required this.stream,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton(
        onPressed: onAdd,
        backgroundColor: Colors.orange[600],
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: stream,
        builder: (_, snap) {
          final docs = snap.data?.docs ?? [];
          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 80),
              child: Container(
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
                    const Text('Diet Plan',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF6C5CE7))),
                    const SizedBox(height: 16),
                    if (snap.connectionState == ConnectionState.waiting)
                      const Center(
                          child: CircularProgressIndicator(
                              color: Color(0xFF6C5CE7)))
                    else if (docs.isEmpty)
                      _empty('No meals yet. Tap + to add one.')
                    else
                      ...docs.map((doc) {
                        final d = doc.data() as Map<String, dynamic>;
                        return _MealCard(
                          data: d,
                          onEdit: () => onEdit(d, doc.id),
                          onDelete: () => onDelete(doc.id),
                        );
                      }),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _MealCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _MealCard(
      {required this.data, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.restaurant, color: Colors.orange[600], size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(data['meal'] ?? '',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.orange[700],
                      fontSize: 15)),
            ),
            if ((data['time'] as String? ?? '').isNotEmpty)
              Text(data['time'],
                  style: TextStyle(
                      color: Colors.orange[600],
                      fontWeight: FontWeight.w500,
                      fontSize: 13)),
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
          ]),
          if ((data['food'] as String? ?? '').isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(data['food'],
                  style: const TextStyle(fontSize: 13)),
            ),
          if ((data['notes'] as String? ?? '').isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text('Notes: ${data['notes']}',
                  style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic)),
            ),
        ],
      ),
    );
  }
}

// ─── Shared helpers ───────────────────────────────────────────────────────────
Widget _empty(String msg) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 30),
    child: Center(
      child: Text(msg,
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey[500], fontSize: 14)),
    ),
  );
}

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
