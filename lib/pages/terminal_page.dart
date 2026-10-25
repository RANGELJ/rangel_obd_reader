import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:rangel_obd_reader/widgets/command_input.dart';
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

  Future<void> _sendCommand(String command) async {
    setState(() => _sending = true);
    try {
        await _commandChannel.invokeMethod<void>('sendCommand', {
            'command': command,
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.deviceName)),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CommandInput(
            sending: _sending,
            onSend: _sendCommand,
            ),
                Expanded(
                  child: TerminalOutput(
                    text: _receivedText,
                    timestamps: _replyTimestamps,
                  ),
                ),
        ],
    ),
    );
  }
}