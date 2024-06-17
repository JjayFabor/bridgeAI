import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class HomepageDashboard extends StatefulWidget {
  const HomepageDashboard({super.key});

  @override
  State<HomepageDashboard> createState() => _HomepageDashboardState();
}

class _HomepageDashboardState extends State<HomepageDashboard> {
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
              )))),
      backgroundColor: Colors.blueAccent,
      body: Align(
        alignment: Alignment.topLeft,
        child: Padding(
          padding: const EdgeInsets.all(
              25.0), // Add padding to keep some space from the edges
          child: ElevatedButton(
            onPressed: () {
              _showAddSubjectDialog(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              fixedSize: const Size(150, 175),
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
        ),
      ),
    );
  }

  void _showAddSubjectDialog(BuildContext context) {
    TextEditingController subjectController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Add Subject"),
          content: TextField(
            controller: subjectController,
            decoration: const InputDecoration(hintText: "Enter subject name"),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text("Cancel"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text("Add"),
              onPressed: () {
                String newSubject = subjectController.text;
                print("New Subject: $newSubject");
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
