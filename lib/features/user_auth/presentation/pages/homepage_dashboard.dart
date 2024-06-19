import 'package:bridgeai/features/user_auth/presentation/pages/add_subject_page.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class HomepageDashboard extends StatefulWidget {
  const HomepageDashboard({super.key});

  @override
  State<HomepageDashboard> createState() => _HomepageDashboardState();
}

class _HomepageDashboardState extends State<HomepageDashboard> {
  List<String> subjects = [];

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
    }
  }
}
