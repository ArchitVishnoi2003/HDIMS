import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

const _kPrimary = Color(0xFF6C5CE7);
const _kBg = Color(0xFFF8F9FA);

class PatientPersonalDetails extends StatefulWidget {
  final String? linkedPatientId;
  const PatientPersonalDetails({super.key, this.linkedPatientId});

  @override
  State<PatientPersonalDetails> createState() =>
      _PatientPersonalDetailsState();
}

class _PatientPersonalDetailsState extends State<PatientPersonalDetails> {
  final _nameC = TextEditingController();
  final _ageC = TextEditingController();
  final _genderC = TextEditingController();
  final _phoneC = TextEditingController();
  final _addressC = TextEditingController();
  final _weightC = TextEditingController();
  final _heightC = TextEditingController();
  final _bloodC = TextEditingController();
  final _emergPhoneC = TextEditingController();
  final _emergRelC = TextEditingController();
  final _emergAddrC = TextEditingController();
  final _insProvC = TextEditingController();
  final _insPolicyC = TextEditingController();
  final _insCoverC = TextEditingController();
  final _insValidC = TextEditingController();

  List<String> _chronicConditions = [];
  bool _isEditing = false;
  bool _isSaving = false;
  String? _email;
  String? _lastUpdated;

  User? get _user => FirebaseAuth.instance.currentUser;

