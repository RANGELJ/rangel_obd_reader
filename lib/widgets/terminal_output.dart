import 'package:flutter/material.dart';
import 'package:rangel_obd_reader/models/diagnostic_command.dart';
import 'package:rangel_obd_reader/widgets/command_list_item.dart';
import 'package:rangel_obd_reader/widgets/pulsing_command_item.dart';

class TerminalOutput extends StatelessWidget {
  const TerminalOutput({
    super.key,
    required this.text,
    this.timestamps = const {},
    this.commands = const {},
    this.replyGroups = const {},
    this.activeReplyIndex,
    this.actionsEnabled = true,
    this.onHold,
    this.onCancelHold,
  });

  final String text;
  final Map<int, DateTime> timestamps;
  final Map<int, DiagnosticCommand> commands;
  final Map<int, int> replyGroups;
  final int? activeReplyIndex;
  final bool actionsEnabled;
  final void Function(DiagnosticCommand command, int replyIndex)? onHold;
  final VoidCallback? onCancelHold;

  @override
  Widget build(BuildContext context) {
    final replies = text.split('>');
    final groupedReplies = <int, ({
      DiagnosticCommand? command,
      bool isComplete,
      DateTime? timestamp,
      String text,
    })>{};
    for (final reply in replies.indexed) {
      final replyText = reply.$2
          .replaceAll('\r\n', '\n')
          .replaceAll('\r', '\n')
          .trim();
      if (replyText.isEmpty) continue;
      final groupIndex = replyGroups[reply.$1] ?? reply.$1;
      groupedReplies[groupIndex] = (
        command: commands[reply.$1] ?? commands[groupIndex],
        isComplete: reply.$1 < replies.length - 1,
        timestamp: timestamps[reply.$1],
        text: replyText,
      );
    }
    final displayReplies = groupedReplies.entries.toList()
      ..sort((firstReply, secondReply) => secondReply.key.compareTo(firstReply.key));

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: displayReplies.isEmpty ? 1 : displayReplies.length,
      separatorBuilder: (context, replyIndex) => const Divider(),
      itemBuilder: (context, replyIndex) {
        if (displayReplies.isEmpty) {
          return const SelectableText('Waiting for data...');
        }
        final entry = displayReplies[replyIndex];
        final reply = entry.value;
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
          final active = entry.key == activeReplyIndex;
          return PulsingCommandItem(
            key: ValueKey(entry.key),
            active: active,
            child: CommandListItem(
              command: command,
              timestamp: timestampWidget,
              response: command.renderResponse(
                reply.text,
                isComplete: reply.isComplete,
              ),
              actions: Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: active
                      ? onCancelHold
                      : actionsEnabled && reply.isComplete && onHold != null
                          ? () => onHold!(command, entry.key)
                          : null,
                  icon: Icon(active ? Icons.stop : Icons.repeat),
                  label: Text(active ? 'Cancel reading' : 'Hold reading'),
                ),
              ),
              contentPadding: const EdgeInsets.all(8),
            ),
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