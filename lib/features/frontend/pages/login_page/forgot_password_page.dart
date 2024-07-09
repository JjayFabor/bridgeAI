import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final TextEditingController _emailController = TextEditingController();
  String message = '';

  Future<void> _sendPasswordResetEmail() async {
    try {
      final email = _emailController.text;

      // Check if the email is registered
      final list =
          // ignore: deprecated_member_use
          await FirebaseAuth.instance.fetchSignInMethodsForEmail(email);
      if (list.isEmpty) {
        setState(() {
          message = 'This email is not registered in our system.';
        });
        return;
      }

      // Send the password reset email
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);

      setState(() {
        message = 'Password reset link has been sent to your email.';
      });
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        setState(() {
          message = 'This email is not registered in our system.';
        });
      } else {
        setState(() {
          message = 'An error occurred: ${e.message}';
        });
      }
    } catch (e) {
      setState(() {
        message = 'An unexpected error occurred: $e';
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Forgot Password', style: GoogleFonts.cormorant()),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'Email',
                labelStyle: GoogleFonts.aBeeZee(),
                border: const OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _sendPasswordResetEmail,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF008DDA),
                foregroundColor: Colors.white,
              ),
              child: Text('Send Password Reset Email',
                  style: GoogleFonts.cormorant()),
            ),
            const SizedBox(height: 20),
            if (message.isNotEmpty)
              Text(
                message,
                style: TextStyle(
                  color: message.contains('error') ||
                          message.contains('not registered')
                      ? Colors.red
                      : Colors.green,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
