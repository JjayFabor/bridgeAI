import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
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

      QuerySnapshot topicSnapshot =
          await subjectRef.collection('topics').orderBy('order').get();

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
        toolbarHeight: 70,
        backgroundColor: const Color.fromARGB(255, 88, 83, 83),
        foregroundColor: Colors.white,
        title: Text(
          'Topics',
          style: GoogleFonts.cormorant(
            textStyle: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 100),
          Expanded(
            child: ListView.builder(
              itemCount: topics.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: IntrinsicHeight(
                    child: IntrinsicWidth(
                      stepWidth: MediaQuery.of(context).size.width,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: topics[index]['unlocked']
                              ? Colors.green
                                  .shade400 // Vibrant color for unlocked topics
                              : Colors.grey.shade300, // Disabled color
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              vertical: 15, horizontal: 20),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: topics[index]['unlocked']
                              ? 10
                              : 2, // Elevation for 3D effect
                        ),
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
                        child: Row(
                          children: [
                            Icon(
                              topics[index]['unlocked']
                                  ? Icons.star
                                  : Icons.lock,
                              color: topics[index]['unlocked']
                                  ? Colors.yellow.shade700
                                  : Colors.grey.shade600,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                topics[index]['name'],
                                style: GoogleFonts.aBeeZee(
                                  textStyle: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: topics[index]['unlocked']
                                        ? Colors.white
                                        : Colors.grey.shade800,
                                  ),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (topics[index]['unlocked'])
                              const Icon(
                                Icons.arrow_forward,
                                color: Colors.white,
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
