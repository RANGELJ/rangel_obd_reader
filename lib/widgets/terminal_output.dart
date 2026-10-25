import 'package:flutter/material.dart';

class TerminalOutput extends StatelessWidget {
  const TerminalOutput({
    super.key,
    required this.text,
    this.timestamps = const {},
  });

  final String text;
  final Map<int, DateTime> timestamps;

  @override
  Widget build(BuildContext context) {
    final displayReplies = text.split('>').indexed
      .map((reply) => (
          timestamp: timestamps[reply.$1],
          text: reply.$2
            .replaceAll('\r\n', '\n')
            .replaceAll('\r', '\n')
            .trim(),
        ))
      .where((reply) => reply.text.isNotEmpty)
      .toList()
      .reversed
      .toList();

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: displayReplies.isEmpty ? 1 : displayReplies.length,
      separatorBuilder: (context, replyIndex) => const Divider(),
      itemBuilder: (context, replyIndex) {
        if (displayReplies.isEmpty) {
          return const SelectableText('Waiting for data...');
        }
        final reply = displayReplies[replyIndex];
        final timestamp = reply.timestamp;
        final timeLabel = timestamp == null
            ? '--:--:--'
            : timestamp.toIso8601String().substring(11, 23);
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: SelectableText(
                reply.text,
                style: const TextStyle(fontFamily: 'monospace'),
              ),
            ),
            const SizedBox(width: 16),
            Text(
              timeLabel,
              style: const TextStyle(fontFamily: 'monospace'),
            ),
          ],
        );
      },
    );
  }
}