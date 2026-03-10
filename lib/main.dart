import 'package:flutter/material.dart';
import 'package:flutterapp/pages/dashboard.dart';
import 'package:flutterapp/pages/patient_dashboard.dart';
import 'package:flutterapp/pages/user_type_selection.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutterapp/pages/signup_page.dart';
import 'firebase_options.dart';
import 'package:flutterapp/pages/ask_diet_plan.dart';


void main()async{
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      routes: {
        '/': (context) => AuthWrapper(),
        '/dashboard': (context) => const Dashboard(),
        '/patient-dashboard': (context) => const PatientDashboard(),
        '/user-type-selection': (context) => const UserTypeSelection(),
        '/auth': (context) => HomeScreen(),
        '/ask-ai': (context) => const AskAIPage(),
      },
    );
  }
}

class AuthWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
        
        if (snapshot.hasData) {
          return UserTypeWrapper();
        } else {
          return HomeScreen();
        }
      },
    );
  }
}

class UserTypeWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser?.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
        
        if (snapshot.hasData && snapshot.data!.exists) {
          final userData = snapshot.data!.data() as Map<String, dynamic>;
          final userType = userData['userType'];
          
          
          if (userType == null) {
            // User exists but doesn't have userType field - show selection screen
            return const UserTypeSelection();
          } else if (userType == 'hospital') {
            return const Dashboard();
          } else {
            return const PatientDashboard();
          }
        } else if (snapshot.hasError) {
          return HomeScreen();
        } else {
          // If user data doesn't exist, redirect to auth
          return HomeScreen();
        }
      },
    );
  }
}
