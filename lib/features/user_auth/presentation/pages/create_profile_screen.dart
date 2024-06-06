// ignore_for_file: use_build_context_synchronously

import 'package:bridgeai/features/user_auth/presentation/pages/home_page.dart';
import 'package:bridgeai/features/user_auth/presentation/widgets/form_container_widget.dart';
import 'package:bridgeai/global/common/toast.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

class CreateProfileScreen extends StatefulWidget {
  const CreateProfileScreen({super.key});

  @override
  State<CreateProfileScreen> createState() => _CreateProfileScreenState();
}

class _CreateProfileScreenState extends State<CreateProfileScreen> {
  //bool _isCreated = false;
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _gradeController = TextEditingController();
  final TextEditingController _countryController = TextEditingController();
  String _errorMessage = "";

  Future<void> _saveProfile() async {
    if (_formKey.currentState?.validate() ?? false) {
      try {
        // Ensure the user is authenticated
        User? user = FirebaseAuth.instance.currentUser;
        if (user == null) {
          setState(() {
            _errorMessage = 'You must be sign up to create a profile.';
          });
          return;
        }

        await FirebaseFirestore.instance.collection('profiles').add({
          'name': _nameController.text,
          'age': int.parse(_ageController.text),
          'grade': int.parse(_gradeController.text),
          'country': _countryController.text,
          'userId': user.uid, // Associate the profile with the user
        });
        showToast(message: "Profile created successfully");
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const HomePage()),
        );
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
                    style: GoogleFonts.rammettoOne(
                      textStyle: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(
                  height: 15,
                ),
                FormContainerWidget(
                  hintText: "Name",
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
                    style: GoogleFonts.mitr(
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
