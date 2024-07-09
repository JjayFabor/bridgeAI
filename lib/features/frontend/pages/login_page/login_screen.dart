import 'package:bridgeai/features/frontend/widgets/form_container_widget.dart';
import 'package:bridgeai/global/provider_implementation/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:google_sign_in/google_sign_in.dart';
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
        // Fetch the user profile data
        DocumentSnapshot userProfileSnapshot = await FirebaseFirestore.instance
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
            setState(() {
              // errorMessage = 'Profile not found';
              showAlertDialog(context, 'Profile not found');
              isLogIn = false;
            });
          }
        }
      }
    } catch (e) {
      setState(() {
        // errorMessage = 'Invalid Email or Password';
        showAlertDialog(context, 'Invalid Email or Password');
        isLogIn = false;
      });
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      isLogIn = true;
    });

    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      final GoogleSignInAuthentication googleAuth =
          await googleUser!.authentication;

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);

      User? user = userCredential.user;

      if (user != null) {
        // Fetch the user profile data
        DocumentSnapshot userProfileSnapshot = await FirebaseFirestore.instance
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
                  username: googleUser.displayName ?? '',
                  email: googleUser.email,
                  password: '',
                ),
              ),
            );
          }
        }
      }
    } catch (e) {
      setState(() {
        //errorMessage = 'An error occurred while signing in with Google: $e';
        showAlertDialog(
            context, 'An error occurred while signing in with Google: $e');
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
                      Text(
                        'Bridge AI',
                        style: GoogleFonts.cormorant(
                          textStyle: const TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 70),
                      Image.asset(
                        'assets/welcome.png', // Path to your image
                        width: 700,
                        height: 81,
                        fit: BoxFit.contain, // BoxFit property to fit the image
                      ),
                      const SizedBox(height: 50),
                      FormContainerWidget(
                        controller: _emailController,
                        hintText: "Email",
                        hintStyle: GoogleFonts.aBeeZee(
                            textStyle: const TextStyle(color: Colors.black45)),
                        isPasswordField: false,
                      ),
                      const SizedBox(height: 10),
                      FormContainerWidget(
                        controller: _passwordController,
                        hintText: "Password",
                        hintStyle: GoogleFonts.aBeeZee(
                            textStyle: const TextStyle(color: Colors.black45)),
                        isPasswordField: true,
                      ),
                      const SizedBox(height: 1),
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
                                color: Colors.black,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Column(
                        children: [
                          ElevatedButton(
                            onPressed: isLogIn ? null : _login,
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  const Color(0xFFACE2E1), // Button color
                              foregroundColor: Colors.black, // Text color
                              fixedSize: const Size(207, 51), // Button Size
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.all(
                                  Radius.circular(10),
                                ),
                              ),
                            ),
                            child: isLogIn
                                ? const CircularProgressIndicator(
                                    color: Colors.white,
                                  )
                                : Text(
                                    'Login',
                                    style: GoogleFonts.cormorant(
                                      textStyle: const TextStyle(
                                        fontSize: 26,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                          ),
                          const SizedBox(height: 10),
                          ElevatedButton(
                            onPressed: isLogIn ? null : _signInWithGoogle,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white, // Button color
                              foregroundColor: Colors.black, // Text color
                              fixedSize: const Size(207, 51), // Button Size
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.all(
                                  Radius.circular(10),
                                ),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'Sign in with Google',
                                    style: GoogleFonts.cormorant(
                                      textStyle: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 5),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text("Don't have an account?",
                                  style: GoogleFonts.aBeeZee(
                                      textStyle: const TextStyle(
                                    color: Colors.white,
                                  ))),
                              const SizedBox(
                                width: 5,
                              ),
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
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              )
                            ],
                          ),
                          const SizedBox(height: 50), // Space at the bottom
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
