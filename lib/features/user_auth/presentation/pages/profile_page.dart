import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../../global/user_provider_implementation/user_provider.dart';
import 'homepage_dashboard.dart';
import 'package:provider/provider.dart';
import 'login_screen.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late User? _user;
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
          Map<String, dynamic> profileData =
              userProfileSnapshot.docs.first.data() as Map<String, dynamic>;
          if (mounted) {
            Provider.of<UserProvider>(context, listen: false)
                .setProfileData(profileData);

            setState(() {
              _nameController.text = profileData['name'];
              _ageController.text = profileData['age'].toString();
              _gradeController.text = profileData['grade'].toString();
              _countryController.text = profileData['country'];
            });

            print("Profile data set in UserProvider: $profileData");
          }
        } else {
          if (mounted) {
            setState(() {
              _errorMessage = 'Profile not found';
            });
          }
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
        });

        if (mounted) {
          Provider.of<UserProvider>(context, listen: false).setProfileData({
            'name': _nameController.text,
            'age': int.parse(_ageController.text),
            'grade': int.parse(_gradeController.text),
            'country': _countryController.text,
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

  void _logout() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => const LoginScreen(),
        ),
        (route) => false,
      );
    }
  }

  void _navigateToDashboard(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const HomepageDashboard(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Map<String, dynamic>? profileData =
        Provider.of<UserProvider>(context).profileData;

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
        // ignore: unnecessary_null_comparison
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
                  ElevatedButton(
                    onPressed: () => _navigateToDashboard(context),
                    child: const Text('Go to Dashboard'),
                  ),
                ],
              )
            : Text(_errorMessage.isEmpty ? 'Loading...' : _errorMessage),
      ),
    );
  }
}
