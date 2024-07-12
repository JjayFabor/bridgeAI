import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logger/logger.dart';
import '../../../../global/provider_implementation/user_provider.dart';

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
          // 'password': _passwordController.text,
        });

        if (mounted) {
          Provider.of<UserProvider>(context, listen: false).setProfileData({
            'name': _nameController.text,
            'age': int.parse(_ageController.text),
            'grade': int.parse(_gradeController.text),
            'country': _countryController.text,
            'username': _usernameController.text,
            'email': _emailController.text,
            // 'password': _passwordController.text,
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
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
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
          child: Column(
            children: [
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              TextField(
                controller: _ageController,
                decoration: const InputDecoration(labelText: 'Age'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: _gradeController,
                decoration: const InputDecoration(labelText: 'Grade Level'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: _countryController,
                decoration: const InputDecoration(labelText: 'Country'),
              ),
              TextField(
                controller: _usernameController,
                decoration: const InputDecoration(labelText: 'Username'),
              ),
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  elevation: 10,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                onPressed: _saveProfile,
                child: const Text('Save'),
              ),
              const SizedBox(height: 20),
              Text(
                _errorMessage,
                style: const TextStyle(color: Colors.red),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
