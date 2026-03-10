import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutterapp/services/access_request_service.dart';
import 'edit_patient_details.dart';

class SelectPatientToUpdate extends StatefulWidget {
  const SelectPatientToUpdate({super.key});

  @override
  _SelectPatientToUpdateState createState() => _SelectPatientToUpdateState();
}

class _SelectPatientToUpdateState extends State<SelectPatientToUpdate> {
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

        // Sort patients alphabetically by name
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

  Future<void> _navigateToEditPatient(Map<String, dynamic> patient) async {
    final doctorUid = FirebaseAuth.instance.currentUser?.uid;
    if (doctorUid == null) return;

    // Use pre-enriched privacy data from _fetchPatients
    final privacyEnabled = patient['_privacyMode'] == true;
    final patientUid = patient['_userUid'] as String?;

    if (privacyEnabled && patientUid != null) {
      final hasAccess = await AccessRequestService.hasAccess(
        doctorUid: doctorUid,
        patientUid: patientUid,
      );
      if (!mounted) return;

      if (!hasAccess) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'This patient has Privacy Mode on. Request access from View Patients first.'),
        ));
        return;
      }
    }

    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditPatientDetails(patient: patient),
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
          'Select Patient to Update',
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
                    "Update Patient",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "Select a patient to update their information",
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
                                              Icons.edit,
                                              color: Color(0xFF6C5CE7),
                                              size: 20,
                                            ),
                                          ),
                                          onTap: () => _navigateToEditPatient(patient),
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
