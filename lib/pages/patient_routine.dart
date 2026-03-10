import 'package:flutter/material.dart';

class PatientRoutine extends StatefulWidget {
  const PatientRoutine({super.key});

  @override
  _PatientRoutineState createState() => _PatientRoutineState();
}

class _PatientRoutineState extends State<PatientRoutine> with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
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
                "Daily Routine",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "Follow your doctor's recommended daily routine",
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),

        // Tab Bar
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
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
          child: TabBar(
            controller: _tabController,
            indicator: BoxDecoration(
              color: const Color(0xFF6C5CE7),
              borderRadius: BorderRadius.circular(15),
            ),
            labelColor: Colors.white,
            unselectedLabelColor: const Color(0xFF6C5CE7),
            labelStyle: const TextStyle(fontWeight: FontWeight.bold),
            tabs: const [
              Tab(text: 'Daily'),
              Tab(text: 'Exercise'),
              Tab(text: 'Diet'),
            ],
          ),
        ),

        // Tab Content
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildDailyRoutineTab(),
              _buildExerciseTab(),
              _buildDietTab(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDailyRoutineTab() {
    // Hardcoded daily routine data
    final dailyRoutine = [
      {
        "time": "07:00 AM",
        "activity": "Morning walk - 30 mins",
        "icon": Icons.directions_walk,
        "color": Colors.green,
      },
      {
        "time": "08:00 AM",
        "activity": "Breakfast - Oatmeal and fruit",
        "icon": Icons.restaurant,
        "color": Colors.orange,
      },
      {
        "time": "09:00 AM",
        "activity": "Take medicine: Cetirizine 10mg",
        "icon": Icons.medication,
        "color": Colors.red,
      },
      {
        "time": "12:30 PM",
        "activity": "Lunch - Salad + Chicken soup",
        "icon": Icons.restaurant,
        "color": Colors.orange,
      },
      {
        "time": "02:00 PM",
        "activity": "Take medicine: Lisinopril 5mg",
        "icon": Icons.medication,
        "color": Colors.red,
      },
      {
        "time": "06:00 PM",
        "activity": "Evening walk - 20 mins",
        "icon": Icons.directions_walk,
        "color": Colors.green,
      },
      {
        "time": "08:00 PM",
        "activity": "Dinner - Light meal",
        "icon": Icons.restaurant,
        "color": Colors.orange,
      },
      {
        "time": "09:00 PM",
        "activity": "Take medicine: Paracetamol 500mg",
        "icon": Icons.medication,
        "color": Colors.red,
      },
      {
        "time": "10:30 PM",
        "activity": "Sleep - 8 hours",
        "icon": Icons.bedtime,
        "color": Colors.purple,
      },
    ];

    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 20),
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
                const Text(
                  "Today's Schedule",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF6C5CE7),
                  ),
                ),
                const SizedBox(height: 20),
                ...dailyRoutine.map((routine) => _buildRoutineItem(routine)).toList(),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildExerciseTab() {
    final exercises = [
      {
        "name": "Morning Walk",
        "duration": "30 minutes",
        "frequency": "Daily",
        "benefits": "Improves cardiovascular health, maintains weight",
        "instructions": "Walk at a moderate pace in a park or safe area",
      },
      {
        "name": "Evening Walk",
        "duration": "20 minutes",
        "frequency": "Daily",
        "benefits": "Helps digestion, reduces stress",
        "instructions": "Light walk after dinner, avoid heavy meals",
      },
      {
        "name": "Stretching",
        "duration": "15 minutes",
        "frequency": "3 times a week",
        "benefits": "Improves flexibility, reduces muscle tension",
        "instructions": "Gentle stretching exercises for all major muscle groups",
      },
      {
        "name": "Breathing Exercises",
        "duration": "10 minutes",
        "frequency": "Daily",
        "benefits": "Reduces stress, improves lung function",
        "instructions": "Deep breathing exercises, meditation",
      },
    ];

    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 20),
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
                const Text(
                  "Exercise Routine",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF6C5CE7),
                  ),
                ),
                const SizedBox(height: 20),
                ...exercises.map((exercise) => _buildExerciseCard(exercise)).toList(),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildDietTab() {
    final dietPlan = [
      {
        "meal": "Breakfast",
        "time": "8:00 AM",
        "food": "Oatmeal with fruits, Green tea",
        "notes": "High fiber, low sugar",
      },
      {
        "meal": "Mid-morning Snack",
        "time": "10:30 AM",
        "food": "Nuts (almonds, walnuts)",
        "notes": "Healthy fats, protein",
      },
      {
        "meal": "Lunch",
        "time": "12:30 PM",
        "food": "Salad with chicken, Brown rice",
        "notes": "Balanced protein and carbs",
      },
      {
        "meal": "Evening Snack",
        "time": "4:00 PM",
        "food": "Fruits (apple, banana)",
        "notes": "Natural sugars, vitamins",
      },
      {
        "meal": "Dinner",
        "time": "8:00 PM",
        "food": "Light soup, Grilled fish",
        "notes": "Light meal, easy digestion",
      },
    ];

    final restrictions = [
      "Avoid processed foods",
      "Limit salt intake (for blood pressure)",
      "No alcohol consumption",
      "Avoid foods with peanuts (allergy)",
      "Limit caffeine intake",
    ];

    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 20),
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
                const Text(
                  "Diet Plan",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF6C5CE7),
                  ),
                ),
                const SizedBox(height: 20),
                ...dietPlan.map((meal) => _buildMealCard(meal)).toList(),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.red[50],
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.red[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.warning, color: Colors.red[600]),
                    const SizedBox(width: 8),
                    Text(
                      "Dietary Restrictions",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.red[600],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                ...restrictions.map((restriction) => 
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Icon(Icons.close, color: Colors.red[600], size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            restriction,
                            style: TextStyle(
                              color: Colors.red[600],
                              fontWeight: FontWeight.w500,
                            ),
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
        ],
      ),
    );
  }

  Widget _buildRoutineItem(Map<String, dynamic> routine) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: (routine['color'] as Color).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: (routine['color'] as Color).withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: routine['color'] as Color,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              routine['icon'] as IconData,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  routine['time'],
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: routine['color'] as Color,
                    fontSize: 16,
                  ),
                ),
                Text(
                  routine['activity'],
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseCard(Map<String, String> exercise) {
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
              Icon(Icons.fitness_center, color: Colors.green[600], size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  exercise['name']!,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green[600],
                    fontSize: 16,
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
                  "Duration: ${exercise['duration']}",
                  style: const TextStyle(fontSize: 14),
                ),
              ),
              Expanded(
                child: Text(
                  "Frequency: ${exercise['frequency']}",
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            "Benefits: ${exercise['benefits']}",
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 8),
          Text(
            "Instructions: ${exercise['instructions']}",
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMealCard(Map<String, String> meal) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.restaurant, color: Colors.orange[600], size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  meal['meal']!,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange[600],
                    fontSize: 16,
                  ),
                ),
              ),
              Text(
                meal['time']!,
                style: TextStyle(
                  color: Colors.orange[600],
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            meal['food']!,
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(
            "Notes: ${meal['notes']!}",
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}

