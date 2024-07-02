import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import '../../../../global/provider_implementation/user_provider.dart';
import 'subject_topics_page.dart';
import 'add_subject_page.dart';

class HomepageDashboard extends StatefulWidget {
  const HomepageDashboard({super.key});

  @override
  State<HomepageDashboard> createState() => _HomepageDashboardState();
}

class _HomepageDashboardState extends State<HomepageDashboard> {
  late User? _user;
  List<String> subjects = [];
  Map<String, List<String>> subjectTopics = {};
  Set<String> loadingSubjects = {};
  final Logger logger = Logger();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _loadSubjects();
    fetchProfile();
  }

  Future<void> _loadSubjects() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      subjects = prefs.getStringList('subjects') ?? [];
      final String? storedSubjectTopics = prefs.getString('subjectTopics');
      if (storedSubjectTopics != null) {
        final Map<String, dynamic> decodedTopics =
            json.decode(storedSubjectTopics);
        subjectTopics = decodedTopics
            .map((key, value) => MapEntry(key, List<String>.from(value)));
      }
    });
  }

  Future<void> _saveSubjects() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setStringList('subjects', subjects);
    prefs.setString('subjectTopics', json.encode(subjectTopics));
  }

  Future<void> _removeSubject(String subject) async {
    if (_user != null) {
      // Remove subject from Firestore
      DocumentReference subjectRef = _firestore
          .collection('profiles')
          .doc(_user!.uid)
          .collection('subjects')
          .doc(subject);
      await subjectRef.delete();
    }

    setState(() {
      subjects.remove(subject);
      subjectTopics.remove(subject);
    });
    _saveSubjects();
  }

  Future<void> _clearCachedSubjects() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('subjects');
    await prefs.remove('subjectTopics');
    setState(() {
      subjects = [];
      subjectTopics = {};
    });
  }

  Future<void> _storeLastUserId(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('lastUserId', userId);
  }

  Future<String?> _getLastUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('lastUserId');
  }

  Future<void> fetchProfile() async {
    _user = FirebaseAuth.instance.currentUser;
    if (_user != null) {
      String? lastUserId = await _getLastUserId();
      if (lastUserId != _user!.uid) {
        await _clearCachedSubjects();
        await _storeLastUserId(_user!.uid);
      }
      
      // Now fetch and load the profile as before
      if (mounted) {
        Map<String, dynamic>? profileData =
            Provider.of<UserProvider>(context, listen: false).profileData;
        if (profileData != null) {
          String? name = profileData['name'];
          int? age = profileData['age'];
          int? grade = profileData['grade'];
          String? country = profileData['country'];
          String? userId = profileData['userId'];
          String? email = profileData['email'];
          String? password = profileData['password'];
          String? username = profileData['username'];

          logger.i(
              'Fetched topics for $name $age $grade $country $email $password $username $userId');

          for (String subject in subjects) {
            await fetchTopicsForSubject(subject);
          }
        } else {
          logger.i('profileData is null');
        }
      }
    }
  }

  Future<void> fetchTopicsForSubject(String subject) async {
    if (subjectTopics.containsKey(subject) &&
        subjectTopics[subject]!.isNotEmpty) {
      return;
    }

    setState(() {
      loadingSubjects.add(subject);
    });

    Map<String, dynamic>? profileData =
        Provider.of<UserProvider>(context, listen: false).profileData;

    if (profileData != null) {
      String? name = profileData['name'];
      int? age = profileData['age'];
      int? grade = profileData['grade'];
      String? country = profileData['country'];

      final response = await http.get(
        Uri.parse('http://10.0.2.2:5000/generate-topics')
            .replace(queryParameters: {
          'name': name,
          'age': age.toString(),
          'grade': grade.toString(),
          'country': country,
          'subject': subject,
        }),
      );

      if (response.statusCode == 200) {
        logger.i(response.body);
        final decodedResponse = json.decode(response.body);
        List<String> topics = List<String>.from(decodedResponse['topics']);
        if (mounted) {
          setState(() {
            subjectTopics[subject] = topics;
            loadingSubjects.remove(subject);
          });
          await _saveSubjects();
          await _saveTopicsToFirestore(
              subject, topics); // Save topics to Firestore
        }
      } else {
        logger.i('Failed to load topics for $subject');
        setState(() {
          loadingSubjects.remove(subject);
        });
      }
    } else {
      logger.i('profileData is null');
      setState(() {
        loadingSubjects.remove(subject);
      });
    }
  }

  Future<void> _saveTopicsToFirestore(
      String subject, List<String> topics) async {
    if (_user != null) {
      DocumentReference subjectRef = _firestore
          .collection('profiles')
          .doc(_user!.uid)
          .collection('subjects')
          .doc(subject);
      for (String topic in topics) {
        await subjectRef.collection('topics').doc(topic).set({
          'name': topic,
        });
      }
    }
  }

  Future<void> _addSubjectToFirestore(String subject) async {
    if (_user != null) {
      DocumentReference userRef =
          _firestore.collection('profiles').doc(_user!.uid);
      await userRef.collection('subjects').doc(subject).set({
        'progress': 0,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueAccent,
      body: Padding(
        padding: const EdgeInsets.all(25.0),
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              ...subjects.map((subject) {
                final isLoading = loadingSubjects.contains(subject);
                return ElevatedButton(
                  onPressed: isLoading
                      ? null
                      : () {
                          logger.i("Clicked on $subject");
                          _navigateToSubjectTopicScreen(context, subject);
                        },
                  onLongPress: isLoading
                      ? null
                      : () {
                          _confirmDeleteSubject(context, subject);
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    fixedSize: const Size(175, 175),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    shadowColor: Colors.black26,
                    elevation: 5,
                  ),
                  child: isLoading
                      ? const CircularProgressIndicator()
                      : Text(subject,
                          style: GoogleFonts.cormorant(
                            textStyle: const TextStyle(
                              fontSize: 24,
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                          )),
                );
              }),
              ElevatedButton(
                onPressed: () {
                  _navigateToAddSubjectScreen(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  fixedSize: const Size(175, 175),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  shadowColor: Colors.black26,
                  elevation: 5,
                ),
                child: const Icon(
                  Icons.add,
                  color: Colors.black,
                  size: 70,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToAddSubjectScreen(BuildContext context) async {
    final newSubject = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AddSubjectPage()),
    );

    if (newSubject != null) {
      if (!subjects.contains(newSubject)) {
        setState(() {
          subjects.add(newSubject);
          subjectTopics[newSubject] = [];
        });
        await fetchTopicsForSubject(newSubject); // fetch topic for new subject
        await _addSubjectToFirestore(newSubject); // add subject to Firestore
        if (mounted) {
          _saveSubjects();
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Subject "$newSubject" already exists.')),
          );
        }
      }
    }
  }

  void _navigateToSubjectTopicScreen(
      BuildContext context, String subject) async {
    await fetchTopicsForSubject(subject);
    final topics = subjectTopics[subject] ?? [];
    if (context.mounted) {
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) =>
                  SubjectTopicsPage(subject: subject, topics: topics)));
    }
  }

  void _confirmDeleteSubject(BuildContext context, String subject) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Subject'),
          content: Text('Are you sure you want to delete "$subject"?'),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Delete'),
              onPressed: () async {
                await _removeSubject(subject);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
