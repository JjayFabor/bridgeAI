import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class QuizzesPage extends StatefulWidget {
  final String lessonTitle;
  final List<Map<String, dynamic>> quizzes;
  final VoidCallback onNext;
  final VoidCallback? onPrev;
  final bool isLastPage;

  const QuizzesPage({
    super.key,
    required this.lessonTitle,
    required this.quizzes,
    required this.onNext,
    this.onPrev,
    required this.isLastPage,
  });

  @override
  State<QuizzesPage> createState() => _QuizzesPageState();
}

class _QuizzesPageState extends State<QuizzesPage> {
  late List<int?> _selectedAnswers;
  bool _isSubmitted = false;
  int _correctAnswers = 0;
  SharedPreferences? _prefs;
  String? _username;

  @override
  void initState() {
    super.initState();
    _initializeQuiz();
  }

  Future<void> _initializeQuiz() async {
    _prefs = await SharedPreferences.getInstance();
    _username = _prefs?.getString('username');

    _selectedAnswers = List<int?>.filled(widget.quizzes.length, null);
    _isSubmitted = false;
    _correctAnswers = 0;

    // Load saved state
    _loadQuizState();
  }

  void _loadQuizState() async {
    final savedAnswers =
        _prefs?.getStringList('$_username-${widget.lessonTitle}-answers');
    final savedIsSubmitted =
        _prefs?.getBool('$_username-${widget.lessonTitle}-isSubmitted');
    final savedCorrectAnswers =
        _prefs?.getInt('$_username-${widget.lessonTitle}-correctAnswers');

    if (savedAnswers != null) {
      setState(() {
        _selectedAnswers =
            savedAnswers.map((e) => e.isEmpty ? null : int.parse(e)).toList();
      });
    }

    if (savedIsSubmitted != null) {
      setState(() {
        _isSubmitted = savedIsSubmitted;
      });
    }

    if (savedCorrectAnswers != null) {
      setState(() {
        _correctAnswers = savedCorrectAnswers;
      });
    }
  }

  void _submitQuiz() async {
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
    if (_username != null) {
      await _saveLessonScore(widget.lessonTitle, _username!, correctAnswers);
    }
  }

  Future<void> _saveLessonScore(
      String lessonTitle, String username, int score) async {
    await _prefs?.setInt('$username-$lessonTitle-score', score);
    await _prefs?.setString(
        '$username-$lessonTitle-timestamp', DateTime.now().toString());

    // Save the lesson title
    List<String>? lessonTitles =
        _prefs?.getStringList('$username-lessonTitles') ?? [];
    if (!lessonTitles.contains(lessonTitle)) {
      lessonTitles.add(lessonTitle);
      await _prefs?.setStringList('$username-lessonTitles', lessonTitles);
    }
  }

  Future<void> _retakeQuiz() async {
    setState(() {
      _selectedAnswers = List<int?>.filled(widget.quizzes.length, null);
      _isSubmitted = false;
      _correctAnswers = 0;
    });
    await _prefs?.remove('$_username-${widget.lessonTitle}-answers');
    await _prefs?.remove('$_username-${widget.lessonTitle}-isSubmitted');
    await _prefs?.remove('$_username-${widget.lessonTitle}-correctAnswers');
  }

  Future<void> _saveQuizState() async {
    await _prefs?.setStringList('$_username-${widget.lessonTitle}-answers',
        _selectedAnswers.map((e) => e?.toString() ?? '').toList());
    await _prefs?.setBool(
        '$_username-${widget.lessonTitle}-isSubmitted', _isSubmitted);
    await _prefs?.setInt(
        '$_username-${widget.lessonTitle}-correctAnswers', _correctAnswers);
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
                                onPressed: widget.onNext,
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
