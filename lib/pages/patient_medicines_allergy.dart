import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class PatientMedicinesAllergy extends StatefulWidget {
  const PatientMedicinesAllergy({super.key});

  @override
  State<PatientMedicinesAllergy> createState() =>
      _PatientMedicinesAllergyState();
}

class _PatientMedicinesAllergyState extends State<PatientMedicinesAllergy> {
  User? get _user => FirebaseAuth.instance.currentUser;

  CollectionReference get _allergiesRef => FirebaseFirestore.instance
      .collection('users')
      .doc(_user!.uid)
      .collection('allergies');

  CollectionReference get _medicationsRef => FirebaseFirestore.instance
      .collection('users')
      .doc(_user!.uid)
      .collection('medications');

  // ─── Severity helpers ────────────────────────────────────────────────────
  static Color _severityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      default:
        return Colors.yellow[700]!;
    }
  }

  // ─── Allergy bottom sheet ─────────────────────────────────────────────────
  void _showAllergySheet({Map<String, dynamic>? existing, String? docId}) {
    final allergenC =
        TextEditingController(text: existing?['allergen'] ?? '');
    final descC =
        TextEditingController(text: existing?['description'] ?? '');
    String severity = existing?['severity'] ?? 'Medium';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSheet) => _BottomSheet(
          title: docId == null ? 'Add Allergy' : 'Edit Allergy',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _field(allergenC, 'Allergen', Icons.warning_amber),
              const SizedBox(height: 14),
              _field(descC, 'Description', Icons.description),
              const SizedBox(height: 14),
              const Text('Severity',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Row(
                children: ['Low', 'Medium', 'High'].map((s) {
                  final selected = severity == s;
                  return Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: ChoiceChip(
                      label: Text(s,
                          style: TextStyle(
                              color:
                                  selected ? Colors.white : Colors.black87)),
                      selected: selected,
                      selectedColor: _severityColor(s),
                      onSelected: (_) => setSheet(() => severity = s),
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
                    if (allergenC.text.trim().isEmpty) return;
                    final data = {
                      'allergen': allergenC.text.trim(),
                      'description': descC.text.trim(),
                      'severity': severity,
                    };
                    if (docId == null) {
                      await _allergiesRef.add(data);
                    } else {
                      await _allergiesRef.doc(docId).update(data);
                    }
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  child: Text(docId == null ? 'Add Allergy' : 'Save Changes',
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

  // ─── Medication bottom sheet ──────────────────────────────────────────────
  void _showMedicationSheet({Map<String, dynamic>? existing, String? docId}) {
    final nameC = TextEditingController(text: existing?['name'] ?? '');
    final dosageC = TextEditingController(text: existing?['dosage'] ?? '');
    final freqC = TextEditingController(text: existing?['frequency'] ?? '');
    final purposeC = TextEditingController(text: existing?['purpose'] ?? '');
    final startC = TextEditingController(text: existing?['startDate'] ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => _BottomSheet(
        title: docId == null ? 'Add Medication' : 'Edit Medication',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _field(nameC, 'Medicine Name', Icons.medication),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(child: _field(dosageC, 'Dosage (e.g. 10mg)', Icons.scale)),
                const SizedBox(width: 12),
                Expanded(child: _field(freqC, 'Frequency', Icons.repeat)),
              ],
            ),
            const SizedBox(height: 14),
            _field(purposeC, 'Purpose', Icons.info_outline),
            const SizedBox(height: 14),
            _field(startC, 'Start Date (YYYY-MM-DD)', Icons.calendar_today),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[600],
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () async {
                  if (nameC.text.trim().isEmpty) return;
                  final data = {
                    'name': nameC.text.trim(),
                    'dosage': dosageC.text.trim(),
                    'frequency': freqC.text.trim(),
                    'purpose': purposeC.text.trim(),
                    'startDate': startC.text.trim(),
                  };
                  if (docId == null) {
                    await _medicationsRef.add(data);
                  } else {
                    await _medicationsRef.doc(docId).update(data);
                  }
                  if (sheetCtx.mounted) Navigator.pop(sheetCtx);
                },
                child: Text(
                    docId == null ? 'Add Medication' : 'Save Changes',
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Delete helpers ───────────────────────────────────────────────────────
  Future<void> _deleteAllergy(String docId) async {
    final confirmed = await _confirmDelete(context, 'allergy');
    if (confirmed) await _allergiesRef.doc(docId).delete();
  }

  Future<void> _deleteMedication(String docId) async {
    final confirmed = await _confirmDelete(context, 'medication');
    if (confirmed) await _medicationsRef.doc(docId).delete();
  }

  Future<bool> _confirmDelete(BuildContext ctx, String label) async {
    return await showDialog<bool>(
          context: ctx,
          builder: (_) => AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('Confirm Delete'),
            content: Text('Remove this $label?'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancel')),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Delete',
                    style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ) ??
        false;
  }

  // ─── Build ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
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
                  'Medicines & Allergies',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  'Manage your medication info and allergy warnings',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),

          // ── Allergies section ─────────────────────────────────────────────
          _SectionCard(
            icon: Icons.warning,
            iconColor: Colors.red[600]!,
            title: 'My Allergies',
            subtitle: 'Substances you are allergic to',
            onAdd: () => _showAllergySheet(),
            addLabel: 'Add Allergy',
            addColor: Colors.red,
            child: StreamBuilder<QuerySnapshot>(
              stream: _allergiesRef
                  .orderBy('allergen')
                  .snapshots(),
              builder: (_, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Center(
                        child: CircularProgressIndicator(
                            color: Color(0xFF6C5CE7))),
                  );
                }
                final docs = snap.data?.docs ?? [];
                if (docs.isEmpty) {
                  return _emptyState(
                      'No allergies recorded', Icons.check_circle_outline);
                }
                return Column(
                  children: docs.map((doc) {
                    final d = doc.data() as Map<String, dynamic>;
                    return _AllergyCard(
                      allergen: d['allergen'] ?? '',
                      description: d['description'] ?? '',
                      severity: d['severity'] ?? 'Low',
                      onEdit: () => _showAllergySheet(existing: d, docId: doc.id),
                      onDelete: () => _deleteAllergy(doc.id),
                    );
                  }).toList(),
                );
              },
            ),
          ),

          const SizedBox(height: 20),

          // ── Medications section ───────────────────────────────────────────
          _SectionCard(
            icon: Icons.medication,
            iconColor: Colors.green[600]!,
            title: 'Current Medications',
            subtitle: 'Medicines you are currently taking',
            onAdd: () => _showMedicationSheet(),
            addLabel: 'Add Medication',
            addColor: Colors.green[600]!,
            child: StreamBuilder<QuerySnapshot>(
              stream: _medicationsRef
                  .orderBy('name')
                  .snapshots(),
              builder: (_, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Center(
                        child: CircularProgressIndicator(
                            color: Color(0xFF6C5CE7))),
                  );
                }
                final docs = snap.data?.docs ?? [];
                if (docs.isEmpty) {
                  return _emptyState(
                      'No medications recorded', Icons.medication_liquid);
                }
                return Column(
                  children: docs.map((doc) {
                    final d = doc.data() as Map<String, dynamic>;
                    return _MedicationCard(
                      name: d['name'] ?? '',
                      dosage: d['dosage'] ?? '',
                      frequency: d['frequency'] ?? '',
                      purpose: d['purpose'] ?? '',
                      startDate: d['startDate'] ?? '',
                      onEdit: () =>
                          _showMedicationSheet(existing: d, docId: doc.id),
                      onDelete: () => _deleteMedication(doc.id),
                    );
                  }).toList(),
                );
              },
            ),
          ),

          // Important notice
          Container(
            margin: const EdgeInsets.fromLTRB(20, 20, 20, 30),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.red[50],
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.red[200]!),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, color: Colors.red[600]),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Always inform your doctor about your allergies before taking any new medication. Keep this information up to date.',
                    style: TextStyle(color: Colors.red[700], fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState(String message, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Column(
          children: [
            Icon(icon, color: Colors.grey[400], size: 40),
            const SizedBox(height: 10),
            Text(message,
                style:
                    TextStyle(color: Colors.grey[500], fontSize: 14)),
          ],
        ),
      ),
    );
  }
}

// ─── Section card wrapper ─────────────────────────────────────────────────────
class _SectionCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onAdd;
  final String addLabel;
  final Color addColor;
  final Widget child;

  const _SectionCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onAdd,
    required this.addLabel,
    required this.addColor,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
          Row(
            children: [
              Icon(icon, color: iconColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF6C5CE7)),
                ),
              ),
              TextButton.icon(
                onPressed: onAdd,
                icon: Icon(Icons.add, size: 18, color: addColor),
                label: Text(addLabel,
                    style: TextStyle(
                        color: addColor, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          Text(subtitle,
              style: TextStyle(color: Colors.grey[600], fontSize: 13)),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

// ─── Allergy card ─────────────────────────────────────────────────────────────
class _AllergyCard extends StatelessWidget {
  final String allergen;
  final String description;
  final String severity;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _AllergyCard({
    required this.allergen,
    required this.description,
    required this.severity,
    required this.onEdit,
    required this.onDelete,
  });

  static Color _sColor(String s) {
    switch (s.toLowerCase()) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      default:
        return Colors.yellow[700]!;
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = _sColor(severity);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_amber, color: Colors.red[600], size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(allergen,
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: Colors.red[700])),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                          color: c, borderRadius: BorderRadius.circular(10)),
                      child: Text(severity,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                if (description.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(description,
                      style: TextStyle(
                          color: Colors.red[600], fontSize: 13)),
                ],
              ],
            ),
          ),
          const SizedBox(width: 6),
          IconButton(
            icon: const Icon(Icons.edit, size: 18, color: Color(0xFF6C5CE7)),
            onPressed: onEdit,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: Icon(Icons.delete, size: 18, color: Colors.red[400]),
            onPressed: onDelete,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}

// ─── Medication card ──────────────────────────────────────────────────────────
class _MedicationCard extends StatelessWidget {
  final String name;
  final String dosage;
  final String frequency;
  final String purpose;
  final String startDate;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _MedicationCard({
    required this.name,
    required this.dosage,
    required this.frequency,
    required this.purpose,
    required this.startDate,
    required this.onEdit,
    required this.onDelete,
  });

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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.medication, color: Colors.green[600], size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Colors.green[700])),
                const SizedBox(height: 6),
                if (dosage.isNotEmpty || frequency.isNotEmpty)
                  Text('${dosage.isNotEmpty ? dosage : '—'}  •  ${frequency.isNotEmpty ? frequency : '—'}',
                      style: const TextStyle(fontSize: 13)),
                if (purpose.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text('Purpose: $purpose',
                      style: TextStyle(
                          fontSize: 13, color: Colors.grey[700])),
                ],
                if (startDate.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text('Started: $startDate',
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey[500])),
                ],
              ],
            ),
          ),
          const SizedBox(width: 6),
          IconButton(
            icon: const Icon(Icons.edit, size: 18, color: Color(0xFF6C5CE7)),
            onPressed: onEdit,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: Icon(Icons.delete, size: 18, color: Colors.red[400]),
            onPressed: onDelete,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
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
