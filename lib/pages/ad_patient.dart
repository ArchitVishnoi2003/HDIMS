import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AddPatient extends StatefulWidget {
  const AddPatient({super.key});

  @override
  _AddPatientState createState() => _AddPatientState();
}

class _AddPatientState extends State<AddPatient> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController ageController = TextEditingController();
  final TextEditingController genderController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController pinController = TextEditingController();
  final TextEditingController bloodController = TextEditingController();
  final TextEditingController medicalHistoryController =
      TextEditingController();
  final TextEditingController vaccinationController = TextEditingController();
  final TextEditingController currentMedicationController =
      TextEditingController();
  final TextEditingController familyHistoryController = TextEditingController();
  final TextEditingController allergiesController = TextEditingController();

  @override
  void dispose() {
    // Clean up the controllers when the widget is disposed
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

  // Method to handle the 'Add Patient' action
  Future<void> addPatient() async {
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
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Get current user
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        Navigator.of(context).pop(); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please log in to add patients')),
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
        'doctorId': currentUser.uid,
        'createdAt': FieldValue.serverTimestamp(),
      };

      // Save to Firebase
      await FirebaseFirestore.instance
          .collection('patients')
          .add(patientData);

      // Close loading dialog
      Navigator.of(context).pop();

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Patient $name added successfully!')),
      );

      // Clear form
      nameController.clear();
      emailController.clear();
      phoneController.clear();
      ageController.clear();
      genderController.clear();
      addressController.clear();
      pinController.clear();
      bloodController.clear();
      medicalHistoryController.clear();
      vaccinationController.clear();
      currentMedicationController.clear();
      familyHistoryController.clear();
      allergiesController.clear();

      // Navigate back to dashboard
      Navigator.of(context).pop();

    } catch (e) {
      // Close loading dialog if open
      Navigator.of(context).pop();
      
      print('Error adding patient: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding patient: $e')),
      );
    }
  }

  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Add Patient',
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header section
              Container(
                width: double.infinity,
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
                      "Add New Patient",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      "Enter patient details to create a new record",
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 30),
              
              // Form section
              Container(
                padding: const EdgeInsets.all(25),
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
                child: Column(
                  children: [
                    _buildTextField(nameController, 'Patient Name', Icons.person),
                    _buildTextField(emailController, 'Email Address', Icons.email),
                    _buildTextField(phoneController, 'Phone Number', Icons.phone),
                    _buildTextField(ageController, 'Age', Icons.cake),
                    _buildTextField(genderController, 'Gender', Icons.wc),
                    _buildTextField(addressController, 'Address', Icons.location_on, maxLines: 3),
                    _buildTextField(pinController, 'Pin Code', Icons.pin_drop),
                    _buildTextField(bloodController, 'Blood Group', Icons.bloodtype),
                    _buildTextField(medicalHistoryController, 'Medical History', Icons.medical_services, maxLines: 3),
                    _buildTextField(vaccinationController, 'Vaccination Records', Icons.vaccines, maxLines: 3),
                    _buildTextField(currentMedicationController, 'Current Medications', Icons.medication, maxLines: 3),
                    _buildTextField(familyHistoryController, 'Family Medical History', Icons.family_restroom, maxLines: 3),
                    _buildTextField(allergiesController, 'Allergies', Icons.warning, maxLines: 3),
                    
                    const SizedBox(height: 30),
                    
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: addPatient,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6C5CE7),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          elevation: 5,
                        ),
                        child: const Text(
                          'Add Patient',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
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
