import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';
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
  final _commandController = TextEditingController();
  bool _sending = false;

  StreamSubscription<String>? _subscription;
  String _receivedText = '';

  @override
  void initState() {
    super.initState();
    _subscription = _dataChannel.receiveBroadcastStream().cast<String>().listen(
      (String chunk) {
        if (kDebugMode) {
            debugPrint('[OBD RX] ${jsonEncode(chunk)}');
        }
        if (!mounted) return;
        setState(() => _receivedText += chunk);
      },
      onError: (Object error) {
        if (!mounted) return;
        setState(() => _receivedText += '\n[Channel error: $error]\n');
      },
    );
  }

  Future<void> _sendCommand() async {
    setState(() => _sending = true);
    try {
        await _commandChannel.invokeMethod<void>('sendCommand', {
            'command': _commandController.text,
        });
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
    _commandController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.deviceName)),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
            Expanded(
                child: TerminalOutput(text: _receivedText),
            ),
            SafeArea(
                top: false,
                child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                    children: [
                        Expanded(
                            child: TextField(
                                controller: _commandController,
                                autocorrect: false,
                                enableSuggestions: false,
                                decoration: const InputDecoration(labelText: 'Command'),
                            ),
                        ),
                        IconButton(
                        tooltip: 'Send command',
                        onPressed: _sending ? null : _sendCommand,
                        icon: const Icon(Icons.send),
                        ),
                    ],
                    ),
                ),
            ),
        ],
    ),
    );
  }
}