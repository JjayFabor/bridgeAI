import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../../../../global/user_provider_implementation/user_provider.dart';
import 'add_subject_page.dart';

class HomepageDashboard extends StatefulWidget {
  const HomepageDashboard({super.key});

  @override
  State<HomepageDashboard> createState() => _HomepageDashboardState();
}

class _HomepageDashboardState extends State<HomepageDashboard> {
  List<String> subjects = [];

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
    });
  }

  Future<void> _saveSubjects() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setStringList('subjects', subjects);
  }

  Future<void> _removeSubject(String subject) async {
    setState(() {
      subjects.remove(subject);
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
      setState(() {
        subjects.add(newSubject);
      });
      _saveSubjects();
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
