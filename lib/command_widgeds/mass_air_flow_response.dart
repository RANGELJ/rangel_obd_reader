import 'package:flutter/material.dart';
import 'package:rangel_obd_reader/command_widgeds/default_command_response.dart';
import 'package:rangel_obd_reader/command_widgeds/mode_one_payload.dart';

class MassAirFlowResponse extends StatelessWidget {
  const MassAirFlowResponse(this.response, {super.key});

  final String response;

  double? get gramsPerSecond {
    final data = parseModeOnePayload(response, 0x10, dataLength: 2);
    if (data == null) return null;
    return ((data[0] << 8) | data[1]) / 100;
  }

  @override
  Widget build(BuildContext context) {
    final flow = gramsPerSecond;
    if (flow == null) return DefaultCommandResponse(response);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${flow.toStringAsFixed(2)} g/s',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        DefaultCommandResponse(response),
      ],
    );
  }
}