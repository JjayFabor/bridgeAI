import 'package:flutter/material.dart';

class AddSubjectPage extends StatelessWidget {
  final TextEditingController searchController = TextEditingController();
  final List<String> recommendedSubjects = [
    'Mathematics',
    'Science',
    'History',
    'Geography',
    'Literature',
    'Art',
    'Music',
    'Physics',
    'Chemistry',
    'Biology'
  ];

  AddSubjectPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Add Subject"),
        backgroundColor: Colors.blueAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: searchController,
              decoration: const InputDecoration(
                hintText: 'Search a Subject',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
              ),
              onSubmitted: (value) {
                if (value.isNotEmpty) {
                  Navigator.pop(context, value);
                }
              },
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: recommendedSubjects.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(recommendedSubjects[index]),
                    onTap: () {
                      Navigator.pop(context, recommendedSubjects[index]);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
