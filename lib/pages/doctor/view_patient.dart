import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutterapp/services/access_request_service.dart';

class ViewPatient extends StatefulWidget {
  const ViewPatient({super.key});

  @override
  _ViewPatientState createState() => _ViewPatientState();
}

class _ViewPatientState extends State<ViewPatient> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _patients = [];
  List<Map<String, dynamic>> _filteredPatients = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchPatients();
  }

  Future<void> _fetchPatients() async {
    try {
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        QuerySnapshot querySnapshot = await FirebaseFirestore.instance
            .collection('patients')
            .where('doctorId', isEqualTo: currentUser.uid)
            .get();

        var patients = querySnapshot.docs
            .map((doc) => {
                  'id': doc.id,
                  ...doc.data() as Map<String, dynamic>,
                })
            .toList();

        // Enrich with user-collection data where a linked account exists
        patients = await AccessRequestService.enrichWithUserData(patients);

        // Sort patients alphabetically by name on the client side
        patients.sort((a, b) {
          String nameA = a['name']?.toString().toLowerCase() ?? '';
          String nameB = b['name']?.toString().toLowerCase() ?? '';
          return nameA.compareTo(nameB);
        });

        if (!mounted) return;
        setState(() {
          _patients = patients;
          _filteredPatients = _patients;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching patients: $e');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching patients: $e')),
      );
    }
  }

  void _filterPatients(String query) {
    setState(() {
      _filteredPatients = _patients.where((patient) {
        final name = patient['name']?.toString().toLowerCase() ?? '';
        final email = patient['email']?.toString().toLowerCase() ?? '';
        final phone = patient['phone']?.toString().toLowerCase() ?? '';
        final searchQuery = query.toLowerCase();
        
        return name.contains(searchQuery) ||
               email.contains(searchQuery) ||
               phone.contains(searchQuery);
      }).toList();
    });
  }

  Future<void> _showPatientDetails(Map<String, dynamic> patient) async {
    // Use pre-enriched data from _fetchPatients
    final patientUid = patient['_userUid'] as String?;
    final privacyModeEnabled = patient['_privacyMode'] == true;

    final doctorUid = FirebaseAuth.instance.currentUser?.uid;

    // Get the doctor's display name for the request
    final doctorDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(doctorUid)
        .get();
    final doctorName = doctorDoc.data()?['name'] as String? ??
        FirebaseAuth.instance.currentUser?.email ??
        'Doctor';

    if (!mounted) return;

    // Check if doctor already has approved access
    String? approvedRequestId;
    if (privacyModeEnabled && patientUid != null && doctorUid != null) {
      approvedRequestId = await AccessRequestService.getApprovedRequestId(
        doctorUid: doctorUid,
        patientUid: patientUid,
      );
    }
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          patient['name'] ?? 'Unknown Patient',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (privacyModeEnabled)
                Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6C5CE7).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: const Color(0xFF6C5CE7).withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.lock,
                          color: Color(0xFF6C5CE7), size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          approvedRequestId != null
                              ? 'Privacy Mode is active. You have approved access.'
                              : 'Privacy Mode is active. Patient-entered records are encrypted.',
                          style: const TextStyle(
                              fontSize: 12, color: Color(0xFF6C5CE7)),
                        ),
                      ),
                    ],
                  ),
                ),
              _buildDetailRow('Email', patient['email']),
              _buildDetailRow('Phone', patient['phone']),
              _buildDetailRow('Age', patient['age']),
              _buildDetailRow('Gender', patient['gender']),
              _buildDetailRow('Blood Group', patient['blood']),
              _buildDetailRow('Address', patient['address']),
              _buildDetailRow('Pin Code', patient['pin']),
              _buildDetailRow('Medical History', patient['medical history']),
              _buildDetailRow('Vaccination', patient['vaccination']),
              _buildDetailRow(
                  'Current Medications', patient['current medication']),
              _buildDetailRow('Family History', patient['family history']),
              _buildDetailRow('Allergies', patient['allergies']),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
          if (privacyModeEnabled && patientUid != null) ...[
            if (approvedRequestId != null)
              ElevatedButton.icon(
                icon: const Icon(Icons.visibility,
                    size: 16, color: Colors.white),
                label: const Text('View Records',
                    style: TextStyle(color: Colors.white, fontSize: 13)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[600],
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () {
                  Navigator.of(ctx).pop();
                  _showSessionRecords(approvedRequestId!, patientUid,
                      patient['name'] ?? 'Patient');
                },
              )
            else
              ElevatedButton.icon(
                icon: const Icon(Icons.lock_open,
                    size: 16, color: Colors.white),
                label: const Text('Request Access',
                    style: TextStyle(color: Colors.white, fontSize: 13)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6C5CE7),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () async {
                  Navigator.of(ctx).pop();
                  await AccessRequestService.requestAccess(
                    patientUid: patientUid,
                    doctorName: doctorName,
                  );
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text(
                            'Access request sent. Waiting for patient approval.')));
                  }
                },
              ),
          ],
        ],
      ),
    );
  }

  Future<void> _showSessionRecords(
      String requestId, String patientUid, String patientName) async {
    final session =
        await AccessRequestService.readSession(requestId, patientUid);
    if (!mounted) return;

    if (session == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Access session expired or not found.')));
      return;
    }

    final medications =
        List<Map<String, dynamic>>.from(session['medications'] ?? []);
    final allergies =
        List<Map<String, dynamic>>.from(session['allergies'] ?? []);
    final checkups =
        List<Map<String, dynamic>>.from(session['checkups'] ?? []);
    final appointments =
        List<Map<String, dynamic>>.from(session['appointments'] ?? []);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('$patientName — Health Records',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: SizedBox(
          width: double.maxFinite,
          child: DefaultTabController(
            length: 4,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const TabBar(
                  isScrollable: true,
                  labelColor: Color(0xFF6C5CE7),
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: Color(0xFF6C5CE7),
                  labelStyle: TextStyle(fontSize: 12),
                  tabs: [
                    Tab(text: 'Medications'),
                    Tab(text: 'Allergies'),
                    Tab(text: 'Checkups'),
                    Tab(text: 'Appointments'),
                  ],
                ),
                SizedBox(
                  height: 300,
                  child: TabBarView(
                    children: [
                      _buildRecordList(medications, [
                        'name', 'dosage', 'frequency', 'purpose', 'startDate'
                      ]),
                      _buildRecordList(
                          allergies, ['allergen', 'severity', 'description']),
                      _buildRecordList(checkups, [
                        'disease', 'date', 'doctor', 'hospital', 'treatment'
                      ]),
                      _buildRecordList(appointments, [
                        'doctor', 'hospital', 'date', 'time', 'department',
                        'status'
                      ]),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordList(
      List<Map<String, dynamic>> records, List<String> fields) {
    if (records.isEmpty) {
      return const Center(
          child: Text('No records', style: TextStyle(color: Colors.grey)));
    }
    return ListView.separated(
      itemCount: records.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (_, i) {
        final rec = records[i];
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: fields.where((f) {
              final v = rec[f]?.toString() ?? '';
              return v.isNotEmpty;
            }).map((f) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 80,
                      child: Text('$f:',
                          style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                              color: Colors.black87)),
                    ),
                    Expanded(
                      child: Text(rec[f].toString(),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 12, color: Colors.black54)),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label:',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xffF1E4AB),
            ),
          ),
          Text(
            value ?? 'Not specified',
            style: const TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'View Patients',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF6C5CE7),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Header section
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
                    color: const Color(0xFF6C5CE7).withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Patient Records",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "View and manage all patient information",
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            
            // Search and content section
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Search bar
                      TextField(
                        controller: _searchController,
                        onChanged: _filterPatients,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: const Color(0xFFF8F9FA),
                          contentPadding: const EdgeInsets.all(20),
                          hintText: 'Search patients by name, email, or phone...',
                          hintStyle: const TextStyle(
                            color: Colors.grey,
                            fontSize: 16,
                          ),
                          prefixIcon: const Icon(Icons.search, color: Color(0xFF6C5CE7)),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: const BorderSide(color: Color(0xFF6C5CE7), width: 2),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Patients count
                      if (!_isLoading)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF6C5CE7).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${_filteredPatients.length} patient(s) found',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF6C5CE7),
                            ),
                          ),
                        ),
                      
                      const SizedBox(height: 20),
                      
                      // Patients list
                      Expanded(
                        child: _isLoading
                            ? const Center(child: CircularProgressIndicator(color: Color(0xFF6C5CE7)))
                            : _filteredPatients.isEmpty
                                ? Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(20),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF6C5CE7).withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(50),
                                          ),
                                          child: const Icon(
                                            Icons.person_search,
                                            size: 48,
                                            color: Color(0xFF6C5CE7),
                                          ),
                                        ),
                                        const SizedBox(height: 20),
                                        Text(
                                          _patients.isEmpty
                                              ? 'No patients found'
                                              : 'No patients match your search',
                                          style: const TextStyle(
                                            fontSize: 18,
                                            color: Colors.grey,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : ListView.builder(
                                    itemCount: _filteredPatients.length,
                                    itemBuilder: (context, index) {
                                      final patient = _filteredPatients[index];
                                      return Container(
                                        margin: const EdgeInsets.only(bottom: 15),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(15),
                                          border: Border.all(color: Colors.grey[200]!),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(0.05),
                                              blurRadius: 10,
                                              offset: const Offset(0, 5),
                                            ),
                                          ],
                                        ),
                                        child: ListTile(
                                          contentPadding: const EdgeInsets.all(15),
                                          leading: CircleAvatar(
                                            radius: 25,
                                            backgroundColor: const Color(0xFF6C5CE7),
                                            child: Text(
                                              patient['name']?.toString().substring(0, 1).toUpperCase() ?? '?',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                                fontSize: 18,
                                              ),
                                            ),
                                          ),
                                          title: Text(
                                            patient['name'] ?? 'Unknown',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                          subtitle: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              const SizedBox(height: 5),
                                              Text(
                                                patient['email'] ?? '',
                                                style: const TextStyle(fontSize: 14),
                                              ),
                                              const SizedBox(height: 3),
                                              Text(
                                                '${patient['age'] ?? ''} years • ${patient['gender'] ?? ''} • ${patient['blood'] ?? ''}',
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                            ],
                                          ),
                                          trailing: Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF6C5CE7).withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: const Icon(
                                              Icons.visibility,
                                              color: Color(0xFF6C5CE7),
                                              size: 20,
                                            ),
                                          ),
                                          onTap: () => _showPatientDetails(patient),
                                        ),
                                      );
                                    },
                                  ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


