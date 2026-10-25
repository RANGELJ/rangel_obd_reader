import 'package:flutter/material.dart';
import 'package:rangel_obd_reader/command_widgeds/default_command_response.dart';

class TroubleCodesResponse extends StatelessWidget {
  const TroubleCodesResponse({
    super.key,
    required this.response,
    required this.service,
    required this.category,
  });

  final String response;
  final int service;
  final String category;

  List<String>? get codes {
    final tokens = response.trim().split(RegExp(r'\s+'));
    if (tokens.any((token) => !RegExp(r'^[0-9A-Fa-f]{2}$').hasMatch(token))) {
      return null;
    }
    final bytes = tokens.map((token) => int.parse(token, radix: 16)).toList();
    if (bytes.length < 2 || bytes.first != service) return null;

    final codeCount = bytes[1];
    final payloadLength = 2 + codeCount * 2;
    if (bytes.length < payloadLength ||
        bytes.skip(payloadLength).any((byte) => byte != 0)) {
      return null;
    }

    final decodedCodes = <String>[];
    for (var codeIndex = 0; codeIndex < codeCount; codeIndex++) {
      final firstByte = bytes[2 + codeIndex * 2];
      final secondByte = bytes[3 + codeIndex * 2];
      if (firstByte == 0 && secondByte == 0) return null;
      final family = 'PCBU'[firstByte >> 6];
      final firstDigit = (firstByte >> 4) & 3;
      final remainingDigits = (firstByte & 15).toRadixString(16) +
          secondByte.toRadixString(16).padLeft(2, '0');
      decodedCodes.add('$family$firstDigit${remainingDigits.toUpperCase()}');
    }
    return decodedCodes;
  }

  @override
  Widget build(BuildContext context) {
    final decodedCodes = codes;
    if (decodedCodes == null) return DefaultCommandResponse(response);

    final codeLabel = decodedCodes.length == 1 ? 'code' : 'codes';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          decodedCodes.isEmpty
              ? 'No $category emissions-related trouble codes reported.'
              : '${decodedCodes.length} $category emissions-related trouble $codeLabel:',
        ),
        for (final code in decodedCodes)
          SelectableText(code, style: const TextStyle(fontFamily: 'monospace')),
        const SizedBox(height: 8),
        DefaultCommandResponse(response),
      ],
    );
  }
}