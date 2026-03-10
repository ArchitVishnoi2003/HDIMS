import 'package:flutter/material.dart';

class PatientCheckupsHistory extends StatelessWidget {
  const PatientCheckupsHistory({super.key});

  @override
  Widget build(BuildContext context) {
    // Hardcoded checkup history data
    final lastCheckups = [
      {
        "date": "2025-09-10",
        "disease": "Flu",
        "prescriptionImage": "Coming Soon",
        "treatment": "Rest and hydration",
        "doctor": "Dr. Smith",
        "hospital": "City Hospital",
        "vitals": {
          "bp": "120/80",
          "sugar": "95 mg/dL",
          "temp": "98.6°F",
          "weight": "70 kg"
        },
        "medicines": [
          {"name": "Paracetamol", "dosage": "500mg, 3 times a day"},
          {"name": "Cough Syrup", "dosage": "10ml, twice a day"},
        ],
      },
      {
        "date": "2025-07-15",
        "disease": "Allergic Rhinitis",
        "prescriptionImage": "Coming Soon",
        "treatment": "Antihistamines and nasal spray",
        "doctor": "Dr. Emily",
        "hospital": "Green Hospital",
        "vitals": {
          "bp": "118/78",
          "sugar": "92 mg/dL",
          "temp": "98.4°F",
          "weight": "69 kg"
        },
        "medicines": [
          {"name": "Cetirizine", "dosage": "10mg, once a day"},
          {"name": "Nasal Spray", "dosage": "2 sprays each nostril, twice daily"},
        ],
      },
      {
        "date": "2025-05-20",
        "disease": "Hypertension Checkup",
        "prescriptionImage": "Coming Soon",
        "treatment": "Blood pressure monitoring",
        "doctor": "Dr. Johnson",
        "hospital": "City Hospital",
        "vitals": {
          "bp": "135/85",
          "sugar": "98 mg/dL",
          "temp": "98.2°F",
          "weight": "71 kg"
        },
        "medicines": [
          {"name": "Lisinopril", "dosage": "5mg, once daily"},
        ],
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
                  "Medical History",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Your complete medical checkup records and history",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

          // Checkup History List
          ...lastCheckups.map((checkup) => 
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
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
                  // Checkup Header
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6C5CE7).withOpacity(0.1),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF6C5CE7),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.medical_services, color: Colors.white),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                checkup['disease'] as String,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: Color(0xFF6C5CE7),
                                ),
                              ),
                              Text(
                                checkup['date'] as String,
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Checkup Details
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Doctor and Hospital Info
                        _buildInfoRow("Doctor", checkup['doctor'] as String),
                        _buildInfoRow("Hospital", checkup['hospital'] as String),
                        _buildInfoRow("Treatment", checkup['treatment'] as String),

                        const SizedBox(height: 20),

                        // Vitals Section
                        const Text(
                          "Vital Signs",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF6C5CE7),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: _buildVitalCard("Blood Pressure", (checkup['vitals'] as Map<String, dynamic>)['bp'] as String, Icons.favorite),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _buildVitalCard("Blood Sugar", (checkup['vitals'] as Map<String, dynamic>)['sugar'] as String, Icons.water_drop),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: _buildVitalCard("Body Temperature", (checkup['vitals'] as Map<String, dynamic>)['temp'] as String, Icons.thermostat),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _buildVitalCard("Weight", (checkup['vitals'] as Map<String, dynamic>)['weight'] as String, Icons.monitor_weight),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // Prescription Section
                        const Text(
                          "Prescription",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF6C5CE7),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: Column(
                            children: [
                              Icon(Icons.image, size: 50, color: Colors.grey[400]),
                              const SizedBox(height: 10),
                              Text(
                                checkup['prescriptionImage'] as String,
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Medicines Section
                        const Text(
                          "Medicines Prescribed",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF6C5CE7),
                          ),
                        ),
                        const SizedBox(height: 10),
                        ...(checkup['medicines'] as List<Map<String, String>>).map((medicine) => 
                          Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(15),
                            decoration: BoxDecoration(
                              color: Colors.green[50],
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.green[200]!),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.medication, color: Colors.green[600], size: 20),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        medicine['name']!,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green[600],
                                          fontSize: 14,
                                        ),
                                      ),
                                      Text(
                                        medicine['dosage']!,
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ).toList(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ).toList(),

          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
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

  Widget _buildVitalCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.blue[600], size: 20),
          const SizedBox(height: 5),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.blue[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.blue[600],
            ),
          ),
        ],
      ),
    );
  }
}
