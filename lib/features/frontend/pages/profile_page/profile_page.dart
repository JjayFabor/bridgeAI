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

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final profileData = userProvider.profileData;

    return Scaffold(
      backgroundColor: Colors.grey.shade200,
      body: Center(
        child: profileData == null
            ? const CircularProgressIndicator()
            : Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    colors: [Colors.blueGrey.shade50, Colors.white],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.5),
                      spreadRadius: 5,
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundImage: profileData['profile_picture'] != null
                          ? NetworkImage(profileData['profile_picture'])
                          : null,
                      backgroundColor: const Color.fromARGB(255, 88, 83, 83),
                      onBackgroundImageError:
                          profileData['profile_picture'] != null
                              ? (_, __) {
                                  logger.e("Failed to load profile picture.");
                                }
                              : null,
                      child: profileData['profile_picture'] == null
                          ? Text(
                              _getInitials(profileData['username']),
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 54),
                            )
                          : null,
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        elevation: 10,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        foregroundColor: Colors.blueAccent,
                        shadowColor: Colors.black45,
                      ),
                      onPressed: _uploadProfilePicture,
                      child: _isLoading
                          ? const CircularProgressIndicator(
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            )
                          : const Text('Upload Profile Picture'),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Name: ${profileData['name']}',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Age: ${profileData['age']}',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Grade: ${profileData['grade']}',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Country: ${profileData['country']}',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Username: ${profileData['username']}',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Email: ${profileData['email']}',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      _errorMessage,
                      style: const TextStyle(
                          color: Colors.red, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  String _getInitials(String username) {
    List<String> names = username.split(' ');
    String initials = '';
    for (var name in names) {
      initials += name[0];
    }
    return initials.toUpperCase();
  }
}
