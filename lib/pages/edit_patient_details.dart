import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EditPatientDetails extends StatefulWidget {
  final Map<String, dynamic> patient;

  const EditPatientDetails({super.key, required this.patient});

  @override
  _EditPatientDetailsState createState() => _EditPatientDetailsState();
}

class _EditPatientDetailsState extends State<EditPatientDetails> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController ageController = TextEditingController();
  final TextEditingController genderController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController pinController = TextEditingController();
  final TextEditingController bloodController = TextEditingController();
  final TextEditingController medicalHistoryController = TextEditingController();
  final TextEditingController vaccinationController = TextEditingController();
  final TextEditingController currentMedicationController = TextEditingController();
  final TextEditingController familyHistoryController = TextEditingController();
  final TextEditingController allergiesController = TextEditingController();
  
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _populateFields();
  }

  void _populateFields() {
    nameController.text = widget.patient['name'] ?? '';
    emailController.text = widget.patient['email'] ?? '';
    phoneController.text = widget.patient['phone'] ?? '';
    ageController.text = widget.patient['age'] ?? '';
    genderController.text = widget.patient['gender'] ?? '';
    addressController.text = widget.patient['address'] ?? '';
    pinController.text = widget.patient['pin'] ?? '';
    bloodController.text = widget.patient['blood'] ?? '';
    medicalHistoryController.text = widget.patient['medical history'] ?? '';
    vaccinationController.text = widget.patient['vaccination'] ?? '';
    currentMedicationController.text = widget.patient['current medication'] ?? '';
    familyHistoryController.text = widget.patient['family history'] ?? '';
    allergiesController.text = widget.patient['allergies'] ?? '';
  }

  Future<void> updatePatient() async {
    // Validate required fields
    if (nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter patient name')),
      );
      return;
    }

    if (emailController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter patient email')),
      );
      return;
    }

    // Validate email format
    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(emailController.text.trim())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid email address')),
      );
      return;
    }

    try {
      setState(() {
        _isUpdating = true;
      });

      // Get current user
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please log in to update patients')),
        );
        return;
      }

      // Access the values from the text controllers
      String name = nameController.text.trim();
      String email = emailController.text.trim();
      String phone = phoneController.text.trim();
      String age = ageController.text.trim();
      String gender = genderController.text.trim();
      String address = addressController.text.trim();
      String pin = pinController.text.trim();
      String blood = bloodController.text.trim();
      String medicalHistory = medicalHistoryController.text.trim();
      String vaccination = vaccinationController.text.trim();
      String currentMedication = currentMedicationController.text.trim();
      String familyHistory = familyHistoryController.text.trim();
      String allergies = allergiesController.text.trim();

      // Prepare patient data
      Map<String, dynamic> patientData = {
        'name': name,
        'email': email,
        'phone': phone,
        'age': age,
        'gender': gender,
        'address': address,
        'pin': pin,
        'blood': blood,
        'medical history': medicalHistory,
        'vaccination': vaccination,
        'current medication': currentMedication,
        'family history': familyHistory,
        'allergies': allergies,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Update in Firebase (doctor's patients collection)
      await FirebaseFirestore.instance
          .collection('patients')
          .doc(widget.patient['id'])
          .update(patientData);

      // Also sync overlapping fields to the patient's users/{uid} document
      if (email.isNotEmpty) {
        final userQuery = await FirebaseFirestore.instance
            .collection('users')
            .where('email', isEqualTo: email)
            .limit(1)
            .get();
        if (userQuery.docs.isNotEmpty) {
          final userRef = userQuery.docs.first.reference;
          await userRef.update({
            'name': name,
            'phone': phone,
            'address': address,
            'age': int.tryParse(age) ?? 0,
            'bloodGroup': blood,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      }

      if (!mounted) return;

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Patient $name updated successfully!')),
      );

      // Navigate back to patient selection page
      Navigator.of(context).pop();

    } catch (e) {
      print('Error updating patient: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating patient: $e')),
      );
    } finally {
      setState(() {
        _isUpdating = false;
      });
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    ageController.dispose();
    genderController.dispose();
    addressController.dispose();
    pinController.dispose();
    bloodController.dispose();
    medicalHistoryController.dispose();
    vaccinationController.dispose();
    currentMedicationController.dispose();
    familyHistoryController.dispose();
    allergiesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(
          'Edit ${widget.patient['name'] ?? 'Patient'}',
          style: const TextStyle(
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
        child: SingleChildScrollView(
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Edit Patient Details",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Update ${widget.patient['name'] ?? 'patient'}'s information",
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Form section
              Container(
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
                  padding: const EdgeInsets.all(25.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Basic Information Section
                      _buildSectionTitle('Basic Information'),
                      _buildTextField(nameController, 'Patient Name', Icons.person),
                      _buildTextField(emailController, 'Email Address', Icons.email),
                      _buildTextField(phoneController, 'Phone Number', Icons.phone),
                      _buildTextField(ageController, 'Age', Icons.cake),
                      _buildTextField(genderController, 'Gender', Icons.wc),
                      
                      const SizedBox(height: 20),
                      
                      // Address Information Section
                      _buildSectionTitle('Address Information'),
                      _buildTextField(addressController, 'Address', Icons.location_on, maxLines: 3),
                      _buildTextField(pinController, 'Pin Code', Icons.pin_drop),
                      
                      const SizedBox(height: 20),
                      
                      // Medical Information Section
                      _buildSectionTitle('Medical Information'),
                      _buildTextField(bloodController, 'Blood Group', Icons.bloodtype),
                      _buildTextField(medicalHistoryController, 'Medical History', Icons.medical_services, maxLines: 3),
                      _buildTextField(vaccinationController, 'Vaccination Records', Icons.vaccines, maxLines: 3),
                      _buildTextField(currentMedicationController, 'Current Medications', Icons.medication, maxLines: 3),
                      _buildTextField(familyHistoryController, 'Family Medical History', Icons.family_restroom, maxLines: 3),
                      _buildTextField(allergiesController, 'Allergies', Icons.warning, maxLines: 3),
                      
                      const SizedBox(height: 30),
                      
                      // Action buttons
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _isUpdating ? null : updatePatient,
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.all(20),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                backgroundColor: const Color(0xFF6C5CE7),
                              ),
                              child: _isUpdating
                                  ? const CircularProgressIndicator(color: Colors.white)
                                  : const Text(
                                      'Update Patient',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(width: 15),
                          ElevatedButton(
                            onPressed: () => Navigator.of(context).pop(),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.all(20),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              backgroundColor: Colors.grey,
                            ),
                            child: const Text(
                              'Cancel',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15, top: 10),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Color(0xFF6C5CE7),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {int maxLines = 1}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            maxLines: maxLines,
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFFF8F9FA),
              contentPadding: const EdgeInsets.all(20),
              hintText: 'Enter $label',
              hintStyle: const TextStyle(
                color: Colors.grey,
                fontSize: 16,
              ),
              prefixIcon: Icon(icon, color: const Color(0xFF6C5CE7)),
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
        ],
      ),
    );
  }
}

