import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Controllers for email & password input
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;

  // ---------------- EMAIL LOGIN ----------------
  Future<void> loginWithEmail() async {
    setState(() => _isLoading = true);

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      showMessage('Login successful ✅');
    } on FirebaseAuthException catch (e) {
      showMessage(e.message ?? 'Login failed');
    }

    setState(() => _isLoading = false);
  }

  // ---------------- EMAIL SIGNUP ----------------
  Future<void> createAccount() async {
    setState(() => _isLoading = true);

    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      showMessage('Account created 🎉');
    } on FirebaseAuthException catch (e) {
      showMessage(e.message ?? 'Signup failed');
    }

    setState(() => _isLoading = false);
  }

  // ---------------- GOOGLE SIGN IN ----------------
  Future<void> loginWithGoogle() async {
    setState(() => _isLoading = true);

    try {
      final GoogleSignInAccount? googleUser =
          await GoogleSignIn().signIn();

      if (googleUser == null) {
        showMessage('Google sign-in cancelled');
        setState(() => _isLoading = false);
        return;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await FirebaseAuth.instance.signInWithCredential(credential);

      showMessage('Google login successful ✅');
    } catch (e) {
      showMessage('Google sign-in failed');
    }

    setState(() => _isLoading = false);
  }

  // ---------------- UI MESSAGE ----------------
  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  // ---------------- CLEANUP ----------------
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Email field
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 16),

                // Password field
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 24),

                // Loading indicator
                if (_isLoading)
                  const CircularProgressIndicator()
                else
                  Column(
                    children: [
                      // Login
                      ElevatedButton(
                        onPressed: loginWithEmail,
                        style: ElevatedButton.styleFrom(
                          minimumSize:
                              const Size(double.infinity, 48),
                        ),
                        child: const Text('Login'),
                      ),

                      const SizedBox(height: 10),

                      // Signup
                      OutlinedButton(
                        onPressed: createAccount,
                        style: OutlinedButton.styleFrom(
                          minimumSize:
                              const Size(double.infinity, 48),
                        ),
                        child: const Text('Create Account'),
                      ),

                      const SizedBox(height: 20),

                      // Google Sign-In
                      ElevatedButton.icon(
                        onPressed: loginWithGoogle,
                        icon: const Icon(Icons.login),
                        label:
                            const Text('Continue with Google'),
                        style: ElevatedButton.styleFrom(
                          minimumSize:
                              const Size(double.infinity, 48),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


