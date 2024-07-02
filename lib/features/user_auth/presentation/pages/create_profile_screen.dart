import 'package:bridgeai/features/user_auth/presentation/widgets/form_container_widget.dart';
import 'package:bridgeai/global/common/toast.dart';
import 'package:bridgeai/global/provider_implementation/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'home_page.dart';

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
        // Ensure the user is authenticated
        User? user = FirebaseAuth.instance.currentUser;
        if (user == null) {
          setState(() {
            _errorMessage = 'You must be signed up to create a profile.';
          });
          return;
        }

        String userId = user.uid; // Get the current user's UID

        // Use userId as the document ID
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

        // Save the profile data to the provider
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

        showToast(message: "Profile created successfully");
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const HomePage()),
          );
        }
      } catch (e) {
        setState(() {
          _errorMessage = 'An error occurred while saving the profile: $e';
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
          color: Color(0xFF008DDA),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                const SizedBox(height: 15),
                Center(
                  child: Text(
                    'Create your Account',
                    style: GoogleFonts.cormorant(
                      textStyle: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 15),
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
                const SizedBox(height: 5),
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
                const SizedBox(height: 5),
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
                const SizedBox(height: 5),
                FormContainerWidget(
                  hintText: "Country",
                  hintStyle: GoogleFonts.aBeeZee(
                      textStyle: const TextStyle(color: Colors.black45)),
                  controller: _countryController,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Country is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 5),
                Text(
                  _errorMessage,
                  style: const TextStyle(color: Colors.red),
                ),
                const SizedBox(height: 5),
                ElevatedButton(
                  onPressed: _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFACE2E1), // Button color
                    foregroundColor: Colors.black, // Text color
                  ),
                  child: Text(
                    'Save Profile',
                    style: GoogleFonts.cormorant(
                      textStyle: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
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
