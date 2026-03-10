import 'package:flutter/material.dart';

class PatientAppointments extends StatelessWidget {
  const PatientAppointments({super.key});

  @override
  Widget build(BuildContext context) {
    // Hardcoded appointments data
    final appointments = [
      {
        "date": "2025-10-20",
        "time": "10:30 AM",
        "doctor": "Dr. Smith",
        "hospital": "City Hospital",
        "department": "General Medicine",
        "status": "Upcoming",
        "type": "Regular Checkup",
        "notes": "Annual health checkup",
      },
      {
        "date": "2025-11-05",
        "time": "2:00 PM",
        "doctor": "Dr. Emily",
        "hospital": "Green Hospital",
        "department": "Cardiology",
        "status": "Upcoming",
        "type": "Specialist Consultation",
        "notes": "Blood pressure follow-up",
      },
      {
        "date": "2025-09-10",
        "time": "11:00 AM",
        "doctor": "Dr. Emily",
        "hospital": "Green Hospital",
        "department": "General Medicine",
        "status": "Completed",
        "type": "Follow-up",
        "notes": "Flu treatment follow-up",
      },
      {
        "date": "2025-07-15",
        "time": "3:30 PM",
        "doctor": "Dr. Johnson",
        "hospital": "City Hospital",
        "department": "General Medicine",
        "status": "Completed",
        "type": "Regular Checkup",
        "notes": "Allergy consultation",
      },
    ];

    // Separate upcoming and completed appointments
    final upcomingAppointments = appointments.where((apt) => apt['status'] == 'Upcoming').toList();
    final completedAppointments = appointments.where((apt) => apt['status'] == 'Completed').toList();

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
                  "Appointments",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Manage your upcoming and past appointments",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

          // Quick Stats
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    "Upcoming",
                    upcomingAppointments.length.toString(),
                    Icons.schedule,
                    const Color(0xFF4CAF50),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: _buildStatCard(
                    "Completed",
                    completedAppointments.length.toString(),
                    Icons.check_circle,
                    const Color(0xFF2196F3),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 30),

          // Upcoming Appointments Section
          if (upcomingAppointments.isNotEmpty) ...[
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
                      Icon(Icons.schedule, color: Colors.green[600]),
                      const SizedBox(width: 8),
                      const Text(
                        "Upcoming Appointments",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF6C5CE7),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  ...upcomingAppointments.map((appointment) => 
                    _buildAppointmentCard(context, appointment, true)
                  ).toList(),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],

          // Completed Appointments Section
          if (completedAppointments.isNotEmpty) ...[
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
                      Icon(Icons.history, color: Colors.blue[600]),
                      const SizedBox(width: 8),
                      const Text(
                        "Completed Appointments",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF6C5CE7),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  ...completedAppointments.map((appointment) => 
                    _buildAppointmentCard(context, appointment, false)
                  ).toList(),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],

          // Book New Appointment Button
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                _showBookAppointmentDialog(context);
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                backgroundColor: const Color(0xFF6C5CE7),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add, color: Colors.white),
                  SizedBox(width: 10),
                  Text(
                    'Book New Appointment',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 30),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentCard(BuildContext context, Map<String, String> appointment, bool isUpcoming) {
    Color statusColor = isUpcoming ? Colors.green : Colors.blue;
    Color cardColor = isUpcoming ? Colors.green[50]! : Colors.blue[50]!;
    Color borderColor = isUpcoming ? Colors.green[200]! : Colors.blue[200]!;

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  isUpcoming ? Icons.schedule : Icons.check_circle,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      appointment['doctor']!,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: statusColor,
                      ),
                    ),
                    Text(
                      appointment['hospital']!,
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  appointment['status']!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.calendar_today, color: statusColor, size: 16),
              const SizedBox(width: 8),
              Text(
                appointment['date']!,
                style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
              const SizedBox(width: 20),
              Icon(Icons.access_time, color: statusColor, size: 16),
              const SizedBox(width: 8),
              Text(
                appointment['time']!,
                style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.medical_services, color: statusColor, size: 16),
              const SizedBox(width: 8),
              Text(
                appointment['department']!,
                style: TextStyle(
                  color: statusColor,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            "Type: ${appointment['type']!}",
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
          if (appointment['notes']!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              "Notes: ${appointment['notes']!}",
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
          if (isUpcoming) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      _showRescheduleDialog(context, appointment);
                    },
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: statusColor),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Reschedule',
                      style: TextStyle(color: statusColor),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      _showCancelDialog(context, appointment);
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  void _showBookAppointmentDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Book New Appointment'),
          content: const Text('This feature will be available soon. Please contact the hospital directly to book an appointment.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _showRescheduleDialog(BuildContext context, Map<String, String> appointment) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Reschedule Appointment'),
          content: Text('Reschedule appointment with ${appointment['doctor']} on ${appointment['date']}?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Reschedule feature coming soon!')),
                );
              },
              child: const Text('Reschedule'),
            ),
          ],
        );
      },
    );
  }

  void _showCancelDialog(BuildContext context, Map<String, String> appointment) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Cancel Appointment'),
          content: Text('Are you sure you want to cancel your appointment with ${appointment['doctor']} on ${appointment['date']}?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('No'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Cancel feature coming soon!')),
                );
              },
              child: const Text('Yes, Cancel', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }
}
