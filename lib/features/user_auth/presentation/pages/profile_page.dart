import 'dart:io';

import 'package:bridgeai/features/user_auth/presentation/pages/login_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late User? _user;
  Map<String, dynamic>? _profileData;
  String _errorMessage = '';
  bool _isLoading = false;
  bool _isEditing = false;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _gradeController = TextEditingController();
  final TextEditingController _countryController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _getUserProfile();
  }

  Future<void> _getUserProfile() async {
    _user = FirebaseAuth.instance.currentUser;
    if (_user != null) {
      try {
        final QuerySnapshot userProfileSnapshot =
            await FirebaseFirestore.instance.collection('profiles').get();

        if (userProfileSnapshot.docs.isNotEmpty) {
          setState(() {
            _profileData =
                userProfileSnapshot.docs.first.data() as Map<String, dynamic>;
          });
        } else {
          setState(() {
            _errorMessage = 'Profile not found';
          });
        }
      } catch (e) {
        setState(() {
          _errorMessage = 'An error occurred while fetching the profile: $e';
        });
      }
    } else {
      setState(() {
        _errorMessage = 'User not logged in';
      });
    }
  }

  Future<void> _uploadProfilePicture() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _isLoading = true;
      });

      File file = File(pickedFile.path);
      try {
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('profile_pictures')
            .child('${_user!.uid}.jpg');
        await storageRef.putFile(file);
        String downloadUrl = await storageRef.getDownloadURL();

        await FirebaseFirestore.instance
            .collection('profiles')
            .doc(_profileData!['userId'])
            .update({'profile_picture': downloadUrl});

        setState(() {
          _profileData!['profile_picture'] = downloadUrl;
        });
      } catch (e) {
        setState(() {
          _errorMessage =
              'An error occurred while uploading the profile picture: $e';
        });
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _saveProfile() async {
    if (_user != null) {
      try {
        await FirebaseFirestore.instance
            .collection('profiles')
            .doc(_profileData!['userId'])
            .update({
          'name': _nameController.text,
          'age': int.parse(_ageController.text),
          'grade': int.parse(_gradeController.text),
          'country': _countryController.text,
        });
        setState(() {
          _profileData!['name'] = _nameController.text;
          _profileData!['age'] = int.parse(_ageController.text);
          _profileData!['grade'] = int.parse(_gradeController.text);
          _profileData!['country'] = _countryController.text;
          _isEditing = false;
        });
      } catch (e) {
        setState(() {
          _errorMessage = 'An error occurred while saving the profile: $e';
        });
      }
    }
  }

  void _logout() async {
    await FirebaseAuth.instance.signOut();
    // ignore: use_build_context_synchronously
    Navigator.push(
      // ignore: use_build_context_synchronously
      context,
      MaterialPageRoute(
        builder: (context) => const LoginScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          backgroundColor: Colors.blueAccent,
          toolbarHeight: 100,
          automaticallyImplyLeading: false,
          title: Text('Profile',
              style: GoogleFonts.rammettoOne(
                  textStyle: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ))),
          actions: [
            IconButton(
                icon: const Icon(Icons.settings, size: 35),
                onPressed: () {
                  // Navigate to settings page
                },
                tooltip: 'Settings'),
            IconButton(
              icon: const Icon(Icons.logout, size: 35),
              onPressed: _logout,
              tooltip: 'Logout',
            )
          ]),
      backgroundColor: Colors.blueAccent,
      body: Center(
        child: _profileData != null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_profileData!['profile_picture'] != null)
                    CircleAvatar(
                      backgroundImage:
                          NetworkImage(_profileData!['profile_picture']),
                      radius: 50,
                    )
                  else
                    const CircleAvatar(
                      radius: 75,
                      child: Icon(
                        Icons.person,
                        size: 150,
                      ),
                    ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _uploadProfilePicture,
                    child: _isLoading
                        ? const CircularProgressIndicator()
                        : const Text('Upload Profile Picture'),
                  ),
                  const SizedBox(height: 20),
                  if (_isEditing)
                    Column(
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
                          decoration:
                              const InputDecoration(labelText: 'Grade Level'),
                          keyboardType: TextInputType.number,
                        ),
                        TextField(
                          controller: _countryController,
                          decoration:
                              const InputDecoration(labelText: 'Country'),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: _saveProfile,
                          child: const Text('Save'),
                        ),
                      ],
                    )
                  else
                    Column(
                      children: [
                        Text(
                          'Name: ${_profileData!['name']}',
                          style: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Age: ${_profileData!['age']}',
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Grade Level: ${_profileData!['grade']}',
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Country: ${_profileData!['country']}',
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _isEditing = true;
                            });
                          },
                          child: const Text('Edit Profile'),
                        ),
                      ],
                    ),
                  const SizedBox(height: 20),
                  Text(
                    _errorMessage,
                    style: const TextStyle(color: Colors.red),
                  ),
                ],
              )
            : Text(_errorMessage.isEmpty ? 'Loading...' : _errorMessage),
      ),
    );
  }
}
