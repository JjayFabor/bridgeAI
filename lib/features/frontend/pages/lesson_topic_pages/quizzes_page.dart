import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

class QuizzesPage extends StatefulWidget {
  final String subject;
  final String topic;
  final String lessonTitle;
  final List<Map<String, dynamic>> quizzes;
  final VoidCallback onNext;
  final VoidCallback? onPrev;
  final VoidCallback onFinish;
  final bool isLastPage;

  const QuizzesPage({
    super.key,
    required this.subject,
    required this.topic,
    required this.lessonTitle,
    required this.quizzes,
    required this.onNext,
    this.onPrev,
    required this.onFinish,
    required this.isLastPage,
  });

  @override
  State<QuizzesPage> createState() => _QuizzesPageState();
}

class _QuizzesPageState extends State<QuizzesPage> {
  User? _user;
  late List<int?> _selectedAnswers;
  bool _isSubmitted = false;
  int _correctAnswers = 0;
  SharedPreferences? _prefs;
  late String _userId;
  final Logger logger = Logger();
  int _currentIndex = 0;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _initializeUser();
    _initializeQuiz();
  }

  Future<void> _initializeUser() async {
    _user = FirebaseAuth.instance.currentUser;
    if (_user != null) {
      _userId = _user!.uid;
    }
  }

  Future<void> _initializeQuiz() async {
    _prefs = await SharedPreferences.getInstance();

    setState(() {
      _selectedAnswers = List<int?>.filled(widget.quizzes.length, null);
      _isSubmitted = false;
      _correctAnswers = 0;
    });

    // Load saved state
    await _loadQuizState();
  }

  Future<void> _loadQuizState() async {
    final savedAnswers = _prefs?.getStringList(
        '$_userId-${widget.subject}-${widget.topic}-${widget.lessonTitle}-answers');
    final savedIsSubmitted = _prefs?.getBool(
        '$_userId-${widget.subject}-${widget.topic}-${widget.lessonTitle}-isSubmitted');
    final savedCorrectAnswers = _prefs?.getInt(
        '$_userId-${widget.subject}-${widget.topic}-${widget.lessonTitle}-correctAnswers');

    setState(() {
      if (savedAnswers != null) {
        _selectedAnswers =
            savedAnswers.map((e) => e.isEmpty ? null : int.parse(e)).toList();
      }

      if (savedIsSubmitted != null) {
        _isSubmitted = savedIsSubmitted;
      }

      if (savedCorrectAnswers != null) {
        _correctAnswers = savedCorrectAnswers;
      }
    });
  }

  Future<void> _submitQuiz() async {
    logger.i("UserID: $_userId");
    int correctAnswers = 0;
    for (int i = 0; i < widget.quizzes.length; i++) {
      if (_selectedAnswers[i] != null &&
          widget.quizzes[i]['choices'][_selectedAnswers[i]!] ==
              widget.quizzes[i]['answer']) {
        correctAnswers++;
      }
    }
    setState(() {
      _correctAnswers = correctAnswers;
      _isSubmitted = true;
    });
    await _saveQuizState();

    // Save the score for the current lesson
    if (_userId.isNotEmpty) {
      await _saveLessonScore(widget.subject, widget.topic, widget.lessonTitle,
          _userId, correctAnswers);
    }
  }

  Future<void> _saveLessonScore(String subject, String topic,
      String lessonTitle, String userId, int score) async {
    await _prefs?.setInt('$userId-$subject-$topic-$lessonTitle-score', score);
    await _prefs?.setString('$userId-$subject-$topic-$lessonTitle-timestamp',
        DateTime.now().toString());

    await _saveStringListItem('$userId-subjects', subject);
    await _saveStringListItem('$userId-$subject-topics', topic);
    await _saveStringListItem('$userId-$subject-$topic-lessons', lessonTitle);
  }

  Future<void> _saveStringListItem(String key, String value) async {
    List<String>? items = _prefs?.getStringList(key) ?? [];
    if (!items.contains(value)) {
      items.add(value);
      await _prefs?.setStringList(key, items);
      logger.i('Stored $value in $key');
    }
  }

  Future<void> _retakeQuiz() async {
    setState(() {
      _selectedAnswers = List<int?>.filled(widget.quizzes.length, null);
      _isSubmitted = false;
      _correctAnswers = 0;
      _currentIndex = 0; // Reset the index to the first quiz
    });
    _pageController.jumpToPage(0);
    await _prefs?.remove(
        '$_userId-${widget.subject}-${widget.topic}-${widget.lessonTitle}-answers');
    await _prefs?.remove(
        '$_userId-${widget.subject}-${widget.topic}-${widget.lessonTitle}-isSubmitted');
    await _prefs?.remove(
        '$_userId-${widget.subject}-${widget.topic}-${widget.lessonTitle}-correctAnswers');
  }

  Future<void> _saveQuizState() async {
    await _prefs?.setStringList(
        '$_userId-${widget.subject}-${widget.topic}-${widget.lessonTitle}-answers',
        _selectedAnswers.map((e) => e?.toString() ?? '').toList());
    await _prefs?.setBool(
        '$_userId-${widget.subject}-${widget.topic}-${widget.lessonTitle}-isSubmitted',
        _isSubmitted);
    await _prefs?.setInt(
        '$_userId-${widget.subject}-${widget.topic}-${widget.lessonTitle}-correctAnswers',
        _correctAnswers);
  }

  Future<void> _unlockNextTopic() async {
    if (_user != null) {
      try {
        final subjectRef = FirebaseFirestore.instance
            .collection('profiles')
            .doc(_user!.uid)
            .collection('subjects')
            .doc(widget.subject);

        final topicsCollection = subjectRef.collection('topics');
        final currentTopicDoc = await topicsCollection.doc(widget.topic).get();

        if (currentTopicDoc.exists) {
          final currentOrder = currentTopicDoc.data()?['order'] ?? 0;
          final nextTopicQuery = await topicsCollection
              .where('order', isEqualTo: currentOrder + 1)
              .limit(1)
              .get();

          if (nextTopicQuery.docs.isNotEmpty) {
            final nextTopicDoc = nextTopicQuery.docs.first;
            await nextTopicDoc.reference.update({'unlocked': true});
            logger.i('Unlocked next topic: ${nextTopicDoc.id}');
          } else {
            logger.w('No next topic found with order ${currentOrder + 1}');
          }
        } else {
          logger.w('Current topic document does not exist: ${widget.topic}');
        }
      } catch (e) {
        logger.e('Error unlocking next topic: $e');
      }
    } else {
      logger.e('User is not logged in');
    }
  }

  void _nextQuiz() {
    if (_currentIndex < widget.quizzes.length - 1) {
      setState(() {
        _currentIndex++;
      });
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _prevQuiz() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
      });
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return _prefs == null
        ? const Center(child: CircularProgressIndicator())
        : Column(
            children: [
              if (!_isSubmitted)
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: widget.quizzes.length,
                    onPageChanged: (index) {
                      setState(() {
                        _currentIndex = index;
                      });
                    },
                    itemBuilder: (context, index) {
                      final quiz = widget.quizzes[index];
                      return Center(
                        child: Container(
                          margin: const EdgeInsets.all(8.0),
                          width: MediaQuery.of(context).size.width * 0.9,
                          height: MediaQuery.of(context).size.height * 0.5,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                spreadRadius: 2,
                                blurRadius: 6,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 4,
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(
                                    height: 20,
                                  ),
                                  Text(
                                    quiz['question'] ?? 'No question provided',
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Expanded(
                                    child: ListView(
                                      children: List.generate(
                                          quiz['choices']?.length ?? 0, (i) {
                                        return RadioListTile<int>(
                                          title: Text(
                                            quiz['choices'][i] ??
                                                'No choice provided',
                                            style:
                                                const TextStyle(fontSize: 22),
                                          ),
                                          value: i,
                                          groupValue: _selectedAnswers[index],
                                          onChanged: (int? value) {
                                            setState(() {
                                              _selectedAnswers[index] = value;
                                            });
                                          },
                                        );
                                      }),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                )
              else
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'You got $_correctAnswers out of ${widget.quizzes.length} correct.',
                          style: const TextStyle(fontSize: 20),
                        ),
                        if (_correctAnswers / widget.quizzes.length >= 0.75)
                          Column(
                            children: [
                              const Text(
                                  'Congratulations! You can proceed to the next lesson.',
                                  style: TextStyle(
                                      color: Colors.green, fontSize: 16)),
                              const SizedBox(height: 20),
                              SizedBox(
                                height: 600,
                                child: ListView.builder(
                                  itemCount: widget.quizzes.length,
                                  itemBuilder: (context, index) {
                                    final quiz = widget.quizzes[index];
                                    final isCorrect = _selectedAnswers[index] !=
                                            null &&
                                        quiz['choices']
                                                [_selectedAnswers[index]!] ==
                                            quiz['answer'];
                                    return Container(
                                      margin: const EdgeInsets.all(8.0),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(16),
                                        boxShadow: [
                                          BoxShadow(
                                            color:
                                                Colors.black.withOpacity(0.2),
                                            spreadRadius: 2,
                                            blurRadius: 6,
                                            offset: const Offset(0, 3),
                                          ),
                                        ],
                                      ),
                                      child: Card(
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(16),
                                        ),
                                        elevation: 4,
                                        child: Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                quiz['question'] ??
                                                    'No question provided',
                                                style: const TextStyle(
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              Text(
                                                'Your answer: ${_selectedAnswers[index] != null ? quiz['choices'][_selectedAnswers[index]!] : 'No answer provided'}',
                                                style: TextStyle(
                                                    color: isCorrect
                                                        ? Colors.green
                                                        : Colors.red),
                                              ),
                                              Text(
                                                'Correct answer: ${quiz['answer']}',
                                                style: const TextStyle(
                                                    color: Colors.green),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              ElevatedButton(
                                onPressed: () async {
                                  if (widget.isLastPage) {
                                    logger.i(
                                        "Last page detected. Unlocking next topic...");
                                    await _unlockNextTopic();
                                    logger.i("Unlock next topic successful.");
                                    widget.onFinish();
                                  } else {
                                    widget.onNext();
                                  }
                                },
                                child:
                                    Text(widget.isLastPage ? 'Finish' : 'Next'),
                              ),
                            ],
                          )
                        else
                          Column(
                            children: [
                              const Text(
                                  'You need to score at least 75% to proceed to the next lesson.',
                                  style: TextStyle(
                                      color: Colors.red, fontSize: 16)),
                              ElevatedButton(
                                onPressed: _retakeQuiz,
                                child: const Text('Retake Quiz'),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
              if (!_isSubmitted)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (_currentIndex > 0)
                      ElevatedButton(
                        onPressed: _prevQuiz,
                        child: const Text('Prev'),
                      ),
                    if (_currentIndex < widget.quizzes.length - 1)
                      ElevatedButton(
                        onPressed: _nextQuiz,
                        child: const Text('Next'),
                      ),
                    if (_currentIndex == widget.quizzes.length - 1)
                      ElevatedButton(
                        onPressed: _submitQuiz,
                        child: const Text('Submit'),
                      ),
                  ],
                )
            ],
          );
  }
}
