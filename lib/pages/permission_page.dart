import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rangel_obd_reader/pages/devices_page.dart';

enum BtPermission { unknown, granted, denied, error }

class PermissionPage extends StatefulWidget {
  const PermissionPage({super.key});

  @override
  State<PermissionPage> createState() => _PermissionPageState();
}

class _PermissionPageState extends State<PermissionPage> {
  static const _channel = MethodChannel('obd/bt');
  BtPermission permission = BtPermission.unknown;
  String? errorMessage;

  Future<void> request() async {
    try {
      final granted = await _channel.invokeMethod<bool>('requestPermission') ?? false;
      setState(() {
        permission = granted ? BtPermission.granted : BtPermission.denied;
        errorMessage = null;
      });
    } on PlatformException catch (e) {
      setState(() {
        permission = BtPermission.error;
        errorMessage = e.message;
      });
    }
  }

  String get label => switch (permission) {
        BtPermission.unknown => 'not asked yet',
        BtPermission.granted => 'granted',
        BtPermission.denied => 'denied',
        BtPermission.error => 'error: $errorMessage',
      };

  void openDevices() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const DevicesPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Rangel OBD Prototype MK1')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: const TextStyle(fontSize: 24)),
            if (permission == BtPermission.granted) ...[
              const SizedBox(height: 24),
              FilledButton(onPressed: openDevices, child: const Text('Continue')),
            ],
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: request,
        label: const Text('Request permission'),
      ),
    );
  }
}