  CollectionReference get _allergiesRef => FirebaseFirestore.instance
      .collection('users')
      .doc(_user!.uid)
      .collection('allergies');

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (_user == null) return;
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(_user!.uid)
        .get();
    if (!doc.exists || !mounted) return;
    final d = doc.data()!;
    setState(() {
      _email = d['email'] as String? ?? _user!.email ?? '';
      _nameC.text = d['name'] as String? ?? '';
      _ageC.text = (d['age'] ?? '').toString();
      _genderC.text = d['gender'] as String? ?? '';
      _phoneC.text = d['phone'] as String? ?? '';
      _addressC.text = d['address'] as String? ?? '';
      _weightC.text = d['weight'] as String? ?? '';
      _heightC.text = d['height'] as String? ?? '';
      _bloodC.text = d['bloodGroup'] as String? ?? '';
      _emergPhoneC.text = d['emergencyPhone'] as String? ?? '';
      _emergRelC.text = d['emergencyRelationship'] as String? ?? '';
      _emergAddrC.text = d['emergencyAddress'] as String? ?? '';
      _insProvC.text = d['insuranceProvider'] as String? ?? '';
      _insPolicyC.text = d['policyNumber'] as String? ?? '';
      _insCoverC.text = d['coverageType'] as String? ?? '';
      _insValidC.text = d['validUntil'] as String? ?? '';
      _chronicConditions =
          List<String>.from(d['chronicConditions'] as List? ?? []);
      final ts = d['updatedAt'] as Timestamp?;
      if (ts != null) {
        final dt = ts.toDate();
        _lastUpdated =
            '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
      }
    });
  }

  Future<void> _saveData() async {
    if (_user == null) return;
    setState(() => _isSaving = true);
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_user!.uid)
          .update({
        'name': _nameC.text.trim(),
        'age': _ageC.text.trim(),
        'gender': _genderC.text.trim(),
        'phone': _phoneC.text.trim(),
        'address': _addressC.text.trim(),
        'weight': _weightC.text.trim(),
        'height': _heightC.text.trim(),
        'bloodGroup': _bloodC.text.trim(),
        'emergencyPhone': _emergPhoneC.text.trim(),
        'emergencyRelationship': _emergRelC.text.trim(),
        'emergencyAddress': _emergAddrC.text.trim(),
        'insuranceProvider': _insProvC.text.trim(),
        'policyNumber': _insPolicyC.text.trim(),
        'coverageType': _insCoverC.text.trim(),
        'validUntil': _insValidC.text.trim(),
        'chronicConditions': _chronicConditions,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      final now = DateTime.now();
      setState(() {
        _isEditing = false;
        _lastUpdated =
            '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Details updated successfully!')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error saving: $e')));
      }
    }
    setState(() => _isSaving = false);
  }

  // ── Allergy CRUD ──────────────────────────────────────────────────────────

  void _showAddAllergySheet({Map<String, dynamic>? existing, String? docId}) {
    final allergenC =
        TextEditingController(text: existing?['allergen'] as String? ?? '');
    final descC =
        TextEditingController(text: existing?['description'] as String? ?? '');
    String severity = existing?['severity'] as String? ?? 'High';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => _BottomForm(
          title: existing == null ? 'Add Allergy' : 'Edit Allergy',
          onSave: () async {
            if (allergenC.text.trim().isEmpty) return;
            final data = <String, dynamic>{
              'allergen': allergenC.text.trim(),
              'description': descC.text.trim(),
              'severity': severity,
            };
            if (existing == null) {
              data['createdAt'] = FieldValue.serverTimestamp();
              await _allergiesRef.add(data);
            } else {
              await _allergiesRef.doc(docId).update(data);
            }
            if (ctx.mounted) Navigator.pop(ctx);
          },
          children: [
            _formField(allergenC, 'Allergen (e.g. Penicillin)',
                Icons.warning_amber_rounded),
            const SizedBox(height: 16),
            _formField(descC, 'Description (e.g. Antibiotic allergy)',
                Icons.notes),
            const SizedBox(height: 16),
            const Text('Severity',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87)),
            const SizedBox(height: 8),
            Row(
              children: ['High', 'Medium', 'Low'].map((s) {
                final sel = severity == s;
                final color = s == 'High'
                    ? Colors.red
                    : s == 'Medium'
                        ? Colors.orange
                        : Colors.green;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setSheet(() => severity = s),
                    child: Container(
                      margin: EdgeInsets.only(
                          right: s != 'Low' ? 8 : 0),
                      padding:
                          const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: sel ? color : Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color:
                                sel ? color : Colors.grey[300]!),
                      ),
                      child: Text(s,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: sel ? Colors.white : color,
                              fontWeight: FontWeight.bold)),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteAllergy(String docId) async =>
      _allergiesRef.doc(docId).delete();

  // ── Chronic conditions ────────────────────────────────────────────────────

  void _addChronicConditionDialog() {
    final c = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Chronic Condition'),
        content: _formField(
            c, 'e.g. Hypertension', Icons.medical_services),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (c.text.trim().isNotEmpty) {
                setState(
                    () => _chronicConditions.add(c.text.trim()));
              }
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: _kPrimary),
            child: const Text('Add',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      floatingActionButton: !_isEditing
          ? FloatingActionButton.extended(
              onPressed: () => setState(() => _isEditing = true),
              backgroundColor: _kPrimary,
              icon: const Icon(Icons.edit, color: Colors.white),
              label: const Text('Edit',
                  style: TextStyle(color: Colors.white)),
            )
          : null,
      body: SingleChildScrollView(
        child: Column(
          children: [
            _header(),
            const SizedBox(height: 16),
            _section('Basic Information', [
              _field('Full Name', _nameC, Icons.person),
              _field('Age', _ageC, Icons.cake,
                  keyboard: TextInputType.number),
              _field('Gender', _genderC, Icons.wc),
              _field('Phone', _phoneC, Icons.phone,
                  keyboard: TextInputType.phone),
              _field('Email', null, Icons.email,
                  staticValue: _email ?? ''),
              _field('Address', _addressC, Icons.location_on,
                  maxLines: 2),
              _field('Weight', _weightC, Icons.monitor_weight,
                  hint: 'e.g. 70 kg'),
              _field('Height', _heightC, Icons.height,
                  hint: 'e.g. 175 cm'),
              _field('Blood Group', _bloodC, Icons.bloodtype),
            ]),
            const SizedBox(height: 16),
            _allergiesSection(),
            const SizedBox(height: 16),
            _chronicSection(),
            const SizedBox(height: 16),
            _section('Emergency Contact', [
              _field('Phone', _emergPhoneC, Icons.phone,
                  keyboard: TextInputType.phone),
              _field('Relationship', _emergRelC, Icons.people),
              _field('Address', _emergAddrC, Icons.location_on,
                  maxLines: 2),
            ]),
            const SizedBox(height: 16),
            _section('Insurance Information', [
              _field('Provider', _insProvC, Icons.business),
              _field('Policy Number', _insPolicyC, Icons.badge),
              _field('Coverage Type', _insCoverC, Icons.shield),
              _field('Valid Until', _insValidC,
                  Icons.calendar_today),
            ]),
            if (_isEditing) ...[
              const SizedBox(height: 24),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _saveData,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _kPrimary,
                          padding: const EdgeInsets.symmetric(
                              vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(15)),
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white),
                              )
                            : const Text('Save Changes',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          setState(() => _isEditing = false);
                          _loadData();
                        },
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: _kPrimary),
                          padding: const EdgeInsets.symmetric(
                              vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(15)),
                        ),
                        child: const Text('Cancel',
                            style: TextStyle(
                                color: _kPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: 16)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            // Doctor's record section (read-only)
            if (widget.linkedPatientId != null) ...[
              const SizedBox(height: 16),
              _doctorRecordSection(),
            ],
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // ── Doctor record section ─────────────────────────────────────────────────

  Widget _doctorRecordSection() {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('patients')
          .doc(widget.linkedPatientId)
          .snapshots(),
      builder: (_, snap) {
        if (!snap.hasData || !snap.data!.exists) return const SizedBox.shrink();
        final dr = snap.data!.data() as Map<String, dynamic>;

        Widget row(IconData icon, String label, String? value) {
          if (value == null || value.isEmpty) return const SizedBox.shrink();
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, size: 16, color: _kPrimary),
                const SizedBox(width: 8),
                SizedBox(
                  width: 140,
                  child: Text('$label:',
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87)),
                ),
                Expanded(
                  child: Text(value,
                      style: const TextStyle(
                          fontSize: 13, color: Colors.black54)),
                ),
              ],
            ),
          );
        }

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _kPrimary.withValues(alpha: 0.25)),
            boxShadow: [
              BoxShadow(
                color: _kPrimary.withValues(alpha: 0.06),
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
                    color: _kPrimary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.local_hospital,
                      color: Colors.white, size: 18),
                ),
                const SizedBox(width: 10),
                const Text(
                  'Provided by Your Doctor',
                  style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: _kPrimary),
                ),
              ]),
              const SizedBox(height: 4),
              Text('Read-only — updated by your doctor',
                  style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[500],
                      fontStyle: FontStyle.italic)),
              const SizedBox(height: 14),
              row(Icons.medical_services, 'Medical History',
                  dr['medical history'] as String?),
              row(Icons.vaccines, 'Vaccination',
                  dr['vaccination'] as String?),
              row(Icons.medication, 'Current Medications',
                  dr['current medication'] as String?),
              row(Icons.family_restroom, 'Family History',
                  dr['family history'] as String?),
              row(Icons.warning_amber, 'Allergies (Doctor)',
                  dr['allergies'] as String?),
              row(Icons.bloodtype, 'Blood Group', dr['blood'] as String?),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _importDoctorData(dr),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.download_rounded,
                      color: Colors.white, size: 18),
                  label: const Text('Import to My Records',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Existing fields are kept. Only empty fields will be filled. '
                'Allergies & medications are merged, not duplicated.',
                style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[500],
                    fontStyle: FontStyle.italic),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _importDoctorData(Map<String, dynamic> dr) async {
    if (_user == null) return;

    // ── 1. Scalar fields: copy only if currently empty ────────────────────
    final userSnap = await FirebaseFirestore.instance
        .collection('users')
        .doc(_user!.uid)
        .get();
    final cur = userSnap.data() ?? {};

    final updates = <String, dynamic>{};
    void copyIfEmpty(String userField, dynamic doctorValue) {
      final existing = cur[userField];
      if ((existing == null || existing.toString().isEmpty) &&
          doctorValue != null &&
          doctorValue.toString().isNotEmpty) {
        updates[userField] = doctorValue;
      }
    }

    copyIfEmpty('bloodGroup', dr['blood']);
    copyIfEmpty('age', dr['age']);
    copyIfEmpty('gender', dr['gender']);
    copyIfEmpty('phone', dr['phone']);
    copyIfEmpty('address', dr['address']);

    if (updates.isNotEmpty) {
      updates['updatedAt'] = FieldValue.serverTimestamp();
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_user!.uid)
          .update(updates);
    }

    // ── 2. Allergies text → allergies subcollection (upsert by fromDoctor) ─
    final allergiesText = (dr['allergies'] as String? ?? '').trim();
    if (allergiesText.isNotEmpty) {
      final existing = await _allergiesRef
          .where('fromDoctor', isEqualTo: true)
          .limit(1)
          .get();
      final allergyData = {
        'allergen': 'Doctor-provided allergies',
        'description': allergiesText,
        'severity': 'Unknown',
        'fromDoctor': true,
      };
      if (existing.docs.isNotEmpty) {
        await existing.docs.first.reference.update(allergyData);
      } else {
        await _allergiesRef.add(allergyData);
      }
    }

    // ── 3. Medications text → medications subcollection (upsert by fromDoctor)
    final medsText = (dr['current medication'] as String? ?? '').trim();
    if (medsText.isNotEmpty) {
      final medsRef = FirebaseFirestore.instance
          .collection('users')
          .doc(_user!.uid)
          .collection('medications');
      final existing = await medsRef
          .where('fromDoctor', isEqualTo: true)
          .limit(1)
          .get();
      final medData = {
        'name': 'Doctor-prescribed medications',
        'dosage': '',
        'frequency': '',
        'purpose': medsText,
        'fromDoctor': true,
      };
      if (existing.docs.isNotEmpty) {
        await existing.docs.first.reference.update(medData);
      } else {
        await medsRef.add(medData);
      }
    }

    // ── Reload & notify ───────────────────────────────────────────────────
    await _loadData();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Doctor's data imported to your records!"),
          backgroundColor: Color(0xFF6C5CE7),
        ),
      );
    }
  }

  // ── Widgets ───────────────────────────────────────────────────────────────

  Widget _header() => Container(
        width: double.infinity,
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.all(25),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [_kPrimary, Color(0xFF74B9FF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
                color: _kPrimary.withValues(alpha: 0.3),
                blurRadius: 15,
                offset: const Offset(0, 8)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Personal Details',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              _lastUpdated != null
                  ? 'Last updated: $_lastUpdated'
                  : _isEditing
                      ? 'Editing — tap Save to apply'
                      : 'Tap Edit to update your information',
              style: const TextStyle(
                  color: Colors.white70, fontSize: 14),
            ),
          ],
        ),
      );

  Widget _section(String title, List<Widget> children) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.all(20),
        decoration: _cardDeco(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [_sectionTitle(title), ...children],
        ),
      );

  Widget _field(
    String label,
    TextEditingController? controller,
    IconData icon, {
    String? staticValue,
    String? hint,
    int maxLines = 1,
    TextInputType keyboard = TextInputType.text,
  }) {
    if (!_isEditing || controller == null) {
      final val = controller?.text.isNotEmpty == true
          ? controller!.text
          : (staticValue ?? '');
      return _readRow(label, val.isNotEmpty ? val : '—');
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboard,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          labelStyle: const TextStyle(color: _kPrimary),
          prefixIcon: Icon(icon, color: _kPrimary),
          filled: true,
          fillColor: _kBg,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: _kPrimary, width: 2)),
        ),
      ),
    );
  }

  Widget _readRow(String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 130,
              child: Text('$label:',
                  style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                      fontSize: 14)),
            ),
            Expanded(
              child: Text(value,
                  style: const TextStyle(
                      fontSize: 14, color: Colors.black54)),
            ),
          ],
        ),
      );

  Widget _allergiesSection() => Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.all(20),
        decoration: _cardDeco(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: _sectionTitle('Allergies')),
                if (_isEditing)
                  TextButton.icon(
                    onPressed: () => _showAddAllergySheet(),
                    icon: const Icon(Icons.add,
                        color: _kPrimary, size: 18),
                    label: const Text('Add',
                        style: TextStyle(color: _kPrimary)),
                  ),
              ],
            ),
            StreamBuilder<QuerySnapshot>(
              stream:
                  _allergiesRef.orderBy('allergen').snapshots(),
              builder: (ctx, snap) {
                if (snap.connectionState ==
                    ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(12),
                    child: Center(
                        child: CircularProgressIndicator(
                            color: _kPrimary, strokeWidth: 2)),
                  );
                }
                final docs = snap.data?.docs ?? [];
                if (docs.isEmpty) {
                  return _emptyHint(_isEditing
                      ? 'Tap + Add to record allergies'
                      : 'No allergies recorded');
                }
                return Column(
                  children: docs.map((doc) {
                    final d =
                        doc.data() as Map<String, dynamic>;
                    final sev =
                        d['severity'] as String? ?? 'High';
                    final col = sev == 'High'
                        ? Colors.red
                        : sev == 'Medium'
                            ? Colors.orange
                            : Colors.green;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: col.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: col.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.warning_amber_rounded,
                              color: col, size: 18),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                    d['allergen'] as String? ??
                                        '',
                                    style: TextStyle(
                                        fontWeight:
                                            FontWeight.bold,
                                        color: col,
                                        fontSize: 14)),
                                if ((d['description']
                                            as String?)
                                        ?.isNotEmpty ==
                                    true)
                                  Text(
                                      d['description']
                                          as String,
                                      style: TextStyle(
                                          color: col,
                                          fontSize: 12)),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                                color: col,
                                borderRadius:
                                    BorderRadius.circular(8)),
                            child: Text(sev,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight:
                                        FontWeight.bold)),
                          ),
                          if (_isEditing) ...[
                            const SizedBox(width: 4),
                            IconButton(
                              icon: Icon(Icons.edit,
                                  color: col, size: 18),
                              padding: EdgeInsets.zero,
                              constraints:
                                  const BoxConstraints(),
                              onPressed: () =>
                                  _showAddAllergySheet(
                                      existing: d,
                                      docId: doc.id),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close,
                                  color: Colors.red, size: 18),
                              padding: EdgeInsets.zero,
                              constraints:
                                  const BoxConstraints(),
                              onPressed: () =>
                                  _deleteAllergy(doc.id),
                            ),
                          ],
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

  Widget _chronicSection() => Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.all(20),
        decoration: _cardDeco(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                    child: _sectionTitle('Chronic Conditions')),
                if (_isEditing)
                  TextButton.icon(
                    onPressed: _addChronicConditionDialog,
                    icon: const Icon(Icons.add,
                        color: _kPrimary, size: 18),
                    label: const Text('Add',
                        style: TextStyle(color: _kPrimary)),
                  ),
              ],
            ),
            if (_chronicConditions.isEmpty)
              _emptyHint(_isEditing
                  ? 'Tap + Add to record conditions'
                  : 'No chronic conditions recorded'),
            ..._chronicConditions.asMap().entries.map((e) =>
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: Colors.orange
                            .withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.medical_services,
                          color: Colors.orange, size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(e.value,
                            style: const TextStyle(
                                color: Colors.orange,
                                fontWeight: FontWeight.w500,
                                fontSize: 14)),
                      ),
                      if (_isEditing)
                        IconButton(
                          icon: const Icon(Icons.close,
                              color: Colors.red, size: 18),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () => setState(() =>
                              _chronicConditions
                                  .removeAt(e.key)),
                        ),
                    ],
                  ),
                )),
          ],
        ),
      );

  BoxDecoration _cardDeco() => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.07),
              blurRadius: 15,
              offset: const Offset(0, 5)),
        ],
      );

  Widget _sectionTitle(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Text(t,
            style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: _kPrimary)),
      );

  Widget _emptyHint(String t) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(t,
            style:
                const TextStyle(color: Colors.grey, fontSize: 13)),
      );

  @override
  void dispose() {
    for (final c in [
      _nameC, _ageC, _genderC, _phoneC, _addressC,
      _weightC, _heightC, _bloodC,
      _emergPhoneC, _emergRelC, _emergAddrC,
      _insProvC, _insPolicyC, _insCoverC, _insValidC,
    ]) { c.dispose(); }
    super.dispose();
  }
}

// ── Reusable form helpers ─────────────────────────────────────────────────────

Widget _formField(TextEditingController c, String hint, IconData icon,
    {int maxLines = 1, TextInputType keyboard = TextInputType.text}) =>
    TextField(
      controller: c,
      maxLines: maxLines,
      keyboardType: keyboard,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: _kPrimary),
        filled: true,
        fillColor: _kBg,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _kPrimary, width: 2)),
      ),
    );

class _BottomForm extends StatelessWidget {
  final String title;
  final Future<void> Function() onSave;
  final List<Widget> children;
  const _BottomForm(
      {required this.title,
      required this.onSave,
      required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 20, 20,
          MediaQuery.of(context).viewInsets.bottom + 20),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            Text(title,
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _kPrimary)),
            const SizedBox(height: 20),
            ...children,
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onSave,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Save',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
