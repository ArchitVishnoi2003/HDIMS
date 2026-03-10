import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class DeletePatient extends StatefulWidget {
  const DeletePatient({super.key});

  @override
  _DeletePatientState createState() => _DeletePatientState();
}

class _DeletePatientState extends State<DeletePatient> {
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

        setState(() {
          _patients = querySnapshot.docs
              .map((doc) => {
                    'id': doc.id,
                    ...doc.data() as Map<String, dynamic>,
                  })
              .toList();
          _filteredPatients = _patients;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching patients: $e');
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching patients: $e')),
      );
    }
  }

  Future<void> _deletePatient(String patientId, String patientName) async {
    try {
      // Show confirmation dialog
      bool? confirmed = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Delete Patient'),
            content: Text('Are you sure you want to delete $patientName? This action cannot be undone.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text('Delete'),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
              ),
            ],
          );
        },
      );

      if (confirmed == true) {
        // Delete from Firebase
        await FirebaseFirestore.instance
            .collection('patients')
            .doc(patientId)
            .delete();

        // Update local list
        setState(() {
          _patients.removeWhere((patient) => patient['id'] == patientId);
          _filteredPatients.removeWhere((patient) => patient['id'] == patientId);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Patient $patientName deleted successfully')),
        );
      }
    } catch (e) {
      print('Error deleting patient: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting patient: $e')),
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
          'Delete Patient',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFFE74C3C),
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
                  colors: [Color(0xFFE74C3C), Color(0xFFE67E22)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFE74C3C).withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Delete Patient",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "Select and remove patient records permanently",
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
                          prefixIcon: const Icon(Icons.search, color: Color(0xFFE74C3C)),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: const BorderSide(color: Color(0xFFE74C3C), width: 2),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Patients count
                      if (!_isLoading)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE74C3C).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${_filteredPatients.length} patient(s) found',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFFE74C3C),
                            ),
                          ),
                        ),
                      
                      const SizedBox(height: 20),
                      
                      // Patients list
                      Expanded(
                        child: _isLoading
                            ? const Center(child: CircularProgressIndicator(color: Color(0xFFE74C3C)))
                            : _filteredPatients.isEmpty
                                ? Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(20),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFE74C3C).withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(50),
                                          ),
                                          child: const Icon(
                                            Icons.person_off,
                                            size: 48,
                                            color: Color(0xFFE74C3C),
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
                                            backgroundColor: const Color(0xFFE74C3C),
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
                                                patient['phone'] ?? '',
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
                                              color: const Color(0xFFE74C3C).withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: const Icon(
                                              Icons.delete,
                                              color: Color(0xFFE74C3C),
                                              size: 20,
                                            ),
                                          ),
                                          onTap: () => _deletePatient(
                                            patient['id'],
                                            patient['name'] ?? 'Unknown',
                                          ),
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


