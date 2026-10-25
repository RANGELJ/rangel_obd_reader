import 'package:flutter/material.dart';
import 'package:rangel_obd_reader/command_widgeds/default_command_response.dart';

class MisfireTestsResponse extends StatelessWidget {
  const MisfireTestsResponse(this.response, {super.key});

  final String response;

  static const _testNames = {
    'P0300': 'Random / multiple-cylinder misfire',
    'P0301': 'Cylinder 1 misfire',
    'P0302': 'Cylinder 2 misfire',
    'P0303': 'Cylinder 3 misfire',
    'P0304': 'Cylinder 4 misfire',
    'P0313': 'Misfire detected with low fuel',
    'P0351': 'Ignition coil A primary circuit',
    'P0352': 'Ignition coil B primary circuit',
    'P2300': 'Ignition coil A primary circuit low',
    'P2301': 'Ignition coil A primary circuit high',
    'P2303': 'Ignition coil B primary circuit low',
    'P2304': 'Ignition coil B primary circuit high',
  };

  List<int>? get payload {
    final lines = response
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n')
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();
    if (lines.isEmpty) return null;

    final tokens = <String>[];
    int? expectedLength;
    if (RegExp(r'^[0-9A-Fa-f]{3}$').hasMatch(lines.first)) {
      expectedLength = int.parse(lines.removeAt(0), radix: 16);
      var expectedLine = 0;
      for (final line in lines) {
        final match = RegExp(r'^([0-9A-Fa-f]+):\s*(.*)$').firstMatch(line);
        if (match == null || int.parse(match[1]!, radix: 16) != expectedLine) {
          return null;
        }
        tokens.addAll(match[2]!.split(RegExp(r'\s+')));
        expectedLine++;
      }
    } else {
      for (final line in lines) {
        final lineTokens = line.split(RegExp(r'\s+'));
        if (lineTokens.join().toUpperCase() == '7F1978') continue;
        tokens.addAll(lineTokens);
      }
    }
    if (tokens.any((token) => !RegExp(r'^[0-9A-Fa-f]{2}$').hasMatch(token))) {
      return null;
    }
    final bytes = tokens.map((token) => int.parse(token, radix: 16)).toList();
    if (expectedLength != null && bytes.length != expectedLength) return null;
    if (bytes.length < 3 || bytes[0] != 0x59 || bytes[1] != 0x02 ||
        (bytes[2] & 0x03) == 0 || (bytes.length - 3) % 4 != 0) {
      return null;
    }
    return bytes;
  }

  List<({String code, String name, int failureType, int status})>? get tests {
    final bytes = payload;
    if (bytes == null) return null;
    final results = <({String code, String name, int failureType, int status})>[];
    for (var recordIndex = 3; recordIndex < bytes.length; recordIndex += 4) {
      final firstByte = bytes[recordIndex];
      final secondByte = bytes[recordIndex + 1];
      final status = bytes[recordIndex + 3] & bytes[2];
      if ((status & 0x03) == 0) return null;
      final family = 'PCBU'[firstByte >> 6];
      final firstDigit = (firstByte >> 4) & 3;
      final remainingDigits = (firstByte & 15).toRadixString(16) +
          secondByte.toRadixString(16).padLeft(2, '0');
      final code = '$family$firstDigit${remainingDigits.toUpperCase()}';
      results.add((
        code: code,
        name: _testNames[code] ?? 'Other engine-computer fault test',
        failureType: bytes[recordIndex + 2],
        status: status,
      ));
    }
    return results;
  }

  @override
  Widget build(BuildContext context) {
    final results = tests;
    if (results == null) return DefaultCommandResponse(response);
    final cylinderTests = results.where((test) => _testNames.containsKey(test.code));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(cylinderTests.isEmpty
            ? 'No misfire or coil test failures reported for this drive.'
            : '${cylinderTests.length} misfire / coil test failure records reported.'),
        for (final test in results)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${test.code} - ${test.name}'),
                Text((test.status & 0x01) != 0
                    ? 'Failing now'
                    : 'Failed earlier this driving cycle'),
                if ((test.status & 0x04) != 0) const Text('Pending code'),
                if ((test.status & 0x08) != 0) const Text('Confirmed code'),
                Text('Failure type: ${test.failureType.toRadixString(16).padLeft(2, '0').toUpperCase()}'),
              ],
            ),
          ),
        const Text('These are ECU test results, not individual misfire counts. '
            'No reported failure does not prove every test ran or every cylinder is healthy.'),
        const SizedBox(height: 8),
        DefaultCommandResponse(response),
      ],
    );
  }
}