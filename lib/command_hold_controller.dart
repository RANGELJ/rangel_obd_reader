import 'dart:async';

class CommandHoldController {
  CommandHoldController({
    required this.onRead,
    required this.onStopped,
    required this.onError,
    this.interval = const Duration(seconds: 1),
  });

  final Future<void> Function() onRead;
  final void Function() onStopped;
  final void Function(Object error) onError;
  final Duration interval;

  Timer? _intervalTimer;
  bool _active = false;
  bool _reading = false;

  bool get isActive => _active;

  void start() {
    if (_active || _reading) return;
    _active = true;
    _intervalTimer = Timer.periodic(interval, (timer) => _read());
    unawaited(_read());
  }

  Future<void> _read() async {
    if (!_active || _reading) return;
    _reading = true;
    try {
      await onRead();
    } catch (error) {
      if (_active) {
        cancel();
        onError(error);
      }
    } finally {
      _reading = false;
    }
  }

  void cancel() {
    if (!_active) return;
    _active = false;
    _intervalTimer?.cancel();
    onStopped();
  }
}