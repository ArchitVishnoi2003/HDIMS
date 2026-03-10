import 'package:flutter/material.dart';

class PatientMedicinesAllergy extends StatelessWidget {
  const PatientMedicinesAllergy({super.key});

  @override
  Widget build(BuildContext context) {
    // Hardcoded forbidden medicines data
    final forbiddenMedicines = [
      {
        "medicine": "Amoxicillin",
        "reason": "Contains Penicillin",
        "severity": "High",
        "alternative": "Azithromycin",
      },
      {
        "medicine": "Ibuprofen",
        "reason": "May cause allergy reaction",
        "severity": "Medium",
        "alternative": "Acetaminophen",
      },
      {
        "medicine": "Aspirin",
        "reason": "Contains salicylates",
        "severity": "High",
        "alternative": "Paracetamol",
      },
      {
        "medicine": "Penicillin V",
        "reason": "Direct penicillin allergy",
        "severity": "High",
        "alternative": "Cephalexin",
      },
    ];

    // Hardcoded current medications
    final currentMedications = [
      {
        "medicine": "Cetirizine",
        "dosage": "10mg",
        "frequency": "Once daily",
        "purpose": "Allergy relief",
        "startDate": "2025-09-01",
      },
      {
        "medicine": "Lisinopril",
        "dosage": "5mg",
        "frequency": "Once daily",
        "purpose": "Blood pressure control",
        "startDate": "2025-08-15",
      },
    ];

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
                  "Medicines & Allergies",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Important medication information and allergy warnings",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

          // Forbidden Medicines Section
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
                Row(
                  children: [
                    Icon(Icons.warning, color: Colors.red[600]),
                    const SizedBox(width: 8),
                    const Text(
                      "Forbidden Medicines",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF6C5CE7),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                Text(
                  "These medicines should be avoided due to your allergies:",
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 20),
                ...forbiddenMedicines.map((medicine) => 
                  _buildForbiddenMedicineCard(medicine)
                ).toList(),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Current Medications Section
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
                Row(
                  children: [
                    Icon(Icons.medication, color: Colors.green[600]),
                    const SizedBox(width: 8),
                    const Text(
                      "Current Medications",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF6C5CE7),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                Text(
                  "Medicines you are currently taking:",
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 20),
                ...currentMedications.map((medicine) => 
                  _buildCurrentMedicineCard(medicine)
                ).toList(),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Allergy Information Section
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
                Row(
                  children: [
                    Icon(Icons.warning, color: Colors.orange[600]),
                    const SizedBox(width: 8),
                    const Text(
                      "Allergy Information",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF6C5CE7),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                _buildAllergyInfoCard("Penicillin", "Antibiotic allergy", "High"),
                const SizedBox(height: 10),
                _buildAllergyInfoCard("Peanuts", "Food allergy", "High"),
                const SizedBox(height: 10),
                _buildAllergyInfoCard("Dust Mites", "Environmental allergy", "Medium"),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Important Notice
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.red[50],
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.red[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info, color: Colors.red[600]),
                    const SizedBox(width: 8),
                    Text(
                      "Important Notice",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.red[600],
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  "Always inform your doctor about your allergies before taking any new medication. Keep this information with you at all times.",
                  style: TextStyle(
                    color: Colors.red[600],
                    fontSize: 14,
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

  Widget _buildForbiddenMedicineCard(Map<String, String> medicine) {
    Color severityColor = Colors.red;
    if (medicine['severity'] == 'Medium') {
      severityColor = Colors.orange;
    } else if (medicine['severity'] == 'Low') {
      severityColor = Colors.yellow[700]!;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.close, color: Colors.red[600], size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  medicine['medicine']!,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.red[600],
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: severityColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  medicine['severity']!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            "Reason: ${medicine['reason']}",
            style: TextStyle(
              color: Colors.red[600],
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Alternative: ${medicine['alternative']}",
            style: TextStyle(
              color: Colors.green[600],
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentMedicineCard(Map<String, String> medicine) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.medication, color: Colors.green[600], size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  medicine['medicine']!,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.green[600],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  "Dosage: ${medicine['dosage']}",
                  style: const TextStyle(fontSize: 14),
                ),
              ),
              Expanded(
                child: Text(
                  "Frequency: ${medicine['frequency']}",
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            "Purpose: ${medicine['purpose']}",
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(
            "Started: ${medicine['startDate']}",
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAllergyInfoCard(String allergen, String description, String severity) {
    Color severityColor = Colors.red;
    if (severity == 'Medium') {
      severityColor = Colors.orange;
    } else if (severity == 'Low') {
      severityColor = Colors.yellow[700]!;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.orange[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.warning, color: Colors.orange[600], size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  allergen,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange[600],
                    fontSize: 14,
                  ),
                ),
                Text(
                  description,
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: severityColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              severity,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
