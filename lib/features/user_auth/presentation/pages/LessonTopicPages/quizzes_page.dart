import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class QuizzesPage extends StatefulWidget {
  final List<Map<String, dynamic>> quizzes;
  final VoidCallback onNext;
  final VoidCallback? onPrev;
  final bool isLastPage;

  const QuizzesPage({
    super.key,
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

  @override
  void initState() {
    super.initState();
    _initializeQuiz();
  }

  Future<void> _initializeQuiz() async {
    _prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedAnswers = List<int?>.filled(widget.quizzes.length, null);
      _isSubmitted = false;
      _correctAnswers = 0;
    });
  }

  void _submitQuiz() async {
    int correctAnswers = 0;
    for (int i = 0; i < widget.quizzes.length; i++) {
      if (_selectedAnswers[i] != null &&
          widget.quizzes[i]['choices'][_selectedAnswers[i]] ==
              widget.quizzes[i]['answer']) {
        correctAnswers++;
      }
    }
    setState(() {
      _correctAnswers = correctAnswers;
      _isSubmitted = true;
    });
    await _saveQuizState();
  }

  Future<void> _retakeQuiz() async {
    setState(() {
      _selectedAnswers = List<int?>.filled(widget.quizzes.length, null);
      _isSubmitted = false;
      _correctAnswers = 0;
    });
    await _prefs?.remove('isSubmitted');
    await _prefs?.remove('correctAnswers');
  }

  Future<void> _saveQuizState() async {
    await _prefs?.setBool('isSubmitted', _isSubmitted);
    await _prefs?.setInt('correctAnswers', _correctAnswers);
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
                                    final isCorrect =
                                        _selectedAnswers[index] != null &&
                                            quiz['choices']
                                                    [_selectedAnswers[index]] ==
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
                                              'Your answer: ${_selectedAnswers[index] != null ? quiz['choices'][_selectedAnswers[index]] : 'No answer provided'}',
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
