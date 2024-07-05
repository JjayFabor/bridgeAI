import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProgressPage extends StatelessWidget {
  final String username;

  const ProgressPage({super.key, required this.username});

  Future<List<Map<String, dynamic>>> _getScores() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<Map<String, dynamic>> scores = [];

    List<String>? lessonTitles =
        prefs.getStringList('$username-lessonTitles') ?? [];

    for (String lessonTitle in lessonTitles) {
      int? score = prefs.getInt('$username-$lessonTitle-score');
      String? timestamp = prefs.getString('$username-$lessonTitle-timestamp');

      if (score != null && timestamp != null) {
        scores.add({
          'lessonTitle': lessonTitle,
          'score': score,
          'timestamp': timestamp,
        });
      }
    }

    return scores;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Your Progress')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _getScores(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final scores = snapshot.data!;

          if (scores.isEmpty) {
            return const Center(child: Text('No scores available.'));
          }

          return ListView.builder(
            itemCount: scores.length,
            itemBuilder: (context, index) {
              final score = scores[index];
              final lessonTitle = score['lessonTitle'];
              final scoreValue = score['score'];
              final timestamp = score['timestamp'];

              return ListTile(
                title: Text(lessonTitle),
                subtitle: Text('Score: $scoreValue\nDate: $timestamp'),
              );
            },
          );
        },
      ),
    );
  }
}
