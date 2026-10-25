import 'package:flutter/material.dart';
import 'package:rangel_obd_reader/command_widgeds/default_command_response.dart';
import 'package:rangel_obd_reader/command_widgeds/mode_one_payload.dart';

class SupportedDataResponse extends StatelessWidget {
  const SupportedDataResponse(this.response, {super.key});

  final String response;

  static const _readingNames = [
    'Monitor status since codes were cleared',
    'Freeze-frame trouble code',
    'Fuel-system status',
    'Calculated engine load',
    'Engine coolant temperature',
    'Short-term fuel trim, bank 1',
    'Long-term fuel trim, bank 1',
    'Short-term fuel trim, bank 2',
    'Long-term fuel trim, bank 2',
    'Fuel pressure',
    'Intake manifold pressure',
    'Engine speed (RPM)',
    'Vehicle speed',
    'Ignition timing advance',
    'Intake air temperature',
    'Mass air flow',
    'Throttle position',
    'Secondary air status',
    'Oxygen sensors present (two-bank layout)',
    'Oxygen sensor, bank 1 sensor 1',
    'Oxygen sensor, bank 1 sensor 2',
    'Oxygen sensor, bank 1 sensor 3',
    'Oxygen sensor, bank 1 sensor 4',
    'Oxygen sensor, bank 2 sensor 1',
    'Oxygen sensor, bank 2 sensor 2',
    'Oxygen sensor, bank 2 sensor 3',
    'Oxygen sensor, bank 2 sensor 4',
    'Supported OBD standard',
    'Oxygen sensors present (four-bank layout)',
    'Auxiliary input status',
    'Engine run time since start',
    'Supported data identifiers 21-40 (hex)',
  ];

  List<({String identifier, String name})>? get supportedReadings {
    final data = parseModeOnePayload(response, 0x00);
    if (data == null) return null;
    final bitmap = (data[0] << 24) | (data[1] << 16) | (data[2] << 8) | data[3];
    return [
      for (var identifier = 1; identifier <= 32; identifier++)
        if ((bitmap & (1 << (32 - identifier))) != 0)
          (
            identifier: identifier.toRadixString(16).padLeft(2, '0').toUpperCase(),
            name: _readingNames[identifier - 1],
          ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final readings = supportedReadings;
    if (readings == null) return DefaultCommandResponse(response);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Engine computer responded.'),
        Text('Supported requests: ${readings.length}'),
        for (final reading in readings)
          Text('01${reading.identifier} - ${reading.name}'),
        const SizedBox(height: 8),
        DefaultCommandResponse(response),
      ],
    );
  }
}