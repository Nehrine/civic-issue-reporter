import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart'; // REQUIRED IMPORT
import 'auth/login_page.dart';
import 'auth/signup_page.dart';
import 'dashboard/dashboard_page.dart';
// If you have a separate file for report screen, import it too
import 'report_issue_screen.dart'; 

void main() async { // <--- 1. MUST BE ASYNC
  // 2. These two lines are MANDATORY for Firebase
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); 

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Civic Issue Reporter',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        useMaterial3: true,
      ),
      // Start at Login Page
      initialRoute: '/', 
      routes: {
        '/': (context) => const LoginPage(),
        '/signup': (context) => const SignupPage(),
        '/dashboard': (context) => const DashboardPage(),
        // Add other routes if you navigate by name
      },
    );
  }
}
