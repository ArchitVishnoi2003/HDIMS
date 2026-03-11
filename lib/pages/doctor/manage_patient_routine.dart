import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutterapp/widgets/routine_widgets.dart';

class ManagePatientRoutine extends StatefulWidget {
  final String patientUid;
  final String patientName;

  const ManagePatientRoutine({
    super.key,
    required this.patientUid,
    required this.patientName,
  });

  @override
  State<ManagePatientRoutine> createState() => _ManagePatientRoutineState();
}

class _ManagePatientRoutineState extends State<ManagePatientRoutine>
    with TickerProviderStateMixin {
  late TabController _tabController;

  CollectionReference _col(String name) => FirebaseFirestore.instance
      .collection('users')
      .doc(widget.patientUid)
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
    required List<RoutineFieldDef> fields,
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
      builder: (sheetCtx) => RoutineBottomSheet(
        title: sheetTitle,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ...fields.map((f) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: routineTextField(controllers[f.key]!, f.label, f.icon),
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
                  if (sheetCtx.mounted) Navigator.pop(sheetCtx);
                },
                child: Text(
                    docId == null ? 'Add Entry' : 'Save Changes',
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
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
    if (ok) await _col(colName).doc(docId).delete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(
          'Routine for ${widget.patientName}',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF6C5CE7),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          // Tab bar
          Container(
            margin: const EdgeInsets.all(20),
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
                DailyTab(
                  stream: _col('routine_daily').orderBy('time').snapshots(),
                  onAdd: () => _showSheet(
                    colName: 'routine_daily',
                    sheetTitle: 'Add Daily Activity',
                    fields: [
                      RoutineFieldDef('time', 'Time (e.g. 07:00 AM)', Icons.schedule),
                      RoutineFieldDef('activity', 'Activity', Icons.event_note),
                    ],
                  ),
                  onEdit: (d, id) => _showSheet(
                    colName: 'routine_daily',
                    sheetTitle: 'Edit Activity',
                    fields: [
                      RoutineFieldDef('time', 'Time (e.g. 07:00 AM)', Icons.schedule),
                      RoutineFieldDef('activity', 'Activity', Icons.event_note),
                    ],
                    existing: d,
                    docId: id,
                  ),
                  onDelete: (id) => _delete('routine_daily', id),
                ),
                ExerciseTab(
                  stream: _col('routine_exercise').orderBy('name').snapshots(),
                  onAdd: () => _showSheet(
                    colName: 'routine_exercise',
                    sheetTitle: 'Add Exercise',
                    fields: [
                      RoutineFieldDef('name', 'Exercise Name', Icons.fitness_center),
                      RoutineFieldDef('duration', 'Duration', Icons.timer),
                      RoutineFieldDef('frequency', 'Frequency', Icons.repeat),
                      RoutineFieldDef('benefits', 'Benefits', Icons.thumb_up),
                      RoutineFieldDef('instructions', 'Instructions', Icons.info_outline),
                    ],
                  ),
                  onEdit: (d, id) => _showSheet(
                    colName: 'routine_exercise',
                    sheetTitle: 'Edit Exercise',
                    fields: [
                      RoutineFieldDef('name', 'Exercise Name', Icons.fitness_center),
                      RoutineFieldDef('duration', 'Duration', Icons.timer),
                      RoutineFieldDef('frequency', 'Frequency', Icons.repeat),
                      RoutineFieldDef('benefits', 'Benefits', Icons.thumb_up),
                      RoutineFieldDef('instructions', 'Instructions', Icons.info_outline),
                    ],
                    existing: d,
                    docId: id,
                  ),
                  onDelete: (id) => _delete('routine_exercise', id),
                ),
                DietTab(
                  stream: _col('routine_diet').orderBy('time').snapshots(),
                  onAdd: () => _showSheet(
                    colName: 'routine_diet',
                    sheetTitle: 'Add Meal',
                    fields: [
                      RoutineFieldDef('meal', 'Meal Name (e.g. Breakfast)', Icons.restaurant),
                      RoutineFieldDef('time', 'Time (e.g. 8:00 AM)', Icons.schedule),
                      RoutineFieldDef('food', 'Food Items', Icons.fastfood),
                      RoutineFieldDef('notes', 'Notes / Restrictions', Icons.notes),
                    ],
                  ),
                  onEdit: (d, id) => _showSheet(
                    colName: 'routine_diet',
                    sheetTitle: 'Edit Meal',
                    fields: [
                      RoutineFieldDef('meal', 'Meal Name (e.g. Breakfast)', Icons.restaurant),
                      RoutineFieldDef('time', 'Time (e.g. 8:00 AM)', Icons.schedule),
                      RoutineFieldDef('food', 'Food Items', Icons.fastfood),
                      RoutineFieldDef('notes', 'Notes / Restrictions', Icons.notes),
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
      ),
    );
  }
}
