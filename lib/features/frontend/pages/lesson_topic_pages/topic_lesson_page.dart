import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:logger/logger.dart';
import 'package:http/http.dart' as http;
import 'explanation_page.dart';
import 'examples_page.dart';
import 'practice_questions_page.dart';
import 'key_terms_page.dart';
import 'quizzes_page.dart';

class TopicLessonPage extends StatefulWidget {
  final String topic;
  final String subject;

  const TopicLessonPage({
    super.key,
    required this.topic,
    required this.subject,
  });

  @override
  State<TopicLessonPage> createState() => _TopicLessonPageState();
}

class _TopicLessonPageState extends State<TopicLessonPage> {
  late Future<Map<String, dynamic>> topicLesson;
  int currentPageIndex = 0;
  int currentLessonIndex = 0;
  int totalPages =
      5; // Explanation, Examples, Practice Questions, Key Terms, Quizzes
  int totalLessons = 1; // Default value
  PageController pageController = PageController();
  late Map<String, dynamic> currentLesson;
  final Logger logger = Logger();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    topicLesson = fetchTopicLesson();
  }

  Future<Map<String, dynamic>> fetchTopicLesson() async {
    final User? user = _auth.currentUser;
    if (user != null) {
      DocumentReference topicRef = _firestore
          .collection('profiles')
          .doc(user.uid)
          .collection('subjects')
          .doc(widget.subject)
          .collection('topics')
          .doc(widget.topic);

      final lessonsSnapshot = await topicRef.collection('lessons').get();

      if (lessonsSnapshot.docs.isNotEmpty) {
        // Lessons are found in Firestore
        Map<String, dynamic> lessonsData = {
          "module": {
            "lessons": lessonsSnapshot.docs.map((doc) {
              return {
                "title": doc.id,
                "content": doc["content"],
                "examples": List<Map<String, dynamic>>.from(doc["examples"]),
                "summary": doc["summary"],
                "practice_questions":
                    List<Map<String, dynamic>>.from(doc["practice_questions"]),
                "key_terms": Map<String, String>.from(doc["key_terms"]),
                "quizzes":
                    List<Map<String, dynamic>>.from(doc["quizzes"]).map((quiz) {
                  return {
                    "lessonTitle":
                        doc.id, // Ensure lesson title is added to each quiz
                    ...quiz
                  };
                }).toList(),
              };
            }).toList()
          }
        };
        return lessonsData;
      }
    }
    // If no lessons found in Firestore, generate them via HTTP request
    return _generateAndSaveTopicLesson();
  }

  Future<Map<String, dynamic>> _generateAndSaveTopicLesson() async {
    try {
      final response = await http.get(Uri.parse(
          'http://10.0.2.2:5000/generate-topics-lesson?topic=${widget.topic}'));

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        if (jsonResponse.isNotEmpty) {
          await _saveLessonToFirestore(widget.topic, jsonResponse);
          return jsonResponse;
        } else {
          final defaultResponse = {
            "module": {
              "title": "Default Module",
              "lessons": [
                {
                  "title": "Default Lesson",
                  "content": "No content available",
                  "examples": [
                    {
                      "title": "Default Example",
                      "content": "No examples available",
                      "explanation": "No explanation available"
                    }
                  ],
                  "summary": "No summary available",
                  "practice_questions": [
                    {"question": "Default Question", "answer": "No answer"}
                  ],
                  "key_terms": {"Default Term": "No definition available"}
                }
              ]
            },
            "quizzes": [
              {
                "questions": [
                  {
                    "question": "Default Question",
                    "choices": ["Option 1", "Option 2", "Option 3", "Option 4"],
                    "answer": "Correct Answer",
                    "explanation": "Explanation for the correct answer"
                  }
                ]
              }
            ]
          };
          await _saveLessonToFirestore(widget.topic, defaultResponse);
          return defaultResponse;
        }
      } else {
        logger.e('Failed to load topic details: ${response.statusCode}');
        throw Exception('Failed to load topic details');
      }
    } catch (e) {
      logger.e('Exception: $e');
      throw Exception('Failed to load topic details');
    }
  }

  Future<void> _saveLessonToFirestore(
      String topic, Map<String, dynamic> lessonData) async {
    final User? user = _auth.currentUser;

    if (user != null) {
      DocumentReference topicRef = _firestore
          .collection('profiles')
          .doc(user.uid)
          .collection('subjects')
          .doc(widget.subject)
          .collection('topics')
          .doc(topic);

      // Save lesson data
      for (var lesson in lessonData['module']['lessons']) {
        await topicRef.collection('lessons').doc(lesson['title']).set({
          'content': lesson['content'],
          'examples': List<Map<String, dynamic>>.from(lesson['examples']),
          'summary': lesson['summary'],
          'practice_questions':
              List<Map<String, dynamic>>.from(lesson['practice_questions']),
          'key_terms': Map<String, String>.from(lesson['key_terms']),
          'quizzes': List<Map<String, dynamic>>.from(lesson['quizzes']),
        });
      }
    }
  }

  void _onPageCompleted() async {
    setState(() {
      if (currentPageIndex < totalPages - 1) {
        currentPageIndex++;
        pageController.nextPage(
            duration: const Duration(milliseconds: 300), curve: Curves.easeIn);
      } else {
        if (currentLessonIndex < totalLessons - 1) {
          currentLessonIndex++;
          currentPageIndex = 0;
          pageController.jumpToPage(0);
        }
      }
    });
  }

  void _onPagePrevious() {
    setState(() {
      if (currentPageIndex > 0) {
        currentPageIndex--;
        pageController.previousPage(
            duration: const Duration(milliseconds: 300), curve: Curves.easeIn);
      } else {
        if (currentLessonIndex > 0) {
          currentLessonIndex--;
          currentPageIndex = totalPages - 1;
          pageController.jumpToPage(totalPages - 1);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.topic,
          style: GoogleFonts.cormorant(
            textStyle: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
        backgroundColor: const Color.fromARGB(255, 20, 20, 20),
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: topicLesson,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (snapshot.hasData) {
            final data = snapshot.data!;
            final lessons =
                List<Map<String, dynamic>>.from(data['module']['lessons']);
            currentLesson = lessons[currentLessonIndex];
            totalLessons = lessons.length;

            return Column(
              children: [
                Expanded(
                  child: PageView(
                    controller: pageController,
                    onPageChanged: (index) {
                      setState(() {
                        currentPageIndex = index;
                      });
                    },
                    children: [
                      ExplanationPage(
                        lessonTitle: currentLesson['title'] ?? 'No title',
                        content:
                            currentLesson['content'] ?? 'No content available',
                        onNext: _onPageCompleted,
                        onPrev: currentPageIndex > 0 || currentLessonIndex > 0
                            ? _onPagePrevious
                            : null,
                      ),
                      ExamplesPage(
                        examples: List<Map<String, dynamic>>.from(
                            currentLesson['examples']),
                        onNext: _onPageCompleted,
                        onPrev: _onPagePrevious,
                      ),
                      PracticeQuestionsPage(
                        questions: List<Map<String, dynamic>>.from(
                            currentLesson['practice_questions']),
                        onNext: _onPageCompleted,
                        onPrev: _onPagePrevious,
                      ),
                      KeyTermsPage(
                        keyTerms: Map<String, String>.from(
                            currentLesson['key_terms']),
                        onNext: _onPageCompleted,
                        onPrev: _onPagePrevious,
                        isLastPage: false,
                      ),
                      QuizzesPage(
                        topic: widget.topic,
                        subject: widget.subject,
                        lessonTitle: currentLesson['title'] ?? 'No title',
                        quizzes: List<Map<String, dynamic>>.from(
                            currentLesson['quizzes']),
                        onNext: _onPageCompleted,
                        onPrev: _onPagePrevious,
                        onFinish: () async {
                          _onPageCompleted();
                          Navigator.pop(context);
                        },
                        isLastPage: currentLessonIndex == totalLessons - 1,
                      ),
                    ],
                  ),
                ),
              ],
            );
          } else {
            return const Center(child: Text('No data available'));
          }
        },
      ),
    );
  }
}
