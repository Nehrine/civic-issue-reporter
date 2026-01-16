import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
// ✅ Use this exact line
import 'package:google_sign_in/google_sign_in.dart';
import '../report_issue_screen.dart'; // Make sure this import path is correct

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  // ✅ CORRECT LOGOUT FUNCTION
  Future<void> _logout(BuildContext context) async {
    try {
      // 1. Sign out of Google (Crucial for switching accounts)
      await GoogleSignIn().signOut();
      
      // 2. Sign out of Firebase
      await FirebaseAuth.instance.signOut();

      // 3. Navigate back to Login and remove all previous screens
      if (context.mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Logout Error: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Civic Dashboard"),
        actions: [
          // LOGOUT BUTTON
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _logout(context), 
            tooltip: "Logout",
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.verified_user, size: 80, color: Colors.green),
            const SizedBox(height: 20),
            Text(
              "Welcome, ${user?.email ?? 'User'}!",
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 40),
            
            // REPORT ISSUE BUTTON
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ReportIssueScreen()),
                );
              },
              icon: const Icon(Icons.camera_alt),
              label: const Text("Report New Issue", style: TextStyle(fontSize: 18)),
            ),
          ],
        ),
      ),
    );
  }
}