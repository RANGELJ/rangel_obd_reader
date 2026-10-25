import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:rangel_obd_reader/models/diagnostic_command.dart';
import 'package:rangel_obd_reader/pages/car_commands_page.dart';
import 'package:rangel_obd_reader/pages/scanner_commands_page.dart';
import 'package:rangel_obd_reader/widgets/terminal_output.dart';

class TerminalPage extends StatefulWidget {
  const TerminalPage({super.key, required this.deviceName});

  final String deviceName;

  @override
  State<TerminalPage> createState() => _TerminalPageState();
}

class _TerminalPageState extends State<TerminalPage> {
  static const _dataChannel = EventChannel('obd/bt/data');
  static const _commandChannel = MethodChannel('obd/bt');
  bool _sending = false;

  StreamSubscription<String>? _subscription;
  String _receivedText = '';
  final _replyTimestamps = <int, DateTime>{};
  final _replyCommands = <int, DiagnosticCommand>{};

  @override
  void initState() {
    super.initState();
    _subscription = _dataChannel.receiveBroadcastStream().cast<String>().listen(
      _receiveChunk,
      onError: (Object error) {
        if (!mounted) return;
        setState(() => _appendReceivedText('\n[Channel error: $error]\n'));
      },
    );
  }

  @override
  void reassemble() {
    super.reassemble();
    _subscription?.onData(_receiveChunk);
  }

  void _receiveChunk(String chunk) {
    if (kDebugMode) {
      debugPrint('[OBD RX] ${jsonEncode(chunk)}');
    }
    if (!mounted) return;
    setState(() => _appendReceivedText(chunk));
  }

  void _appendReceivedText(String chunk) {
    var replyIndex = '>'.allMatches(_receivedText).length;
    final receivedAt = DateTime.now();
    for (final part in chunk.split('>')) {
      if (part.trim().isNotEmpty) {
        _replyTimestamps.putIfAbsent(replyIndex, () => receivedAt);
      }
      replyIndex++;
    }
    _receivedText += chunk;
  }

  Future<void> _selectCommand(Widget commandsPage) async {
    if (_sending) return;
    setState(() => _sending = true);
    try {
      final command = await Navigator.of(context).push<DiagnosticCommand>(
        MaterialPageRoute<DiagnosticCommand>(
          builder: (context) => commandsPage,
        ),
      );

      if (!mounted || command == null) return;

      final isValidCommand = DiagnosticCommand.scannerCommands
          .followedBy(DiagnosticCommand.carCommands)
          .any((declaredCommand) => declaredCommand.command == command.command);
      if (!isValidCommand) {
        throw PlatformException(
          code: 'command_blocked',
          message: 'Invalid command',
        );
      }

      var replyIndex = '>'.allMatches(_receivedText).length;
      while (_replyCommands.containsKey(replyIndex)) {
        replyIndex++;
      }
      await _commandChannel.invokeMethod<void>('sendCommand', {
        'command': command.command,
      });
      if (!mounted) return;
      setState(() => _replyCommands[replyIndex] = command);
    } on PlatformException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message ?? error.code)),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.deviceName)),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _sending
                        ? null
                        : () => _selectCommand(const ScannerCommandsPage()),
                    child: const Text('To scanner'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _sending
                        ? null
                        : () => _selectCommand(const CarCommandsPage()),
                    child: const Text('To car'),
                  ),
                ),
              ],
            ),
          ),
                Expanded(
                  child: TerminalOutput(
                    text: _receivedText,
                    timestamps: _replyTimestamps,
                    commands: _replyCommands,
                  ),
                ),
        ],
    ),
    );
  }
}