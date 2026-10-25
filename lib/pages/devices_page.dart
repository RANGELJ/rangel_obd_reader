import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rangel_obd_reader/pages/terminal_page.dart';

enum LoadStatus { loading, ready, error }

class BluetoothDevice {
  const BluetoothDevice({ required this.name, required this.address });
  final String? name;
  final String address;
}

class DevicesPage extends StatefulWidget {
  const DevicesPage({super.key});

  @override
  State<DevicesPage> createState() => _DevicesPageState();
}

class _DevicesPageState extends State<DevicesPage> {
  static const _channel = MethodChannel('obd/bt');
  LoadStatus status = LoadStatus.loading;
  List<BluetoothDevice> devices = [];
  String? errorMessage;
  String? connectingAddress;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    setState(() => status = LoadStatus.loading);
    try {
      final raw = await _channel.invokeListMethod<Map>('getBondedDevices') ?? [];
      if (!mounted) return;
      setState(() {
        devices = [
          for (final d in raw)
            BluetoothDevice(name: d['name'] as String?, address: d['address'] as String),
        ];
        status = LoadStatus.ready;
      });
    } on PlatformException catch (e) {
      if (!mounted) return;
      setState(() {
        errorMessage = e.message;
        status = LoadStatus.error;
      });
    }
  }

  Future<void> connect(BluetoothDevice d) async {
    setState(() => connectingAddress = d.address);
    try {
      await _channel.invokeMethod('connectDevice', {'address': d.address});
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => TerminalPage(deviceName: d.name ?? d.address),
        ),
      );
    } on PlatformException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Connect failed: ${e.message}')),
      );
    } finally {
      if (mounted) setState(() => connectingAddress = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Paired devices'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: load),
        ],
      ),
      body: switch (status) {
        LoadStatus.loading => const Center(child: CircularProgressIndicator()),
        LoadStatus.error => Center(child: Text(errorMessage ?? 'unknown error')),
        LoadStatus.ready => devices.isEmpty
          ? const Center(child: Text('No paired devices. Pair your adapter in Android settings.'))
          : ListView.builder(
              itemCount: devices.length,
              itemBuilder: (context, i) {
                final d = devices[i];
                return ListTile(
                  title: Text(d.name ?? '(no name)'),
                  subtitle: Text(d.address),
                  trailing: connectingAddress == d.address
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : null,
                  onTap: connectingAddress == null ? () => connect(d) : null,
                );
              },
            ),
      },
    );
  }
}