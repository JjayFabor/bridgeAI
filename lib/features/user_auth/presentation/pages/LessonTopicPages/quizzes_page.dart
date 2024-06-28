import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class QuizzesPage extends StatefulWidget {
  final String explanationsJson;

  const QuizzesPage({super.key, required this.explanationsJson});

  @override
  State<QuizzesPage> createState() => _QuizzesPageState();
}

class _QuizzesPageState extends State<QuizzesPage> {
  static List<dynamic>? cachedQuizzes; // Static variable to cache the quizzes
  List<dynamic>? quizzes;
  bool isLoading = true;
  bool isSubmitted = false;
  List<String?> userAnswers = [];

  @override
  void initState() {
    super.initState();
    if (cachedQuizzes != null) {
      // If cached quizzes are available, use them
      quizzes = cachedQuizzes;
      userAnswers =
          List<String?>.filled(quizzes!.first['questions'].length, null);
      isLoading = false;
    } else {
      // If no cached quizzes, fetch from the API
      fetchQuiz();
    }
  }

  Future<void> fetchQuiz() async {
    try {
      final response = await http.post(
        Uri.parse('http://10.0.2.2:5000/generate-quiz'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, String>{
          'explanations': widget.explanationsJson,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          quizzes = data['quizzes'];
          cachedQuizzes = quizzes; // Cache the fetched quizzes
          userAnswers =
              List<String?>.filled(quizzes!.first['questions'].length, null);
          isLoading = false;
        });
      } else {
        setState(() {
          quizzes = null;
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        quizzes = null;
        isLoading = false;
      });
    }
  }

  void submitQuiz() {
    setState(() {
      isSubmitted = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Quizzes')),
      body: Center(
        child: isLoading
            ? const CircularProgressIndicator()
            : quizzes != null && quizzes!.isNotEmpty
                ? ListView.builder(
                    itemCount: quizzes!.first['questions'].length + 1,
                    itemBuilder: (context, index) {
                      if (index == quizzes!.first['questions'].length) {
                        return Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: ElevatedButton(
                            onPressed: submitQuiz,
                            child: const Text('Submit'),
                          ),
                        );
                      }
                      final question = quizzes!.first['questions'][index];
                      return QuizCard(
                        question: question,
                        questionIndex: index,
                        userAnswer: userAnswers[index],
                        isSubmitted: isSubmitted,
                        onAnswerSelected: (value) {
                          setState(() {
                            userAnswers[index] = value;
                          });
                        },
                      );
                    },
                  )
                : const Text('No quiz data available'),
      ),
    );
  }
}

class QuizCard extends StatelessWidget {
  final Map<String, dynamic> question;
  final int questionIndex;
  final String? userAnswer;
  final bool isSubmitted;
  final ValueChanged<String?> onAnswerSelected;

  const QuizCard({
    super.key,
    required this.question,
    required this.questionIndex,
    required this.userAnswer,
    required this.isSubmitted,
    required this.onAnswerSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(10.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Question ${questionIndex + 1}: ${question['question']}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            ...question['choices'].map<Widget>((choice) {
              return RadioListTile<String>(
                title: Text(choice),
                value: choice,
                groupValue: userAnswer,
                onChanged: isSubmitted ? null : onAnswerSelected,
              );
            }).toList(),
            if (isSubmitted) ...[
              Text(
                'Your Answer: ${userAnswer ?? "Not Answered"}',
                style: TextStyle(
                  fontSize: 14,
                  color: userAnswer == question['answer']
                      ? Colors.green
                      : Colors.red,
                ),
              ),
              Text(
                'Correct Answer: ${question['answer']}',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.green,
                ),
              ),
              Text(
                'Explanation: ${question['explanation']}',
                style: const TextStyle(
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class QuizSummary extends StatelessWidget {
  final List<Map<String, dynamic>> questions;
  final List<String?> userAnswers;

  const QuizSummary({
    super.key,
    required this.questions,
    required this.userAnswers,
  });

  @override
  Widget build(BuildContext context) {
    int score = 0;
    for (int i = 0; i < questions.length; i++) {
      if (userAnswers[i] == questions[i]['answer']) {
        score++;
      }
    }

    return AlertDialog(
      title: const Text('Quiz Summary'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Your Score: $score / ${questions.length}'),
          const SizedBox(height: 10),
          ...questions.asMap().entries.map((entry) {
            int index = entry.key;
            Map<String, dynamic> question = entry.value;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Question ${index + 1}: ${question['question']}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text('Your Answer: ${userAnswers[index] ?? "Not Answered"}'),
                  Text('Correct Answer: ${question['answer']}'),
                  Text('Explanation: ${question['explanation']}'),
                ],
              ),
            );
          }).toList(),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Close'),
        ),
      ],
    );
  }
}
