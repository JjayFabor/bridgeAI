import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'user_progress.dart';

class ProgressPage extends StatelessWidget {
  final String userId;

  const ProgressPage({super.key, required this.userId});

  Future<UserProgress> _getProgressData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<Subject> subjects = [];

    List<String>? subjectNames = prefs.getStringList('$userId-subjects') ?? [];

    for (String subjectName in subjectNames) {
      List<String>? topicNames =
          prefs.getStringList('$userId-$subjectName-topics') ?? [];
      List<Topic> topics = [];

      for (String topicName in topicNames) {
        List<String>? lessonTitles =
            prefs.getStringList('$userId-$subjectName-$topicName-lessons') ??
                [];
        List<Lesson> lessons = [];

        for (String lessonTitle in lessonTitles) {
          int? score = prefs
              .getInt('$userId-$subjectName-$topicName-$lessonTitle-score');
          String? timestamp = prefs.getString(
              '$userId-$subjectName-$topicName-$lessonTitle-timestamp');

          if (score != null && timestamp != null) {
            lessons.add(
                Lesson(title: lessonTitle, score: score, timestamp: timestamp));
          }
        }

        topics.add(Topic(name: topicName, lessons: lessons));
      }

      subjects.add(Subject(name: subjectName, topics: topics));
    }

    return UserProgress(userId: userId, subjects: subjects);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<UserProgress>(
        future: _getProgressData(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final progressData = snapshot.data!;

          if (progressData.subjects.isEmpty) {
            return const Center(child: Text('No progress data available.'));
          }

          return ListView.builder(
            itemCount: progressData.subjects.length,
            itemBuilder: (context, subjectIndex) {
              Subject subject = progressData.subjects[subjectIndex];

              return ExpansionTile(
                title: Text(subject.name,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
                children: subject.topics.map<Widget>((Topic topic) {
                  return ExpansionTile(
                    title:
                        Text(topic.name, style: const TextStyle(fontSize: 16)),
                    children: topic.lessons.map<Widget>((Lesson lesson) {
                      return ListTile(
                        title: Text(lesson.title),
                        subtitle: Text(
                            'Score: ${lesson.score}\nDate: ${lesson.timestamp}'),
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
