import 'package:flutter/material.dart';

class KeyTermsPage extends StatelessWidget {
  final Map<String, String> keyTerms;
  final VoidCallback onNext;
  final VoidCallback onPrev;
  final bool isLastPage;

  const KeyTermsPage({
    super.key,
    required this.keyTerms,
    required this.onNext,
    required this.onPrev,
    this.isLastPage = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Key Terms')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: keyTerms.length,
                itemBuilder: (context, index) {
                  final term = keyTerms.keys.elementAt(index);
                  final definition = keyTerms.values.elementAt(index);
                  return buildFlashCard(term, definition);
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  onPressed: onPrev,
                  child: const Text('Prev'),
                ),
                ElevatedButton(
                  onPressed: isLastPage
                      ? () => _showCompletionMessage(context)
                      : onNext,
                  child: Text(isLastPage ? 'Complete' : 'Next'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showCompletionMessage(BuildContext context) {
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

  Widget buildFlashCard(String term, String definition) {
    return Card(
      elevation: 4,
      child: ListTile(
        title: Text(
          term,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        subtitle: Text(definition, style: const TextStyle(fontSize: 16)),
        leading: const Icon(Icons.book, size: 50),
      ),
    );
  }
}
