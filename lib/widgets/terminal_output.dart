import 'package:flutter/material.dart';

class TerminalOutput extends StatelessWidget {
  const TerminalOutput({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final displayText = text
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: SelectableText(
        displayText.isEmpty ? 'Waiting for data...' : displayText,
        style: const TextStyle(fontFamily: 'monospace'),
      ),
    );
  }
}