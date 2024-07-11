import 'package:bridgeai/features/frontend/widgets/form_container_widget.dart';
import 'package:bridgeai/global/common/alert_dialog.dart';
import 'package:bridgeai/global/provider_implementation/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'create_profile_screen.dart';
import 'forgot_password_page.dart';
import '../dashboard_page/home_page.dart';
import 'sign_up_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool isLogIn = false;
  bool isHovered = false;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String errorMessage = '';

  Future<void> _login() async {
    setState(() {
      isLogIn = true;
    });

    try {
      UserCredential userCredential =
          await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );

      User? user = userCredential.user;

      if (user != null) {
        await user.reload();
        if (user.emailVerified) {
          // Fetch the user profile data
          DocumentSnapshot userProfileSnapshot = await FirebaseFirestore
              .instance
              .collection('profiles')
              .doc(user.uid)
              .get();

          if (userProfileSnapshot.exists) {
            Map<String, dynamic> profileData =
                userProfileSnapshot.data() as Map<String, dynamic>;

            if (mounted) {
              Provider.of<UserProvider>(context, listen: false)
                  .setProfileData(profileData);

              // Navigate to the homepage dashboard
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const HomePage()),
              );
            }
          } else {
            if (mounted) {
              // Navigate to CreateProfileScreen if profile does not exist
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => CreateProfileScreen(
                    username: user.displayName ?? '',
                    email: user.email!,
                    password: '',
                  ),
                ),
              );
            }
          }
        } else {
          if (mounted) {
            showAlertDialog(
                context, "Please verify your email before logging in.");
            setState(() {
              isLogIn = false;
            });
          }
        }
      }
    } catch (e) {
      setState(() {
        showAlertDialog(context, 'Invalid Email or Password');
        isLogIn = false;
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color.fromARGB(255, 88, 83, 83),
              Color.fromARGB(255, 31, 29, 29)
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
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
                      const SizedBox(height: 100),
                      Text(
                        'Bridge AI',
                        style: GoogleFonts.rammettoOne(
                          textStyle: const TextStyle(
                            fontSize: 54,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            shadows: [
                              Shadow(
                                offset: Offset(3, 9),
                                blurRadius: 9,
                                color: Colors.white60,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 50),
                      Image.asset(
                        'assets/welcome.png',
                        width: 700,
                        height: 81,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(height: 70),
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              spreadRadius: 2,
                              blurRadius: 5,
                              offset: const Offset(0, 3),
                            ),
                          ],
                          color: Colors.white,
                        ),
                        child: FormContainerWidget(
                          controller: _emailController,
                          hintText: "Email",
                          hintStyle: GoogleFonts.aBeeZee(
                            textStyle: const TextStyle(color: Colors.black45),
                          ),
                          isPasswordField: false,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.white,
                              spreadRadius: 2,
                              blurRadius: 5,
                              offset: Offset(0, 3),
                            ),
                          ],
                          color: Colors.white,
                        ),
                        child: FormContainerWidget(
                          controller: _passwordController,
                          hintText: "Password",
                          hintStyle: GoogleFonts.aBeeZee(
                            textStyle: const TextStyle(color: Colors.black45),
                          ),
                          isPasswordField: true,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Align(
                        alignment: Alignment.centerRight,
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const ForgotPasswordPage(),
                              ),
                            );
                          },
                          child: Text(
                            'Forgot Password?',
                            style: GoogleFonts.aBeeZee(
                              textStyle: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                shadows: [
                                  Shadow(
                                    offset: Offset(1, 1),
                                    blurRadius: 1,
                                    color: Colors.black54,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 100),
                      Column(
                        children: [
                          MouseRegion(
                            onEnter: (_) {
                              setState(() {
                                isHovered = true;
                              });
                            },
                            onExit: (_) {
                              setState(() {
                                isHovered = false;
                              });
                            },
                            child: ElevatedButton(
                              onPressed: isLogIn ? null : _login,
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    isHovered ? Colors.grey : Colors.white,
                                foregroundColor: Colors.black,
                                fixedSize: const Size(207, 51),
                                shape: const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(10),
                                  ),
                                ),
                                elevation: 5,
                                shadowColor: Colors.white60,
                              ),
                              child: isLogIn
                                  ? const CircularProgressIndicator(
                                      color: Colors.white,
                                    )
                                  : Text(
                                      'Login',
                                      style: GoogleFonts.cormorant(
                                        textStyle: const TextStyle(
                                          fontSize: 28,
                                          fontWeight: FontWeight.w900,
                                          shadows: [
                                            Shadow(
                                              offset: Offset(2, 2),
                                              blurRadius: 3,
                                              color: Colors.black54,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "Don't have an account?",
                                style: GoogleFonts.aBeeZee(
                                  textStyle: const TextStyle(
                                    fontSize: 18,
                                    color: Colors.white70,
                                    shadows: [
                                      Shadow(
                                        offset: Offset(1, 1),
                                        blurRadius: 1,
                                        color: Colors.black54,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 5),
                              GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const SignUpScreen(),
                                    ),
                                  );
                                },
                                child: Text(
                                  'Sign Up',
                                  style: GoogleFonts.cormorant(
                                    textStyle: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                      shadows: [
                                        Shadow(
                                          offset: Offset(2, 2),
                                          blurRadius: 4,
                                          color: Colors.white,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              )
                            ],
                          ),
                          const SizedBox(height: 50),
                        ],
                      ),
                      const SizedBox(height: 20),
                      if (errorMessage.isNotEmpty)
                        Text(
                          errorMessage,
                          style: const TextStyle(color: Colors.red),
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
}
