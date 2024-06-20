// ignore_for_file: avoid_print

import 'dart:convert';

import 'package:bridgeai/features/user_auth/presentation/pages/subject_topics_page.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../../../../global/user_provider_implementation/user_provider.dart';
import 'add_subject_page.dart';
import 'package:http/http.dart' as http;

class HomepageDashboard extends StatefulWidget {
  const HomepageDashboard({super.key});

  @override
  State<HomepageDashboard> createState() => _HomepageDashboardState();
}

class _HomepageDashboardState extends State<HomepageDashboard> {
  List<String> subjects = [];
  Map<String, List<String>> subjectTopics = {};

  @override
  void initState() {
    super.initState();
    _loadSubjects();
    fetchTopics();
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
    setState(() {
      subjects.remove(subject);
      subjectTopics.remove(subject);
    });
    _saveSubjects();
  }

  Future<void> fetchTopics() async {
    Map<String, dynamic>? profileData =
        Provider.of<UserProvider>(context, listen: false).profileData;

    if (profileData != null) {
      String? name = profileData['name'];
      int? age = profileData['age'];
      int? grade = profileData['grade'];
      String? country = profileData['country'];

      print('Fetching topics for $name, age $age, grade $grade, from $country');
    } else {
      print('profileData is null');
    }
  }

  Future<void> fetchTopicsForSubject(String subject) async {
    if (subjectTopics.containsKey(subject) &&
        subjectTopics[subject]!.isNotEmpty) {
      return;
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
      }));

      // print(
      //     'Fetching topics for Subject $name, age $age, grade $grade, from $country, from $subject');
      if (response.statusCode == 200) {
        print(response.body);
        final decodedResponse = json.decode(response.body);
        List<String> topics = List<String>.from(decodedResponse['topics']);
        if (mounted) {
          setState(() {
            subjectTopics[subject] = topics;
          });
          _saveSubjects();
        }
      } else {
        print('Failed to load topics for $subject');
      }
    } else {
      print('profileData is null');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blueAccent,
        toolbarHeight: 100,
        automaticallyImplyLeading: false,
        title: Text('Dashboard',
            style: GoogleFonts.rammettoOne(
                textStyle: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ))),
      ),
      backgroundColor: Colors.blueAccent,
      body: Padding(
        padding: const EdgeInsets.all(25.0),
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              ...subjects.map((subject) => ElevatedButton(
                    onPressed: () {
                      // Handle subject button click here
                      print("Clicked on $subject");
                      _navigateToSubjectTopicScreen(context, subject);
                    },
                    onLongPress: () {
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
                    child: Text(
                      subject,
                      style: const TextStyle(
                        fontSize: 18,
                        color: Colors.black,
                      ),
                    ),
                  )),
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
              onPressed: () {
                _removeSubject(subject);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
