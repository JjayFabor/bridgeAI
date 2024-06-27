import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../../../../../global/user_provider_implementation/user_provider.dart';
import 'explanation_page.dart';
import 'examples_page.dart';
import 'practice_questions_page.dart';
import 'key_terms_page.dart';

class TopicLessonPage extends StatefulWidget {
  final String topic;
  final Map<String, Map<String, dynamic>> lessonCache;

  const TopicLessonPage(
      {super.key, required this.topic, required this.lessonCache});

  @override
  State<TopicLessonPage> createState() => _TopicLessonPageState();
}

class _TopicLessonPageState extends State<TopicLessonPage> {
  late Future<Map<String, dynamic>> topicLesson;
  int currentPageIndex = 0;
  int currentLessonIndex = 0;
  int totalPages = 4; // Explanation, Examples, Practice Questions, Key Terms
  int totalLessons = 1; // Default value
  PageController pageController = PageController();

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
          }
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
        } else {
          // Show completion message
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text('Congratulations!'),
                content: const Text('Thank you for completing this lesson'),
                actions: <Widget>[
                  TextButton(
                    child: const Text('OK'),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              );
            },
          );
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
            final data = snapshot.data!['module'];
            final lessons = List<Map<String, dynamic>>.from(data['lessons']);
            final currentLesson = lessons[currentLessonIndex];
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
                        lessonTitle: currentLesson['title'],
                        content: currentLesson['content'],
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
                        isLastPage: currentLessonIndex == totalLessons - 1 &&
                            currentPageIndex == totalPages - 1,
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: LinearProgressIndicator(
                    value: ((currentLessonIndex * totalPages) +
                            currentPageIndex +
                            1) /
                        (totalLessons * totalPages),
                    backgroundColor: Colors.grey[200],
                    color: Colors.purple,
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
