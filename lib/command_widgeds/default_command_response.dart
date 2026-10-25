import 'package:flutter/material.dart';

class DefaultCommandResponse extends StatelessWidget {
  const DefaultCommandResponse(this.response, {super.key});

  final String response;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        border: Border(
          left: BorderSide(
            color: Theme.of(context).colorScheme.outlineVariant,
            width: 3,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Response', style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: 4),
          SelectableText(
            response,
            style: const TextStyle(fontFamily: 'monospace'),
          ),
        ],
      ),
    );
  }
}