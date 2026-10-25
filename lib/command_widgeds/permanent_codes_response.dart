import 'package:flutter/widgets.dart';
import 'package:rangel_obd_reader/command_widgeds/trouble_codes_response.dart';

class PermanentCodesResponse extends StatelessWidget {
  const PermanentCodesResponse(this.response, {super.key});

  final String response;

  @override
  Widget build(BuildContext context) => TroubleCodesResponse(
        response: response,
        service: 0x4A,
        category: 'permanent',
      );
}