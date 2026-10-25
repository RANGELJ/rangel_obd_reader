import 'package:flutter/material.dart';
import 'package:rangel_obd_reader/models/diagnostic_command.dart';

class CommandListItem extends StatelessWidget {
  const CommandListItem({
    super.key,
    required this.command,
    this.timestamp,
    this.response,
    this.actions,
    this.onTap,
    this.contentPadding = const EdgeInsets.symmetric(
      horizontal: 16,
      vertical: 8,
    ),
  });

  final DiagnosticCommand command;
  final Widget? timestamp;
  final Widget? response;
  final Widget? actions;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry contentPadding;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: contentPadding,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  command.command,
                  style: const TextStyle(fontFamily: 'monospace'),
                ),
              ),
              if (timestamp != null) ...[
                const SizedBox(width: 16),
                timestamp!,
              ],
            ],
          ),
          Text(command.name),
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(command.description),
          if (response != null) ...[
            const SizedBox(height: 8),
            response!,
          ],
          if (actions != null) ...[
            const SizedBox(height: 8),
            actions!,
          ],
        ],
      ),
      onTap: onTap,
    );
  }
}