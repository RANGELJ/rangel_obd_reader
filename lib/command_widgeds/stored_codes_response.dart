import 'package:flutter/widgets.dart';
import 'package:rangel_obd_reader/command_widgeds/trouble_codes_response.dart';

class StoredCodesResponse extends StatelessWidget {
  const StoredCodesResponse(this.response, {super.key});

  final String response;

  @override
  Widget build(BuildContext context) => TroubleCodesResponse(
        response: response,
        service: 0x43,
        category: 'stored',
      );
}