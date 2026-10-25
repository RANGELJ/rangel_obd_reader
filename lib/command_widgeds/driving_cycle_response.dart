import 'package:flutter/widgets.dart';
import 'package:rangel_obd_reader/command_widgeds/monitor_status_response.dart';

class DrivingCycleResponse extends StatelessWidget {
  const DrivingCycleResponse(this.response, {super.key});

  final String response;

  @override
  Widget build(BuildContext context) => MonitorStatusResponse(
        response: response,
        identifier: 0x41,
      );
}