import 'package:flutter/material.dart';
import 'package:rangel_obd_reader/command_widgeds/default_command_response.dart';
import 'package:rangel_obd_reader/command_widgeds/mode_one_payload.dart';

class MonitorStatusResponse extends StatelessWidget {
  const MonitorStatusResponse({
    super.key,
    required this.response,
    required this.identifier,
  });

  final String response;
  final int identifier;

  static const _continuousMonitors = [
    'Misfire',
    'Fuel system',
    'Comprehensive components',
  ];
  static const _sparkMonitors = [
    'Catalyst',
    'Heated catalyst',
    'Evaporative system',
    'Secondary air system',
    'Gasoline particulate filter',
    'Oxygen sensor',
    'Oxygen sensor heater',
    'EGR / variable valve timing',
  ];
  static const _compressionMonitors = [
    'Non-methane hydrocarbon catalyst',
    'NOx / SCR aftertreatment',
    null,
    'Boost pressure',
    null,
    'Exhaust gas sensor',
    'Particulate filter',
    'EGR / variable valve timing',
  ];

  List<int>? get data {
    final payload = parseModeOnePayload(response, identifier);
    if (payload == null || (identifier == 0x41 && payload[0] != 0)) return null;
    return payload;
  }

  bool? get malfunctionLightOn {
    final payload = data;
    if (identifier != 0x01 || payload == null) return null;
    return (payload[0] & 0x80) != 0;
  }

  int? get storedCodeCount {
    final payload = data;
    if (identifier != 0x01 || payload == null) return null;
    return payload[0] & 0x7F;
  }

  List<({String name, bool? complete})>? get monitors {
    final payload = data;
    if (payload == null) return null;
    final statuses = <({String name, bool? complete})>[];
    for (var monitorIndex = 0; monitorIndex < 3; monitorIndex++) {
      statuses.add((
        name: _continuousMonitors[monitorIndex],
        complete: (payload[1] & (1 << monitorIndex)) == 0
            ? null
            : (payload[1] & (1 << (monitorIndex + 4))) == 0,
      ));
    }

    final monitorNames = (payload[1] & 0x08) == 0
        ? _sparkMonitors
        : _compressionMonitors;
    for (var monitorIndex = 0; monitorIndex < 8; monitorIndex++) {
      final name = monitorNames[monitorIndex];
      if (name == null) continue;
      statuses.add((
        name: name,
        complete: (payload[2] & (1 << monitorIndex)) == 0
            ? null
            : (payload[3] & (1 << monitorIndex)) == 0,
      ));
    }
    return statuses;
  }

  @override
  Widget build(BuildContext context) {
    final payload = data;
    final statuses = monitors;
    if (payload == null || statuses == null) {
      if (response.trim().toUpperCase() != 'NO DATA') {
        return DefaultCommandResponse(response);
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(identifier == 0x41
              ? 'Current driving-cycle monitor status is unavailable.'
              : 'Emissions readiness data is unavailable.'),
          const Text('No monitor completion or failure can be inferred.'),
          const SizedBox(height: 8),
          DefaultCommandResponse(response),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(identifier == 0x41
            ? 'Monitor completion during this driving cycle'
            : 'Readiness since codes were last cleared'),
        if (identifier == 0x01) ...[
          Text('Check-engine light: ${malfunctionLightOn == true ? 'On' : 'Off'}'),
          Text('Stored emissions-related code count: $storedCodeCount'),
        ],
        Text((payload[1] & 0x08) == 0
            ? 'Engine type: spark ignition'
            : 'Engine type: compression ignition'),
        const SizedBox(height: 8),
        for (final monitor in statuses)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: Text(monitor.name)),
                const SizedBox(width: 8),
                Text(monitor.complete == null
                    ? (identifier == 0x41 ? 'Not enabled' : 'Not supported')
                    : (monitor.complete == true ? 'Complete' : 'Incomplete')),
              ],
            ),
          ),
        const SizedBox(height: 8),
        DefaultCommandResponse(response),
      ],
    );
  }
}