import 'package:flutter/material.dart';
import 'package:rangel_obd_reader/models/diagnostic_command.dart';
import 'package:rangel_obd_reader/widgets/command_list_item.dart';

class ScannerCommandsPage extends StatelessWidget {
  const ScannerCommandsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scanner commands')),
      body: ListView.separated(
        itemCount: DiagnosticCommand.scannerCommands.length,
        separatorBuilder: (context, commandIndex) => const Divider(),
        itemBuilder: (context, commandIndex) {
          final command = DiagnosticCommand.scannerCommands[commandIndex];
          return CommandListItem(
            command: command,
            onTap: () => Navigator.of(context).pop(command),
          );
        },
      ),
    );
  }
}