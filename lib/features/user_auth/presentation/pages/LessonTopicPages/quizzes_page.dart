import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

class QuizzesPage extends StatefulWidget {
  final String subject;
  final String topic;
  final String lessonTitle;
  final List<Map<String, dynamic>> quizzes;
  final VoidCallback onNext;
  final VoidCallback? onPrev;
  final VoidCallback onFinish; // Add this line
  final bool isLastPage;

  const QuizzesPage({
    super.key,
    required this.subject,
    required this.topic,
    required this.lessonTitle,
    required this.quizzes,
    required this.onNext,
    this.onPrev,
    required this.onFinish, // Add this line
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

  @override
  void initState() {
    super.initState();
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
    });
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

  @override
  Widget build(BuildContext context) {
    return _prefs == null
        ? const Center(child: CircularProgressIndicator())
        : Column(
            children: [
              if (!_isSubmitted)
                Expanded(
                  child: ListView.builder(
                    itemCount: widget.quizzes.length,
                    itemBuilder: (context, index) {
                      final quiz = widget.quizzes[index];
                      return Card(
                        child: ListTile(
                          title:
                              Text(quiz['question'] ?? 'No question provided'),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ...List.generate(quiz['choices']?.length ?? 0,
                                  (i) {
                                return RadioListTile<int>(
                                  title: Text(quiz['choices'][i] ??
                                      'No choice provided'),
                                  value: i,
                                  groupValue: _selectedAnswers[index],
                                  onChanged: (int? value) {
                                    setState(() {
                                      _selectedAnswers[index] = value;
                                    });
                                  },
                                );
                              }),
                            ],
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
                          style: const TextStyle(fontSize: 18),
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
                                    return Card(
                                      child: ListTile(
                                        title: Text(quiz['question'] ??
                                            'No question provided'),
                                        subtitle: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
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
                                    );
                                  },
                                ),
                              ),
                              ElevatedButton(
                                onPressed: widget.isLastPage
                                    ? widget.onFinish // Call onFinish if isLastPage is true
                                    : widget.onNext,
                                child: Text(widget.isLastPage ? 'Finish' : 'Next'),
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
                    if (widget.onPrev != null)
                      ElevatedButton(
                          onPressed: widget.onPrev, child: const Text('Prev')),
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
