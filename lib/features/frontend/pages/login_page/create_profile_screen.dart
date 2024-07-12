import 'package:bridgeai/features/frontend/widgets/form_container_widget.dart';
import 'package:bridgeai/global/common/alert_dialog.dart';
import 'package:bridgeai/global/provider_implementation/country_provider.dart';
import 'package:bridgeai/global/provider_implementation/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../widgets/country_dropdown_widget.dart';
import '../dashboard_page/home_page.dart';

class CreateProfileScreen extends StatefulWidget {
  final String username;
  final String email;
  final String password;

  const CreateProfileScreen({
    super.key,
    required this.username,
    required this.email,
    required this.password,
  });

  @override
  State<CreateProfileScreen> createState() => _CreateProfileScreenState();
}

class _CreateProfileScreenState extends State<CreateProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _gradeController = TextEditingController();
  final TextEditingController _countryController = TextEditingController();
  String _errorMessage = "";

  @override
  void initState() {
    super.initState();
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState?.validate() ?? false) {
      try {
        User? user = FirebaseAuth.instance.currentUser;
        if (user == null) {
          setState(() {
            _errorMessage = 'You must be signed up to create a profile.';
          });
          return;
        }

        String userId = user.uid;

        await FirebaseFirestore.instance
            .collection('profiles')
            .doc(userId)
            .set({
          'name': _nameController.text,
          'age': int.parse(_ageController.text),
          'grade': int.parse(_gradeController.text),
          'country': _countryController.text,
          'email': widget.email,
          'username': widget.username,
          'password': widget.password,
          'userId': userId,
        });

        if (mounted) {
          Provider.of<UserProvider>(context, listen: false).setProfileData({
            'name': _nameController.text,
            'age': int.parse(_ageController.text),
            'grade': int.parse(_gradeController.text),
            'country': _countryController.text,
            'email': widget.email,
            'username': widget.username,
            'userId': userId,
          });
        }

        if (mounted) {
          showAlertDialog(context, "Profile created successfully");

          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const HomePage()),
          );
        }
      } catch (e) {
        setState(() {
          showAlertDialog(
              context, 'An error occurred while saving the profile: $e');
        });
      }
    }
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
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                const SizedBox(height: 50),
                Center(
                  child: Text(
                    'Create your Account',
                    style: GoogleFonts.rammettoOne(
                      textStyle: const TextStyle(
                        fontSize: 44,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            offset: Offset(3.0, 3.0),
                            blurRadius: 3.0,
                            color: Colors.black38,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 50),
                FormContainerWidget(
                  hintText: "Name",
                  hintStyle: GoogleFonts.aBeeZee(
                      textStyle: const TextStyle(color: Colors.black45)),
                  controller: _nameController,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Name is required';
                    }
                    return null;
                  },
                ),
                FormContainerWidget(
                  hintText: "Age",
                  hintStyle: GoogleFonts.aBeeZee(
                      textStyle: const TextStyle(color: Colors.black45)),
                  isIntegerField: true,
                  controller: _ageController,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Age is required';
                    }
                    if (int.tryParse(value) == null) {
                      return 'Enter a valid age';
                    }
                    return null;
                  },
                ),
                FormContainerWidget(
                  hintText: "Grade Level",
                  hintStyle: GoogleFonts.aBeeZee(
                      textStyle: const TextStyle(color: Colors.black45)),
                  controller: _gradeController,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Grade level is required';
                    }
                    return null;
                  },
                ),
                Consumer<CountryProvider>(
                    builder: (context, countryProvider, child) {
                  return CountryDropdownWidget(
                    controller: _countryController,
                    hintStyle: GoogleFonts.aBeeZee(
                        textStyle: const TextStyle(color: Colors.black45)),
                    hintText: 'Select your country',
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please select a country';
                      }
                      return null;
                    },
                  );
                }),
                const SizedBox(height: 20),
                Text(
                  _errorMessage,
                  style: const TextStyle(color: Colors.red),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _saveProfile,
                  style: ElevatedButton.styleFrom(
                    elevation: 5,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30.0),
                    ),
                    backgroundColor: const Color(0xFFACE2E1), // Button color
                    foregroundColor: Colors.black, // Text color
                    shadowColor: Colors.black45,
                  ),
                  child: Text(
                    'Save Profile',
                    style: GoogleFonts.cormorant(
                      textStyle: const TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
