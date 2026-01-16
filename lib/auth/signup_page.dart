import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Account')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Join Civic Reporter',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 30),

            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),

            ElevatedButton(
              onPressed: () async {
                // 1. Get Inputs
                final email = _emailController.text.trim();
                final password = _passwordController.text.trim();

                // 2. Quick Validation
                if (email.isEmpty || password.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text("⚠️ All fields are required"),
                    backgroundColor: Colors.red,
                  ));
                  return;
                }

                // 3. Show Loading Spinner
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => const Center(child: CircularProgressIndicator()),
                );

                try {
                  // 4. REAL FIREBASE CREATION
                  await FirebaseAuth.instance.createUserWithEmailAndPassword(
                    email: email,
                    password: password,
                  );

                  // 5. Success!
                  if (mounted) {
                    Navigator.pop(context); // Close loader
                    Navigator.pushReplacementNamed(context, '/dashboard');
                  }
                } on FirebaseAuthException catch (e) {
                  // 6. Handle Errors (e.g. Email already in use)
                  if (mounted) {
                    Navigator.pop(context); // Close loader
                    String message = "Sign up failed";
                    if (e.code == 'email-already-in-use') {
                      message = "That email is already registered.";
                    } else if (e.code == 'weak-password') {
                      message = "Password is too weak (use 6+ chars).";
                    } else if (e.code == 'invalid-email') {
                      message = "Invalid email format.";
                    }
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text("❌ $message"),
                      backgroundColor: Colors.red,
                    ));
                  }
                }
              },
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 14, horizontal: 40),
                child: Text('Create Account'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
