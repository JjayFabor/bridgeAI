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
      appBar: AppBar(title: Text(lessonTitle)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: parseMarkdownWithMath(content)),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (onPrev != null)
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
