import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:rangel_obd_reader/command_hold_controller.dart';
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

class _TerminalPageState extends State<TerminalPage> with WidgetsBindingObserver {
  static const _dataChannel = EventChannel('obd/bt/data');
  static const _commandChannel = MethodChannel('obd/bt');
  bool _sending = false;

  StreamSubscription<String>? _subscription;
  String _receivedText = '';
  final _replyTimestamps = <int, DateTime>{};
  final _replyCommands = <int, DiagnosticCommand>{};
  final _replyGroups = <int, int>{};
  CommandHoldController? _holdController;
  int? _heldReplyIndex;
  Completer<void>? _responseCompleter;
  int? _awaitingReplyIndex;

  bool get _busy => _sending || _holdController != null || _responseCompleter != null;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _subscription = _dataChannel.receiveBroadcastStream().cast<String>().listen(
      _receiveChunk,
      onError: _handleStreamError,
      onDone: _handleStreamDone,
    );
  }

  @override
  void reassemble() {
    super.reassemble();
    WidgetsBinding.instance.removeObserver(this);
    WidgetsBinding.instance.addObserver(this);
    _subscription?.onData(_receiveChunk);
    _subscription?.onError(_handleStreamError);
    _subscription?.onDone(_handleStreamDone);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) _cancelHold();
  }

  void _handleStreamError(Object error) {
    if (!mounted) return;
    _cancelHold();
    _failPendingResponse(error);
    setState(() => _appendReceivedText('\n[Channel error: $error]\n'));
  }

  void _handleStreamDone() {
    if (!mounted) return;
    _handleStreamError(PlatformException(
      code: 'disconnected',
      message: 'Adapter disconnected',
    ));
  }

  void _failPendingResponse(Object error) {
    final completer = _responseCompleter;
    _responseCompleter = null;
    _awaitingReplyIndex = null;
    if (completer != null && !completer.isCompleted) {
      completer.completeError(error);
    }
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
    final awaitingReplyIndex = _awaitingReplyIndex;
    if (awaitingReplyIndex != null &&
        '>'.allMatches(_receivedText).length > awaitingReplyIndex) {
      final completer = _responseCompleter;
      _responseCompleter = null;
      _awaitingReplyIndex = null;
      if (completer != null && !completer.isCompleted) completer.complete();
    }
  }

  Future<void> _selectCommand(Widget commandsPage) async {
    if (_busy) return;
    setState(() => _sending = true);
    try {
      final command = await Navigator.of(context).push<DiagnosticCommand>(
        MaterialPageRoute<DiagnosticCommand>(
          builder: (context) => commandsPage,
        ),
      );

      if (!mounted || command == null) return;

      await _sendCommand(command);
    } catch (error) {
      _showCommandError(error);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _sendCommand(DiagnosticCommand command, {int? groupIndex}) async {
    final isValidCommand = DiagnosticCommand.scannerCommands
        .followedBy(DiagnosticCommand.carCommands)
        .any((declaredCommand) => declaredCommand.command == command.command);
    if (!isValidCommand) {
      throw PlatformException(code: 'command_blocked', message: 'Invalid command');
    }
    if (_responseCompleter != null) {
      throw PlatformException(code: 'busy', message: 'Wait for the adapter reply');
    }

    final replyIndex = '>'.allMatches(_receivedText).length;
    final completer = Completer<void>();
    setState(() {
      _replyCommands[replyIndex] = command;
      if (groupIndex != null) _replyGroups[replyIndex] = groupIndex;
      _responseCompleter = completer;
      _awaitingReplyIndex = replyIndex;
    });
    try {
      await Future.wait<void>([
        _commandChannel.invokeMethod<void>('sendCommand', {
          'command': command.command,
        }),
        completer.future,
      ], eagerError: true).timeout(const Duration(seconds: 10));
    } on TimeoutException {
      rethrow;
    } catch (error) {
      if (identical(_responseCompleter, completer)) {
        _responseCompleter = null;
        _awaitingReplyIndex = null;
        if (!completer.isCompleted) completer.complete();
      }
      rethrow;
    } finally {
      if (mounted) setState(() {});
    }
  }

  void _startHold(DiagnosticCommand command, int replyIndex) {
    if (_busy) return;
    late final CommandHoldController controller;
    controller = CommandHoldController(
      onRead: () => _sendCommand(command, groupIndex: replyIndex),
      onStopped: () {
        if (!mounted || !identical(_holdController, controller)) return;
        setState(() {
          _holdController = null;
          _heldReplyIndex = null;
        });
      },
      onError: _showCommandError,
    );
    setState(() {
      _holdController = controller;
      _heldReplyIndex = replyIndex;
    });
    controller.start();
  }

  void _cancelHold() => _holdController?.cancel();

  void _showCommandError(Object error) {
    if (!mounted) return;
    final message = error is PlatformException
        ? error.message ?? error.code
        : error is TimeoutException
            ? 'Adapter reply timed out. Wait for its prompt or reconnect.'
            : error.toString();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    final controller = _holdController;
    _holdController = null;
    controller?.cancel();
    _failPendingResponse(StateError('Terminal closed'));
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
                    onPressed: _busy
                        ? null
                        : () => _selectCommand(const ScannerCommandsPage()),
                    child: const Text('To scanner'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _busy
                        ? null
                        : () => _selectCommand(const CarCommandsPage()),
                    child: const Text('To car'),
                  ),
                ),
              ],
            ),
          ),
          if (_holdController != null)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: _cancelHold,
                icon: const Icon(Icons.stop),
                label: const Text('Cancel reading'),
              ),
            ),
          if (_holdController == null && _responseCompleter != null)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text('Waiting for adapter response...'),
            ),
                Expanded(
                  child: TerminalOutput(
                    text: _receivedText,
                    timestamps: _replyTimestamps,
                    commands: _replyCommands,
                    replyGroups: _replyGroups,
                    activeReplyIndex: _heldReplyIndex,
                    actionsEnabled: !_busy,
                    onHold: _startHold,
                    onCancelHold: _cancelHold,
                  ),
                ),
        ],
    ),
    );
  }
}