import 'package:flutter/material.dart';
import 'package:rangel_obd_reader/models/diagnostic_command.dart';
import 'package:rangel_obd_reader/widgets/command_list_item.dart';

class TerminalOutput extends StatelessWidget {
  const TerminalOutput({
    super.key,
    required this.text,
    this.timestamps = const {},
    this.commands = const {},
  });

  final String text;
  final Map<int, DateTime> timestamps;
  final Map<int, DiagnosticCommand> commands;

  @override
  Widget build(BuildContext context) {
    final replies = text.split('>');
    final displayReplies = replies.indexed
      .map((reply) => (
          command: commands[reply.$1],
          isComplete: reply.$1 < replies.length - 1,
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
        final timestampWidget = Text(
          timeLabel,
          style: const TextStyle(fontFamily: 'monospace'),
        );
        final response = SelectableText(
          reply.text,
          style: const TextStyle(fontFamily: 'monospace'),
        );
        final command = reply.command;
        if (command != null) {
          return CommandListItem(
            command: command,
            timestamp: timestampWidget,
            response: command.renderResponse(
              reply.text,
              isComplete: reply.isComplete,
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 8),
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: response,
            ),
            const SizedBox(width: 16),
            timestampWidget,
          ],
        );
      },
    );
  }
}