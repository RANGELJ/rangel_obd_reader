import 'package:flutter/material.dart';

class CommandInput extends StatefulWidget {
  const CommandInput({
    super.key,
    required this.sending,
    required this.onSend,
  });

  final bool sending;
  final ValueChanged<String> onSend;

  @override
  State<CommandInput> createState() => _CommandInputState();
}

class _CommandInputState extends State<CommandInput> {
  String _selectedTarget = 'AT';
  String _selectedCommand = 'I';

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: DropdownButton<String>(
                value: _selectedTarget,
                isExpanded: true,
                items: const [
                  DropdownMenuItem(value: 'AT', child: Text('AT - Scanner')),
                ],
                onChanged: widget.sending ? null : (selection) {
                  if (selection == null) return;
                  setState(() => _selectedTarget = selection);
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: DropdownButton<String>(
                value: _selectedCommand,
                isExpanded: true,
                items: const [
                  DropdownMenuItem(value: 'I', child: Text('I - Identify')),
                  DropdownMenuItem(value: 'E0', child: Text('E0 - Echo off')),
                  DropdownMenuItem(
                    value: 'DP',
                    child: Text('DP - Current protocol', overflow: TextOverflow.ellipsis),
                  ),
                  DropdownMenuItem(
                    value: 'SP6',
                    child: Tooltip(
                      message: 'CAN 11/500 - compatible with the 2012 Ford Fiesta',
                      child: Text('SP6 - Fiesta', overflow: TextOverflow.ellipsis),
                    ),
                  ),
                ],
                onChanged: widget.sending ? null : (selection) {
                  if (selection == null) return;
                  setState(() => _selectedCommand = selection);
                },
              ),
            ),
            IconButton(
              tooltip: 'Send command',
              onPressed: widget.sending
                  ? null
                  : () => widget.onSend('$_selectedTarget$_selectedCommand'),
              icon: const Icon(Icons.send),
            ),
          ],
        ),
      ),
    );
  }
}