import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

// ─── Field definition helper ──────────────────────────────────────────────────
class RoutineFieldDef {
  final String key;
  final String label;
  final IconData icon;
  const RoutineFieldDef(this.key, this.label, this.icon);
}

// ─── Daily tab ────────────────────────────────────────────────────────────────
class DailyTab extends StatelessWidget {
  final Stream<QuerySnapshot> stream;
  final VoidCallback onAdd;
  final void Function(Map<String, dynamic>, String) onEdit;
  final void Function(String) onDelete;

  const DailyTab({
    super.key,
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
                      routineEmpty('No activities yet. Tap + to add one.')
                    else
                      ...docs.map((doc) {
                        final d = doc.data() as Map<String, dynamic>;
                        return RoutineRow(
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

class RoutineRow extends StatelessWidget {
  final String time;
  final String activity;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const RoutineRow({
    super.key,
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
class ExerciseTab extends StatelessWidget {
  final Stream<QuerySnapshot> stream;
  final VoidCallback onAdd;
  final void Function(Map<String, dynamic>, String) onEdit;
  final void Function(String) onDelete;

  const ExerciseTab({
    super.key,
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
                      routineEmpty('No exercises yet. Tap + to add one.')
                    else
                      ...docs.map((doc) {
                        final d = doc.data() as Map<String, dynamic>;
                        return ExerciseCard(
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

class ExerciseCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const ExerciseCard(
      {super.key,
      required this.data,
      required this.onEdit,
      required this.onDelete});

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
class DietTab extends StatelessWidget {
  final Stream<QuerySnapshot> stream;
  final VoidCallback onAdd;
  final void Function(Map<String, dynamic>, String) onEdit;
  final void Function(String) onDelete;

  const DietTab({
    super.key,
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
                      routineEmpty('No meals yet. Tap + to add one.')
                    else
                      ...docs.map((doc) {
                        final d = doc.data() as Map<String, dynamic>;
                        return MealCard(
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

class MealCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const MealCard(
      {super.key,
      required this.data,
      required this.onEdit,
      required this.onDelete});

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
Widget routineEmpty(String msg) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 30),
    child: Center(
      child: Text(msg,
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey[500], fontSize: 14)),
    ),
  );
}

class RoutineBottomSheet extends StatelessWidget {
  final String title;
  final Widget child;

  const RoutineBottomSheet(
      {super.key, required this.title, required this.child});

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

Widget routineTextField(
    TextEditingController c, String label, IconData icon) {
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
