import 'package:flutter/material.dart';

class PatientPersonalDetails extends StatelessWidget {
  const PatientPersonalDetails({super.key});

  @override
  Widget build(BuildContext context) {
    // Hardcoded personal details data
    final personalDetails = {
      "name": "John Doe",
      "age": 32,
      "gender": "Male",
      "phone": "+91 9876543210",
      "email": "johndoe@gmail.com",
      "address": "123 Main Street, City, State 12345",
      "allergies": ["Penicillin", "Peanuts"],
      "chronicConditions": ["Hypertension"],
      "lastUpdated": "2025-10-01",
    };

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
                  color: const Color(0xFF6C5CE7).withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Personal Details",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Last updated: ${personalDetails['lastUpdated']}",
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

          // Basic Information Section
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.all(20),
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle("Basic Information"),
                _buildDetailRow("Full Name", personalDetails['name'] as String),
                _buildDetailRow("Age", "${personalDetails['age']} years"),
                _buildDetailRow("Gender", personalDetails['gender'] as String),
                _buildDetailRow("Phone", personalDetails['phone'] as String),
                _buildDetailRow("Email", personalDetails['email'] as String),
                _buildDetailRow("Address", personalDetails['address'] as String),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Health Information Section
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.all(20),
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle("Health Information"),
                
                // Allergies
                _buildDetailRow("Allergies", ""),
                const SizedBox(height: 10),
                ...(personalDetails['allergies'] as List<String>).map((allergy) => 
                  Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.warning, color: Colors.red[600], size: 16),
                        const SizedBox(width: 8),
                        Text(
                          allergy,
                          style: TextStyle(
                            color: Colors.red[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ).toList(),

                const SizedBox(height: 20),

                // Chronic Conditions
                _buildDetailRow("Chronic Conditions", ""),
                const SizedBox(height: 10),
                ...(personalDetails['chronicConditions'] as List<String>).map((condition) => 
                  Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.orange[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.medical_services, color: Colors.orange[600], size: 16),
                        const SizedBox(width: 8),
                        Text(
                          condition,
                          style: TextStyle(
                            color: Colors.orange[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ).toList(),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Emergency Contact Section
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.all(20),
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle("Emergency Contact"),
                _buildDetailRow("Emergency Contact", "+91 9876543211"),
                _buildDetailRow("Relationship", "Spouse"),
                _buildDetailRow("Address", "Same as patient address"),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Insurance Information Section
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.all(20),
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle("Insurance Information"),
                _buildDetailRow("Insurance Provider", "HealthCare Plus"),
                _buildDetailRow("Policy Number", "HCP-123456789"),
                _buildDetailRow("Coverage Type", "Family Plan"),
                _buildDetailRow("Valid Until", "Dec 31, 2025"),
              ],
            ),
          ),

          const SizedBox(height: 30),

          // Update Notice
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF6C5CE7).withOpacity(0.1),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: const Color(0xFF6C5CE7).withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.info, color: const Color(0xFF6C5CE7)),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Information Update",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF6C5CE7),
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        "Your personal details are updated by the hospital staff. Contact your healthcare provider for any corrections.",
                        style: TextStyle(
                          color: const Color(0xFF6C5CE7).withOpacity(0.8),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
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

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.black87,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black54,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
