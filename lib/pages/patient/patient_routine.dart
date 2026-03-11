import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutterapp/data/gemini_service.dart';
import 'package:flutterapp/services/encryption_service.dart';
import 'package:flutterapp/widgets/routine_widgets.dart';

class PatientRoutine extends StatefulWidget {
  const PatientRoutine({super.key});

  @override
  State<PatientRoutine> createState() => _PatientRoutineState();
}

class _PatientRoutineState extends State<PatientRoutine>
    with TickerProviderStateMixin {
  late TabController _tabController;
  bool _generating = false;

  // Preferences state
  String _dietPref = 'Non-Vegetarian';
  String _fitnessLevel = 'Beginner';
  String _strengthComfort = 'None';
  String _goals = '';

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
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final uid = _user?.uid;
    if (uid == null) return;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      final data = doc.data();
      if (data == null || !mounted) return;
      setState(() {
        _dietPref = data['routinePrefDiet'] as String? ?? 'Non-Vegetarian';
        _fitnessLevel = data['routinePrefFitness'] as String? ?? 'Beginner';
        _strengthComfort = data['routinePrefStrength'] as String? ?? 'None';
        _goals = data['routinePrefGoals'] as String? ?? '';
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ─── AI plan generation ────────────────────────────────────────────────────
  Future<void> _generateWithAI() async {
    final uid = _user?.uid;
    if (uid == null) return;

    setState(() => _generating = true);

    try {
      final db = FirebaseFirestore.instance;
      final userDoc = await db.collection('users').doc(uid).get();
      final userData = userDoc.data() ?? {};
      final privacyOn = userData['privacyModeEnabled'] == true;

      // Build profile
      final profile = <String, dynamic>{
        'age': userData['age'],
        'gender': userData['gender'],
        'weight': userData['weight'],
        'height': userData['height'],
        'bloodGroup': userData['bloodGroup'],
      };

      // Chronic conditions (decrypt if needed)
      List<String> chronic =
          List<String>.from(userData['chronicConditions'] as List? ?? []);
      if (privacyOn && chronic.isNotEmpty) {
        chronic = await EncryptionService.decryptList(uid, chronic);
      }

      // Fetch allergies subcollection
      final allergySnap =
          await db.collection('users').doc(uid).collection('allergies').get();
      final allergies = <Map<String, dynamic>>[];
      for (final doc in allergySnap.docs) {
        var data = doc.data();
        if (privacyOn) data = await EncryptionService.decryptMap(uid, data);
        allergies.add(data);
      }

      // Fetch medications subcollection
      final medSnap =
          await db.collection('users').doc(uid).collection('medications').get();
      final medications = <Map<String, dynamic>>[];
      for (final doc in medSnap.docs) {
        var data = doc.data();
        if (privacyOn) data = await EncryptionService.decryptMap(uid, data);
        medications.add(data);
      }

      // Medical history from linked patients doc
      String medicalHistory = '';
      final linkedId = userData['linkedPatientId'] as String?;
      if (linkedId != null && linkedId.isNotEmpty) {
        final patDoc = await db.collection('patients').doc(linkedId).get();
        if (patDoc.exists) {
          medicalHistory = patDoc.data()?['medical history'] as String? ?? '';
        }
      }

      final healthContext = <String, dynamic>{
        'profile': profile,
        'allergies': allergies,
        'medications': medications,
        'chronicConditions': chronic,
        'medicalHistory': medicalHistory,
        'preferences': {
          'dietPreference': _dietPref,
          'fitnessLevel': _fitnessLevel,
          'strengthTrainingComfort': _strengthComfort,
          'goals': _goals,
        },
      };

      // Call Gemini
      final rawResponse =
          await GeminiService().generatePersonalizedPlan(healthContext: healthContext);

      // Strip markdown code fences if present
      String jsonStr = rawResponse.trim();
      if (jsonStr.startsWith('```')) {
        jsonStr = jsonStr.replaceFirst(RegExp(r'^```\w*\n?'), '');
        jsonStr = jsonStr.replaceFirst(RegExp(r'\n?```$'), '');
        jsonStr = jsonStr.trim();
      }

      final parsed = jsonDecode(jsonStr) as Map<String, dynamic>;

      // Save to Firestore — clear old AI-generated entries first, then write new ones
      final batch = db.batch();

      // Daily
      final dailyList = (parsed['daily'] as List?) ?? [];
      final oldDaily = await _col('routine_daily').get();
      for (final doc in oldDaily.docs) {
        batch.delete(doc.reference);
      }
      for (final item in dailyList) {
        batch.set(_col('routine_daily').doc(), Map<String, dynamic>.from(item as Map));
      }

      // Exercise
      final exerciseList = (parsed['exercise'] as List?) ?? [];
      final oldExercise = await _col('routine_exercise').get();
      for (final doc in oldExercise.docs) {
        batch.delete(doc.reference);
      }
      for (final item in exerciseList) {
        batch.set(
            _col('routine_exercise').doc(), Map<String, dynamic>.from(item as Map));
      }

      // Diet
      final dietList = (parsed['diet'] as List?) ?? [];
      final oldDiet = await _col('routine_diet').get();
      for (final doc in oldDiet.docs) {
        batch.delete(doc.reference);
      }
      for (final item in dietList) {
        batch.set(_col('routine_diet').doc(), Map<String, dynamic>.from(item as Map));
      }

      await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Personalized plan generated successfully!'),
            backgroundColor: Color(0xFF6C5CE7),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to generate plan: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  void _confirmGenerate() {
    // Local copies for the sheet so setState inside the sheet works
    String diet = _dietPref;
    String fitness = _fitnessLevel;
    String strength = _strengthComfort;
    final goalsCtrl = TextEditingController(text: _goals);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return RoutineBottomSheet(
              title: 'Generate AI Plan',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Set your preferences to personalize the routine, exercise and diet plan.',
                    style: TextStyle(fontSize: 13, color: Colors.black54),
                  ),
                  const SizedBox(height: 16),
                  _prefDropdown(
                    label: 'Diet Preference',
                    icon: Icons.restaurant,
                    value: diet,
                    items: const [
                      'Vegetarian',
                      'Non-Vegetarian',
                      'Vegan',
                      'Eggetarian',
                    ],
                    onChanged: (v) => setSheetState(() => diet = v!),
                  ),
                  const SizedBox(height: 12),
                  _prefDropdown(
                    label: 'Fitness Level',
                    icon: Icons.fitness_center,
                    value: fitness,
                    items: const ['Beginner', 'Intermediate', 'Advanced'],
                    onChanged: (v) => setSheetState(() => fitness = v!),
                  ),
                  const SizedBox(height: 12),
                  _prefDropdown(
                    label: 'Strength Training',
                    icon: Icons.sports_gymnastics,
                    value: strength,
                    items: const ['None', 'Light', 'Moderate', 'Heavy'],
                    onChanged: (v) => setSheetState(() => strength = v!),
                  ),
                  const SizedBox(height: 12),
                  routineTextField(goalsCtrl, 'Goals (e.g. weight loss, better sleep)',
                      Icons.flag),
                  const SizedBox(height: 8),
                  const Text(
                    'Existing routine entries will be replaced.',
                    style: TextStyle(fontSize: 12, color: Colors.red),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.auto_awesome,
                          color: Colors.white, size: 18),
                      label: const Text('Generate',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6C5CE7),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () async {
                        // Save preferences
                        setState(() {
                          _dietPref = diet;
                          _fitnessLevel = fitness;
                          _strengthComfort = strength;
                          _goals = goalsCtrl.text.trim();
                        });
                        final uid = _user?.uid;
                        if (uid != null) {
                          FirebaseFirestore.instance
                              .collection('users')
                              .doc(uid)
                              .update({
                            'routinePrefDiet': diet,
                            'routinePrefFitness': fitness,
                            'routinePrefStrength': strength,
                            'routinePrefGoals': goalsCtrl.text.trim(),
                          });
                        }
                        if (sheetCtx.mounted) Navigator.pop(sheetCtx);
                        _generateWithAI();
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _prefDropdown({
    required String label,
    required IconData icon,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: value,
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
      items: items
          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
          .toList(),
      onChanged: onChanged,
    );
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text('Daily Routine',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold)),
                  ),
                  _generating
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : IconButton(
                          onPressed: _confirmGenerate,
                          icon: const Icon(Icons.auto_awesome,
                              color: Colors.white),
                          tooltip: 'Generate with AI',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                  "Follow your doctor's recommended daily routine",
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
                stream:
                    _col('routine_exercise').orderBy('name').snapshots(),
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
    );
  }
}

