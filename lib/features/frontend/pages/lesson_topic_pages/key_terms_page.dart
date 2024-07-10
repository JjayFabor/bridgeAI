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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              "Key Terms",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: keyTerms.length,
                itemBuilder: (context, index) {
                  final term = keyTerms.keys.elementAt(index);
                  final definition = keyTerms.values.elementAt(index);
                  return Column(
                    children: [
                      buildDictionaryEntry(term, definition),
                      if (index < keyTerms.length - 1) const Divider(),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton.icon(
                  onPressed: onPrev,
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Prev'),
                ),
                ElevatedButton.icon(
                  onPressed: onNext,
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

  Widget buildDictionaryEntry(String term, String definition) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 8.0),
      title: Text(
        term,
        style: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Color.fromARGB(255, 20, 20, 20),
        ),
      ),
      subtitle: Text(
        definition,
        style: const TextStyle(fontSize: 20, color: Colors.black87),
      ),
      leading: const Icon(Icons.book,
          size: 30, color: Color.fromARGB(255, 42, 43, 44)),
    );
  }
}
