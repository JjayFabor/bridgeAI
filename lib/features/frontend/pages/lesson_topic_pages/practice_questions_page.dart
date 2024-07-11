import 'package:flutter/material.dart';
import 'package:flip_card/flip_card.dart';

class PracticeQuestionsPage extends StatefulWidget {
  final List<Map<String, dynamic>> questions;
  final VoidCallback onNext;
  final VoidCallback onPrev;

  const PracticeQuestionsPage({
    super.key,
    required this.questions,
    required this.onNext,
    required this.onPrev,
  });

  @override
  State<PracticeQuestionsPage> createState() => _PracticeQuestionsPageState();
}

class _PracticeQuestionsPageState extends State<PracticeQuestionsPage> {
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              "Practice Questions",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: widget.questions.length,
                itemBuilder: (context, index) {
                  final question = widget.questions[index];
                  return buildFlipCard(
                    question['question'] as String,
                    question['answer'] as String,
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    if (_pageController.page?.toInt() != 0) {
                      _pageController.previousPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    } else {
                      widget.onPrev();
                    }
                  },
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Prev'),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    if (_pageController.page?.toInt() !=
                        widget.questions.length - 1) {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    } else {
                      widget.onNext();
                    }
                  },
                  icon: const Icon(Icons.arrow_forward),
                  label: const Text('Next'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget buildFlipCard(String question, String answer) {
    return Center(
      child: SizedBox(
        width: 350,
        height: 250,
        child: Card(
          shadowColor: Colors.black87,
          color: const Color.fromARGB(255, 88, 83, 83),
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: FlipCard(
            direction: FlipDirection.HORIZONTAL,
            front: Container(
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 88, 83, 83),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    spreadRadius: 2,
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(16.0),
              child: Center(
                child: Text(
                  question,
                  style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
              ),
            ),
            back: Container(
              decoration: BoxDecoration(
                color: Colors.white,
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
              padding: const EdgeInsets.all(16.0),
              child: Center(
                child: Text(
                  answer,
                  style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: Colors.black),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
