import 'package:bridgeai/features/user_auth/firebase_auth_implementation/firebase_aut_services.dart';
import 'package:bridgeai/features/frontend/pages/login_page/login_screen.dart';
import 'package:bridgeai/features/frontend/widgets/form_container_widget.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'create_profile_screen.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  bool _isSignUp = false;
  final FirebaseAuthServices _auth = FirebaseAuthServices();

  final TextEditingController _userController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _userController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool _isValidEmail(String email) {
    // Regular expression for validating an Email
    String p = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,4}$';
    RegExp regExp = RegExp(p);
    return regExp.hasMatch(email);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          color: Color(0xFF008DDA),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height,
              ),
              child: IntrinsicHeight(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Column(
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      const SizedBox(height: 114),
                      Center(
                        child: Text(
                          'Create your Account',
                          style: GoogleFonts.rammettoOne(
                            textStyle: const TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 50),
                      FormContainerWidget(
                        controller: _userController,
                        hintText: "Username",
                        isPasswordField: false,
                      ),
                      const SizedBox(height: 10),
                      FormContainerWidget(
                        controller: _emailController,
                        hintText: "Email",
                        isPasswordField: false,
                      ),
                      const SizedBox(height: 10),
                      FormContainerWidget(
                        controller: _passwordController,
                        hintText: "Password",
                        isPasswordField: true,
                      ),
                      const SizedBox(height: 20),
                      Column(
                        children: [
                          ElevatedButton(
                            onPressed: _signUp,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFACE2E1), // Button color
                              foregroundColor: Colors.black, // Text color
                              fixedSize: const Size(207, 51), // Button Size
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.all(Radius.circular(10)),
                              ),
                            ),
                            child: _isSignUp
                                ? const CircularProgressIndicator(color: Colors.white)
                                : Text(
                                    'Sign Up',
                                    style: GoogleFonts.mitr(
                                      textStyle: const TextStyle(
                                        fontSize: 26,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                          ),
                          const SizedBox(height: 5),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                "Already have an account?",
                                style: TextStyle(color: Colors.white),
                              ),
                              const SizedBox(width: 5),
                              GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const LoginScreen(),
                                    ),
                                  );
                                },
                                child: Text(
                                  'Login',
                                  style: GoogleFonts.mitr(
                                    textStyle: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 50), // Space at the bottom
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _signUp() async {
    setState(() {
      _isSignUp = true;
    });

    String email = _emailController.text;
    String password = _passwordController.text;
    String username = _userController.text;

    if (!_isValidEmail(email)) {
      showAlertDialog(context, "Please enter a valid email address.");
      setState(() {
        _isSignUp = false;
      });
      return;
    }

    User? user = await _auth.signUpWithEmailandPassword(email, password);

    setState(() {
      _isSignUp = false;
    });

    if (mounted) {
      if (user != null) {
        if (!user.emailVerified) {
          await user.sendEmailVerification(); // Send verification email
          if (mounted) {
            showAlertDialog(
                context,
                "A verification email has been sent to $email. "
                "Please verify your email.");
          }
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CreateProfileScreen(
                username: username,
                email: email,
                password: password,
              ),
            ),
          );
        }
      } else {
        showAlertDialog(context, "An unknown error occurred. Please try again!");
      }
    }
  }
}

void showAlertDialog(BuildContext context, String message) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('Alert'),
        content: Text(message),
        actions: <Widget>[
          TextButton(
            child: const Text('OK'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      );
    },
  );
}