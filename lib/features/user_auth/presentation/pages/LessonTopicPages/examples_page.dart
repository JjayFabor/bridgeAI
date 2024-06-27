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
      appBar: AppBar(title: const Text('Examples')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: examples.length,
                itemBuilder: (context, index) {
                  final example = examples[index];
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        example['title'] as String,
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 5),
                      parseMarkdownWithMath(example['content'] as String),
                      const SizedBox(height: 5),
                      Text(example['explanation'] as String),
                      const SizedBox(height: 20),
                    ],
                  );
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
                  onPressed: onNext,
                  child: const Text('Next'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget parseMarkdownWithMath(String content) {
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
          return MarkdownBody(data: element);
        }
      }).toList(),
    );
  }
}