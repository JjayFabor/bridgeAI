import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../../../../global/user_provider_implementation/user_provider.dart';

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
  PageController _pageController = PageController();
  int currentPageIndex = 0;

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
          "explanations": [
            {
              "title": "Default Explanation",
              "content": "No explanation available"
            }
          ],
          "examples": [
            {"title": "Default Example", "content": "No examples available"}
          ],
          "key_terms": {}
        };
        userProvider.setLessonInCache(widget.topic, defaultResponse);
        return defaultResponse;
      }
    } else {
      throw Exception('Failed to load topic details');
    }
  }

  Widget buildFlashCard(String term, String definition) {
    return Card(
      elevation: 4,
      child: ListTile(
        title: Text(
          term,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        subtitle: Text(definition, style: TextStyle(fontSize: 16)),
        leading: Icon(Icons.book, size: 40),
      ),
    );
  }

  void _onPageChanged(int index) {
    setState(() {
      currentPageIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.topic),
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
            final explanations =
                List<Map<String, dynamic>>.from(data['explanations'] ?? []);
            final examples =
                List<Map<String, dynamic>>.from(data['examples'] ?? []);
            final keyTerms = Map<String, String>.from(data['key_terms'] ?? {});

            return Column(
              children: [
                LinearProgressIndicator(
                  value: (currentPageIndex + 1) / 3,
                  backgroundColor: Colors.grey[300],
                  color: Colors.blue,
                ),
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    onPageChanged: _onPageChanged,
                    children: [
                      buildExplanationsPage(explanations),
                      buildExamplesPage(examples),
                      buildKeyTermsPage(keyTerms),
                    ],
                  ),
                ),
              ],
            );
          } else {
            return Center(child: Text('No data available'));
          }
        },
      ),
    );
  }

  Widget buildExplanationsPage(List<Map<String, dynamic>> explanations) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: ListView.builder(
        itemCount: explanations.length,
        itemBuilder: (context, index) {
          final explanation = explanations[index];
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(explanation['title'] as String,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              SizedBox(height: 5),
              Text(explanation['content'] as String,
                  style: TextStyle(fontSize: 18)),
              SizedBox(height: 20),
            ],
          );
        },
      ),
    );
  }

  Widget buildExamplesPage(List<Map<String, dynamic>> examples) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: ListView.builder(
        itemCount: examples.length,
        itemBuilder: (context, index) {
          final example = examples[index];
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(example['title'] as String,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              SizedBox(height: 5),
              Text(example['content'] as String,
                  style: TextStyle(fontSize: 18)),
              SizedBox(height: 20),
            ],
          );
        },
      ),
    );
  }

  Widget buildKeyTermsPage(Map<String, String> keyTerms) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: ListView(
        children: keyTerms.entries
            .map((entry) => buildFlashCard(entry.key, entry.value))
            .toList(),
      ),
    );
  }
}
