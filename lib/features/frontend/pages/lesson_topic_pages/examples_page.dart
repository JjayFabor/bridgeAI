import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_math_fork/flutter_math.dart';

class ExamplesPage extends StatelessWidget {
  final List<Map<String, dynamic>> examples;
  final VoidCallback onNext;
  final VoidCallback onPrev;

  const ExamplesPage({
    super.key,
    required this.examples,
    required this.onNext,
    required this.onPrev,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Center(
              child: Text(
                "Examples",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: examples.length,
                itemBuilder: (context, index) {
                  final example = examples[index];
                  return Card(
                    elevation: 4,
                    margin: const EdgeInsets.symmetric(vertical: 8.0),
                    child: ExpansionTile(
                      leading: const Icon(Icons.lightbulb_outline),
                      title: Text(
                        example['title'] as String,
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              parseMarkdownWithMath(
                                  context, example['content'] as String),
                              const SizedBox(height: 10),
                              Text(
                                example['explanation'] as String,
                                style: const TextStyle(fontSize: 18),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
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

  Widget parseMarkdownWithMath(BuildContext context, String content) {
    final elements = content.split(RegExp(r'(\$\$.*?\$\$|\$.*?\$)'));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: elements.map((element) {
        if (element.startsWith(r'$$') && element.endsWith(r'$$')) {
          return Math.tex(element.substring(2, element.length - 2),
              textStyle: const TextStyle(fontSize: 18));
        } else if (element.startsWith(r'$') && element.endsWith(r'$')) {
          return Math.tex(element.substring(1, element.length - 1),
              textStyle: const TextStyle(fontSize: 18));
        } else {
          return MarkdownBody(
            data: element,
            styleSheet:
                MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
              p: const TextStyle(fontSize: 20),
              h1: const TextStyle(fontSize: 24),
            ),
          );
        }
      }).toList(),
    );
  }
}
