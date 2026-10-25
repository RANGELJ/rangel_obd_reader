import 'package:flutter/material.dart';

class TerminalPage extends StatelessWidget {
  const TerminalPage({super.key, required this.deviceName});

  final String deviceName;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(deviceName)),
      body: const Center(child: Text('terminal goes here')),
    );
  }
}