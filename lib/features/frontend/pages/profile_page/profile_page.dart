import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:logger/logger.dart';
import 'dart:io';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../global/provider_implementation/user_provider.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  User? _user;
  String _errorMessage = '';
  bool _isLoading = false;
  bool _isEditing = false;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _gradeController = TextEditingController();
  final TextEditingController _countryController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

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
            .doc(_user!.uid)
            .update({'profile_picture': downloadUrl});

        if (mounted) {
          Provider.of<UserProvider>(context, listen: false).setProfileData({
            ...Provider.of<UserProvider>(context, listen: false).profileData!,
            'profile_picture': downloadUrl
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _errorMessage =
                'An error occurred while uploading the profile picture: $e';
          });
        }
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
            .doc(_user!.uid)
            .update({
          'name': _nameController.text,
          'age': int.parse(_ageController.text),
          'grade': int.parse(_gradeController.text),
          'country': _countryController.text,
          'username': _usernameController.text,
          'email': _emailController.text,
          'password': _passwordController.text,
        });

        if (mounted) {
          Provider.of<UserProvider>(context, listen: false).setProfileData({
            'name': _nameController.text,
            'age': int.parse(_ageController.text),
            'grade': int.parse(_gradeController.text),
            'country': _countryController.text,
            'username': _usernameController.text,
            'email': _emailController.text,
            'password': _passwordController.text,
            'profile_picture': Provider.of<UserProvider>(context, listen: false)
                .profileData!['profile_picture'],
          });

          setState(() {
            _isEditing = false;
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
    Map<String, dynamic>? profileData =
        Provider.of<UserProvider>(context).profileData;

    return Scaffold(
      backgroundColor: Colors.blueAccent,
      body: Center(
        child: profileData != null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (profileData['profile_picture'] != null)
                    CircleAvatar(
                      backgroundImage:
                          NetworkImage(profileData['profile_picture']),
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
                        TextField(
                          controller: _usernameController,
                          decoration:
                              const InputDecoration(labelText: 'Username'),
                        ),
                        TextField(
                          controller: _emailController,
                          decoration: const InputDecoration(labelText: 'Email'),
                        ),
                        TextField(
                          controller: _passwordController,
                          decoration:
                              const InputDecoration(labelText: 'Password'),
                          obscureText: true,
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
                          'Name: ${profileData['name']}',
                          style: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Age: ${profileData['age']}',
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Grade Level: ${profileData['grade']}',
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Country: ${profileData['country']}',
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Username: ${profileData['username']}',
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Email: ${profileData['email']}',
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Password: ${profileData['password']}',
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
