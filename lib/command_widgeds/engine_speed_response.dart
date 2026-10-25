import 'package:flutter/material.dart';
import 'package:rangel_obd_reader/command_widgeds/default_command_response.dart';
import 'package:rangel_obd_reader/command_widgeds/mode_one_payload.dart';

class EngineSpeedResponse extends StatelessWidget {
  const EngineSpeedResponse(this.response, {super.key});

  final String response;

  double? get revolutionsPerMinute {
    final data = parseModeOnePayload(response, 0x0C, dataLength: 2);
    if (data == null) return null;
    return ((data[0] << 8) | data[1]) / 4;
  }

  @override
  Widget build(BuildContext context) {
    final speed = revolutionsPerMinute;
    if (speed == null) return DefaultCommandResponse(response);
    final speedLabel = speed % 1 == 0 ? speed.toStringAsFixed(0) : speed.toString();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$speedLabel RPM', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        DefaultCommandResponse(response),
      ],
    );
  }
}