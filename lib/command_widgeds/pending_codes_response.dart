import 'package:flutter/widgets.dart';
import 'package:rangel_obd_reader/command_widgeds/trouble_codes_response.dart';

class PendingCodesResponse extends StatelessWidget {
  const PendingCodesResponse(this.response, {super.key});

  final String response;

  @override
  Widget build(BuildContext context) => TroubleCodesResponse(
        response: response,
        service: 0x47,
        category: 'pending',
      );
}