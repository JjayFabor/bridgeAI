import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_math_fork/flutter_math.dart';

class ExplanationPage extends StatelessWidget {
  final String lessonTitle;
  final String content;
  final VoidCallback onNext;
  final VoidCallback? onPrev;

  const ExplanationPage({
    super.key,
    required this.lessonTitle,
    required this.content,
    required this.onNext,
    this.onPrev,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              lessonTitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16.0),
            Expanded(child: parseMarkdownWithMath(context, content)),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (onPrev != null)
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
              textStyle: const TextStyle(fontSize: 24));
        } else if (element.startsWith(r'$') && element.endsWith(r'$')) {
          return Math.tex(element.substring(1, element.length - 1),
              textStyle: const TextStyle(fontSize: 24));
        } else {
          return MarkdownBody(
            data: element,
            styleSheet:
                MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
              p: const TextStyle(fontSize: 20),
              // h1: const TextStyle(fontSize: 24),
              // h2: const TextStyle(fontSize: 24),
              // h3: const TextStyle(fontSize: 24),
              // h4: const TextStyle(fontSize: 24),
              // h5: const TextStyle(fontSize: 24),
              // h6: const TextStyle(fontSize: 24),
              // strong: const TextStyle(fontSize: 24),
              // code: const TextStyle(fontSize: 24),
              // blockquote: const TextStyle(fontSize: 24),
              // // Add more styles if needed
            ),
          );
        }
      }).toList(),
    );
  }
}
