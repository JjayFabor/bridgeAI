import 'package:bridgeai/features/user_auth/presentation/pages/topic_lesson_page.dart';
import 'package:flutter/material.dart';

class SubjectTopicsPage extends StatefulWidget {
  final String subject;
  final List<String> topics;

  const SubjectTopicsPage(
      {super.key, required this.subject, required this.topics});

  @override
  State<SubjectTopicsPage> createState() => _SubjectTopicsPageState();
}

class _SubjectTopicsPageState extends State<SubjectTopicsPage> {
  final Map<String, Map<String, dynamic>> _lessonCache = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.subject} Topics'),
      ),
      body: ListView.builder(
        itemCount: widget.topics.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton(
              onPressed: () {
                final topic = widget.topics[index];
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TopicLessonPage(
                      topic: topic,
                      lessonCache: _lessonCache,
                    ),
                  ),
                );
              },
              child: Text(widget.topics[index]),
            ),
          );
        },
      ),
    );
  }
}
