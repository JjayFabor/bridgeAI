import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:logger/logger.dart';
import '../lesson_topic_pages/topic_lesson_page.dart';

class SubjectTopicsPage extends StatefulWidget {
  final String subject;
  final List<String> topics;

  const SubjectTopicsPage({
    super.key,
    required this.subject,
    required this.topics,
  });

  @override
  State<SubjectTopicsPage> createState() => SubjectTopicsPageState();
}

class SubjectTopicsPageState extends State<SubjectTopicsPage> {
  late User? _user;
  List<Map<String, dynamic>> topics = [];
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Logger logger = Logger();

  @override
  void initState() {
    super.initState();
    _user = FirebaseAuth.instance.currentUser;
    _fetchTopics();
  }

  Future<void> _fetchTopics() async {
    if (_user != null) {
      DocumentReference subjectRef = _firestore
          .collection('profiles')
          .doc(_user!.uid)
          .collection('subjects')
          .doc(widget.subject);

      QuerySnapshot topicSnapshot = await subjectRef.collection('topics').orderBy('order').get();

      if (mounted) {
        setState(() {
          topics = topicSnapshot.docs.map((doc) {
            final topicName = doc['name'];
            final unlocked = doc['unlocked'];
            logger.i("Fetched topic: $topicName");
            if (unlocked) {
              logger.i("Topic unlocked: $topicName");
            }
            return {
              'name': topicName,
              'unlocked': unlocked,
            };
          }).toList();
        });
      }
    }
  }

  void updateUnlockedStatus(int index) async {
    if (_user != null && index < topics.length - 1) {
      logger.i("Unlocking topic at index: $index");

      setState(() {
        topics[index + 1]['unlocked'] = true;
      });

      DocumentReference topicRef = _firestore
          .collection('profiles')
          .doc(_user!.uid)
          .collection('subjects')
          .doc(widget.subject)
          .collection('topics')
          .doc(topics[index + 1]['name']);

      try {
        await topicRef.update({'unlocked': true});
      } catch (e) {
        logger.i("Failed to unlock next topic: $e");
      }
    } else {
      logger.i("No more topics to unlock or invalid index.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.subject} Topics'),
      ),
      body: ListView.builder(
        itemCount: topics.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton(
              onPressed: topics[index]['unlocked']
                  ? () {
                      final topic = topics[index]['name'];
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TopicLessonPage(
                            topic: topic,
                            subject: widget.subject,
                          ),
                        ),
                      ).then((_) => _fetchTopics());
                    }
                  : null,
              child: Text(topics[index]['name']),
            ),
          );
        },
      ),
    );
  }
}
