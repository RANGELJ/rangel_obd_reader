import 'package:flutter/widgets.dart';
import 'package:rangel_obd_reader/command_widgeds/monitor_status_response.dart';

class EmissionsReadinessResponse extends StatelessWidget {
  const EmissionsReadinessResponse(this.response, {super.key});

  final String response;

  @override
  Widget build(BuildContext context) => MonitorStatusResponse(
        response: response,
        identifier: 0x01,
      );
}