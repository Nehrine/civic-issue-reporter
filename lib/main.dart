import 'report_issue_screen.dart';

import 'package:flutter/material.dart';

void main() {
  runApp(const CivicIssueApp());
}

class CivicIssueApp extends StatelessWidget {
  const CivicIssueApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Civic Issue App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
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
        title: const Text('Civic Issue Reporter'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.report_problem,
              size: 80,
              color: Colors.orange,
            ),
            const SizedBox(height: 20),
            const Text(
              'Report Civic Issues Easily',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 40),

            // Report Issue Button
            ElevatedButton(
              onPressed: () {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => const ReportIssueScreen(),
    ),
  );
},

              child: const Text('Report an Issue'),
            ),
            const SizedBox(height: 15),

            // View Issues Button
            OutlinedButton(
              onPressed: () {
                // later: navigate to issue list
              },
              child: const Text('View Reported Issues'),
            ),
          ],
        ),
      ),
    );
  }
}
