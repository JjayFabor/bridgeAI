import 'package:flutter/material.dart';

class SubjectTopicsPage extends StatelessWidget {
  final String subject;
  final List<String> topics;

  const SubjectTopicsPage({super.key, required this.subject, required this.topics});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('$subject Topics'),
      ),
      body: ListView.builder(
        itemCount: topics.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(topics[index]),
          );
        },
      ),
    );
  }
}
