import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;

import '../../../../../global/provider_implementation/user_provider.dart';
import 'explanation_page.dart';
import 'examples_page.dart';
import 'practice_questions_page.dart';
import 'key_terms_page.dart';
import 'quizzes_page.dart';

class TopicLessonPage extends StatefulWidget {
  final String topic;
  final Map<String, Map<String, dynamic>> lessonCache;

  const TopicLessonPage({
    super.key,
    required this.topic,
    required this.lessonCache,
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

  @override
  void initState() {
    super.initState();
    topicLesson = fetchTopicLesson();
  }

  Future<Map<String, dynamic>> fetchTopicLesson() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    final cachedLesson = userProvider.getLessonFromCache(widget.topic);
    if (cachedLesson != null) {
      return cachedLesson;
    }

    final response = await http.get(Uri.parse(
        'http://10.0.2.2:5000/generate-topics-lesson?topic=${widget.topic}'));

    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonResponse = json.decode(response.body);
      if (jsonResponse.isNotEmpty) {
        userProvider.setLessonInCache(widget.topic, jsonResponse);
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
              "lesson_title": "Default Lesson",
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
        userProvider.setLessonInCache(widget.topic, defaultResponse);
        return defaultResponse;
      }
    } else {
      throw Exception('Failed to load topic details');
    }
  }

  void _onPageCompleted() {
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
        title: Text(widget.topic),
        backgroundColor: Colors.purple,
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
            final lessons = List<Map<String, dynamic>>.from(
                data['module']['lessons'] ?? []);
            currentLesson = lessons[currentLessonIndex];
            totalLessons = lessons.length;

            // Debugging output
            logger.i("Quizzes data: ${currentLesson['quizzes']}");

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
                            currentLesson['examples'] ?? []),
                        onNext: _onPageCompleted,
                        onPrev: _onPagePrevious,
                      ),
                      PracticeQuestionsPage(
                        questions: List<Map<String, dynamic>>.from(
                            currentLesson['practice_questions'] ?? []),
                        onNext: _onPageCompleted,
                        onPrev: _onPagePrevious,
                      ),
                      KeyTermsPage(
                        keyTerms: Map<String, String>.from(
                            currentLesson['key_terms'] ?? {}),
                        onNext: _onPageCompleted,
                        onPrev: _onPagePrevious,
                        isLastPage: false,
                      ),
                      QuizzesPage(
                        quizzes: List<Map<String, dynamic>>.from(
                            currentLesson['quizzes'] ?? []),
                        onNext: _onPageCompleted,
                        onPrev: _onPagePrevious,
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