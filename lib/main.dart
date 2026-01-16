import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'report_issue_screen.dart';
import 'view_issues_screen.dart';
import 'profile_screen.dart'; 

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 🛡️ Fail-Safe Initialization: Catches "Duplicate App" errors on restart
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print("✅ Firebase Initialized Successfully");
  } catch (e) {
    print("⚠️ Firebase was already running (Safe to ignore): $e");
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Civic Lens',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Civic Lens'),
        centerTitle: true,
        backgroundColor: Colors.deepPurple.shade50,
        // 👤 Profile Button
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle, size: 30, color: Colors.deepPurple),
            onPressed: () {
              Navigator.push(
                context, 
                MaterialPageRoute(builder: (context) => const ProfileScreen())
              );
            },
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.location_city, size: 100, color: Colors.deepPurple),
            const SizedBox(height: 20),
            const Text(
              "Welcome to Civic Lens",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              "Empowering citizens to report and resolve local issues.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 40),
            
            // Button 1: Report New Issue
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(20),
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                Navigator.push(
                  context, 
                  MaterialPageRoute(builder: (context) => const ReportIssueScreen())
                );
              },
              icon: const Icon(Icons.add_a_photo),
              label: const Text("Report New Issue", style: TextStyle(fontSize: 18)),
            ),
            
            const SizedBox(height: 20),

            // Button 2: View Community Reports
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(20),
                backgroundColor: Colors.white,
                foregroundColor: Colors.deepPurple,
                side: const BorderSide(color: Colors.deepPurple),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                Navigator.push(
                  context, 
                  MaterialPageRoute(builder: (context) => const ViewIssuesScreen())
                );
              },
              icon: const Icon(Icons.list_alt),
              label: const Text("View Community Reports", style: TextStyle(fontSize: 18)),
            ),
          ],
        ),
      ),
    );
  }
}