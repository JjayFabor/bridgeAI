import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProgressPage extends StatelessWidget {
  final String userId;

  const ProgressPage({super.key, required this.userId});

  Future<Map<String, dynamic>> _getProgressData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    Map<String, dynamic> progressData = {};

    List<String>? subjects = prefs.getStringList('$userId-subjects') ?? [];

    for (String subject in subjects) {
      List<String>? topics =
          prefs.getStringList('$userId-$subject-topics') ?? [];
      Map<String, dynamic> topicsData = {};

      for (String topic in topics) {
        List<String>? lessons =
            prefs.getStringList('$userId-$subject-$topic-lessons') ?? [];
        List<Map<String, dynamic>> lessonsData = [];

        for (String lesson in lessons) {
          int? score = prefs.getInt('$userId-$subject-$topic-$lesson-score');
          String? timestamp =
              prefs.getString('$userId-$subject-$topic-$lesson-timestamp');

          if (score != null && timestamp != null) {
            lessonsData.add({
              'lessonTitle': lesson,
              'score': score,
              'timestamp': timestamp,
            });
          }
        }

        topicsData[topic] = lessonsData;
      }

      progressData[subject] = topicsData;
    }

    return progressData;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Your Progress')),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _getProgressData(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final progressData = snapshot.data!;

          if (progressData.isEmpty) {
            return const Center(child: Text('No progress data available.'));
          }

          return ListView.builder(
            itemCount: progressData.keys.length,
            itemBuilder: (context, subjectIndex) {
              String subject = progressData.keys.elementAt(subjectIndex);
              Map<String, dynamic> topicsData = progressData[subject];

              return ExpansionTile(
                title: Text(subject,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
                children: topicsData.keys.map<Widget>((String topic) {
                  List<Map<String, dynamic>> lessonsData = topicsData[topic];

                  return ExpansionTile(
                    title: Text(topic, style: const TextStyle(fontSize: 16)),
                    children: lessonsData
                        .map<Widget>((Map<String, dynamic> lessonData) {
                      final lessonTitle = lessonData['lessonTitle'];
                      final score = lessonData['score'];
                      final timestamp = lessonData['timestamp'];

                      return ListTile(
                        title: Text(lessonTitle),
                        subtitle: Text('Score: $score\nDate: $timestamp'),
                      );
                    }).toList(),
                  );
                }).toList(),
              );
            },
          );
        },
      ),
    );
  }
}
