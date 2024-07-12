import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logger/logger.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../global/provider_implementation/country_provider.dart';
import '../../../../global/provider_implementation/user_provider.dart';
import 'package:bridgeai/features/frontend/widgets/form_container_widget.dart';
import 'package:bridgeai/features/frontend/widgets/country_dropdown_widget.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  User? _user;
  String _errorMessage = '';

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _gradeController = TextEditingController();
  final TextEditingController _countryController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  final Logger logger = Logger();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _getUserProfile();
    });
  }

  Future<void> _getUserProfile() async {
    _user = FirebaseAuth.instance.currentUser;
    if (_user != null) {
      try {
        logger.i("Fetching profile for UID: ${_user!.uid}");
        final DocumentSnapshot userProfileSnapshot = await FirebaseFirestore
            .instance
            .collection('profiles')
            .doc(_user!.uid)
            .get();

        if (userProfileSnapshot.exists) {
          Map<String, dynamic> profileData =
              userProfileSnapshot.data() as Map<String, dynamic>;
          if (mounted) {
            Provider.of<UserProvider>(context, listen: false)
                .setProfileData(profileData);

            setState(() {
              _nameController.text = profileData['name'] ?? '';
              _ageController.text = profileData['age']?.toString() ?? '';
              _gradeController.text = profileData['grade']?.toString() ?? '';
              _countryController.text = profileData['country'] ?? '';
              _usernameController.text = profileData['username'] ?? '';
              _emailController.text = _user!.email ?? '';
            });

            SharedPreferences prefs = await SharedPreferences.getInstance();
            await prefs.setString('username', profileData['username']);
          }
        } else {
          logger.e("Profile not found for UID: ${_user!.uid}");
          setState(() {
            _errorMessage = "Profile not found.";
          });
        }
      } catch (e) {
        logger.e("Error fetching profile: $e");
        setState(() {
          _errorMessage = "Error fetching profile: $e";
        });
      }
    }
  }

  Future<void> _saveProfile() async {
    if (_user != null) {
      try {
        await FirebaseFirestore.instance
            .collection('profiles')
            .doc(_user!.uid)
            .update({
          'name': _nameController.text,
          'age': int.parse(_ageController.text),
          'grade': int.parse(_gradeController.text),
          'country': _countryController.text,
          'username': _usernameController.text,
          'email': _emailController.text,
        });

        if (mounted) {
          Provider.of<UserProvider>(context, listen: false).setProfileData({
            'name': _nameController.text,
            'age': int.parse(_ageController.text),
            'grade': int.parse(_gradeController.text),
            'country': _countryController.text,
            'username': _usernameController.text,
            'email': _emailController.text,
            'profile_picture': Provider.of<UserProvider>(context, listen: false)
                .profileData!['profile_picture'],
          });

          setState(() {
            Navigator.pop(context);
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _errorMessage = 'An error occurred while saving the profile: $e';
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
      ),
      body: Center(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          padding: const EdgeInsets.all(30),
          decoration: BoxDecoration(
            color: const Color.fromARGB(255, 88, 83, 83),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.5),
                spreadRadius: 5,
                blurRadius: 7,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Form(
            key: GlobalKey<FormState>(),
            child: ListView(
              shrinkWrap: true,
              children: [
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
                    hintText: _countryController.text.isEmpty
                        ? 'Select your country'
                        : _countryController.text,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please select a country';
                      }
                      return null;
                    },
                  );
                }),
                FormContainerWidget(
                  hintText: "Username",
                  hintStyle: GoogleFonts.aBeeZee(
                      textStyle: const TextStyle(color: Colors.black45)),
                  controller: _usernameController,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Username is required';
                    }
                    return null;
                  },
                ),
                FormContainerWidget(
                  hintText: "Email",
                  hintStyle: GoogleFonts.aBeeZee(
                      textStyle: const TextStyle(color: Colors.black45)),
                  controller: _emailController,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Email is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 70),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    elevation: 10,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  onPressed: _saveProfile,
                  child: Text(
                    'Save',
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
                const SizedBox(height: 10),
                Text(
                  _errorMessage,
                  style: const TextStyle(color: Colors.red),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
