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
    if (mounted) {
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
  }

  Future<void> _saveSubjects() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setStringList('subjects', subjects);
    prefs.setString('subjectTopics', json.encode(subjectTopics));
  }

  Future<void> _removeSubject(String subject) async {
    if (_user != null) {
      final userId = _user!.uid;
      // Remove subject and its topics from local storage
      setState(() {
        subjects.remove(subject);
        subjectTopics.remove(subject);
      });
      await _saveSubjects();
      await _removeSubjectFromFirestore(subject);
      await _removeSubjectProgressCache(
          subject, userId); // Delete the cached progress data
    }
  }

  Future<void> _removeSubjectFromFirestore(String subject) async {
    if (_user != null) {
      DocumentReference userRef =
          _firestore.collection('profiles').doc(_user!.uid);
      DocumentReference subjectRef =
          userRef.collection('subjects').doc(subject);

      final topicSnapshots = await subjectRef.collection('topics').get();
      for (var topicDoc in topicSnapshots.docs) {
        final lessonSnapshots =
            await topicDoc.reference.collection('lessons').get();
        for (var lessonDoc in lessonSnapshots.docs) {
          await lessonDoc.reference.delete();
        }
        await topicDoc.reference.delete();
      }
      await subjectRef.delete();
    }
  }

  Future<void> _clearCachedSubjects() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('subjects');
    await prefs.remove('subjectTopics');
    if (mounted) {
      setState(() {
        subjects = [];
        subjectTopics = {};
      });
    }
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

    if (mounted) {
      setState(() {
        loadingSubjects.add(subject);
      });
    }

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
              subject, topics); // Ensure the unlocked field is set
        }
      } else {
        logger.i('Failed to load topics for $subject');
        if (mounted) {
          setState(() {
            loadingSubjects.remove(subject);
          });
        }
      }
    } else {
      logger.i('profileData is null');
      if (mounted) {
        setState(() {
          loadingSubjects.remove(subject);
        });
      }
    }
  }

  Future<List<String>> _fetchTopicsFromFirestore(String subject) async {
    if (_user != null) {
      DocumentReference subjectRef = _firestore
          .collection('profiles')
          .doc(_user!.uid)
          .collection('subjects')
          .doc(subject);

      QuerySnapshot topicSnapshot =
          await subjectRef.collection('topics').orderBy('order').get();

      return topicSnapshot.docs.map((doc) => doc['name'] as String).toList();
    }
    return [];
  }

  Future<void> _saveTopicsToFirestore(
      String subject, List<String> topics) async {
    if (_user != null) {
      DocumentReference subjectRef = _firestore
          .collection('profiles')
          .doc(_user!.uid)
          .collection('subjects')
          .doc(subject);

      WriteBatch batch = _firestore.batch();

      for (int i = 0; i < topics.length; i++) {
        DocumentReference topicRef =
            subjectRef.collection('topics').doc(topics[i]);
        batch.set(topicRef, {
          'name': topics[i],
          'unlocked': i == 0 ? true : false, // Unlock the first topic
          'order': i, // Save the order
        });
      }

      await batch.commit();
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

  Future<void> _removeSubjectProgressCache(
      String subject, String userId) async {
    final prefs = await SharedPreferences.getInstance();
    logger.i('Starting to remove cache data for subject: $subject');

    // Get the list of topics for the subject
    List<String>? topics = prefs.getStringList('$userId-$subject-topics') ?? [];
    logger.i('Topics to be removed for subject $subject: $topics');

    for (String topic in topics) {
      // Get the list of lessons for each topic
      List<String>? lessons =
          prefs.getStringList('$userId-$subject-$topic-lessons') ?? [];
      logger.i('Lessons to be removed for topic $topic: $lessons');

      // Remove lesson scores and timestamps
      for (String lesson in lessons) {
        await prefs.remove('$userId-$subject-$topic-$lesson-score');
        await prefs.remove('$userId-$subject-$topic-$lesson-timestamp');
        logger.i('Removed score and timestamp for lesson $lesson');
      }

      // Remove the list of lessons for the topic
      await prefs.remove('$userId-$subject-$topic-lessons');
      logger.i('Removed lessons list for topic $topic');
    }

    // Remove the list of topics for the subject
    await prefs.remove('$userId-$subject-topics');
    logger.i('Removed topics list for subject $subject');

    // Optionally, remove the subject from the list of subjects
    List<String>? subjects = prefs.getStringList('$userId-subjects') ?? [];
    subjects.remove(subject);
    await prefs.setStringList('$userId-subjects', subjects);
    logger.i(
        'Removed subject $subject from subjects list. Remaining subjects: $subjects');

    logger.i('Finished removing cache data for subject: $subject');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
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
                return GestureDetector(
                  onTap: isLoading
                      ? null
                      : () {
                          logger.i("Clicked on $subject");
                          _navigateToSubjectTopicScreen(subject);
                        },
                  onLongPress: isLoading
                      ? null
                      : () {
                          _confirmDeleteSubject(subject);
                        },
                  child: Container(
                    width: 375,
                    height: 125,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.blueGrey.shade700,
                          Colors.blueGrey.shade900,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Center(
                      child: isLoading
                          ? const CircularProgressIndicator()
                          : Text(
                              subject,
                              style: GoogleFonts.cormorant(
                                textStyle: const TextStyle(
                                  fontSize: 36,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                    ),
                  ),
                );
              }),
              GestureDetector(
                onTap: () {
                  _navigateToAddSubjectScreen();
                },
                child: Container(
                  width: 375,
                  height: 100,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.blueGrey.shade700,
                        Colors.blueGrey.shade900,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.add,
                    color: Colors.white,
                    size: 70,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToAddSubjectScreen() async {
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
        if (mounted) {
          _showSnackBar(message: 'Subject "$newSubject" already exists.');
        }
      }
    }
  }

  void _navigateToSubjectTopicScreen(String subject) async {
    await fetchTopicsForSubject(subject);
    if (mounted) {
      List<String> orderedTopics = await _fetchTopicsFromFirestore(subject);
      setState(() {
        subjectTopics[subject] = orderedTopics;
      });

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                SubjectTopicsPage(subject: subject, topics: orderedTopics),
          ),
        );
      }
    }
  }

  void _confirmDeleteSubject(String subject) {
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
                Navigator.of(context).pop(); // Close the dialog immediately
                await _removeSubject(
                    subject); // Remove the subject and all associated data
              },
            ),
          ],
        );
      },
    );
  }

  void _showSnackBar({required String message}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }
}
