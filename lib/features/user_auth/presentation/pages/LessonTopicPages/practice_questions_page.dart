import 'package:flutter/material.dart';
import 'package:flip_card/flip_card.dart';

class PracticeQuestionsPage extends StatelessWidget {
  final List<Map<String, dynamic>> questions;
  final VoidCallback onNext;
  final VoidCallback onPrev;

  const PracticeQuestionsPage({
    super.key,
    required this.questions,
    required this.onNext,
    required this.onPrev,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Practice Questions')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: questions.length,
                itemBuilder: (context, index) {
                  final question = questions[index];
                  return buildFlipCard(question['question'] as String,
                      question['answer'] as String);
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  onPressed: onPrev,
                  child: const Text('Prev'),
                ),
                ElevatedButton(
                  onPressed: onNext,
                  child: const Text('Next'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget buildFlipCard(String question, String answer) {
    return Card(
      elevation: 4,
      child: FlipCard(
        direction: FlipDirection.HORIZONTAL,
        front: Container(
          padding: const EdgeInsets.all(16.0),
          child: Center(
            child: Text(
              question,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        back: Container(
          padding: const EdgeInsets.all(16.0),
          color: Colors.purple[50],
          child: Center(
            child: Text(
              answer,
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ),
      ),
    );
  }
}
