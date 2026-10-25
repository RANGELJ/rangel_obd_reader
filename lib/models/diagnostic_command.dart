import 'package:flutter/widgets.dart';
import 'package:rangel_obd_reader/command_widgeds/default_command_response.dart';
import 'package:rangel_obd_reader/command_widgeds/driving_cycle_response.dart';
import 'package:rangel_obd_reader/command_widgeds/emissions_readiness_response.dart';
import 'package:rangel_obd_reader/command_widgeds/engine_speed_response.dart';
import 'package:rangel_obd_reader/command_widgeds/pending_codes_response.dart';
import 'package:rangel_obd_reader/command_widgeds/permanent_codes_response.dart';
import 'package:rangel_obd_reader/command_widgeds/stored_codes_response.dart';
import 'package:rangel_obd_reader/command_widgeds/supported_data_response.dart';

// Documented codes
// https://en.wikipedia.org/wiki/OBD-II_PIDs

class DiagnosticCommand {
  const DiagnosticCommand({
    required this.command,
    required this.name,
    required this.description,
    this.responseBuilder,
  });

  final String command;
  final String name;
  final String description;
  final Widget Function(String response)? responseBuilder;

  Widget renderResponse(String response, {bool isComplete = true}) {
    final lines = response
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n')
        .trim()
        .split('\n');
    if (lines.first.trim() == command) {
      lines.removeAt(0);
    }
    final responseWithoutEcho = lines.join('\n').trim();
    return isComplete
      ? (responseBuilder ?? DefaultCommandResponse.new)(responseWithoutEcho)
        : DefaultCommandResponse(responseWithoutEcho);
  }

  static const scannerCommands = [
    DiagnosticCommand(
      command: 'ATI',
      name: 'Identify scanner',
      description: 'Read adapter identification',
    ),
    DiagnosticCommand(
      command: 'ATE0',
      name: 'Disable echo',
      description: 'Stop repeating sent commands',
    ),
    DiagnosticCommand(
      command: 'ATDP',
      name: 'Read current protocol',
      description: 'Show the configured vehicle protocol',
    ),
    DiagnosticCommand(
      command: 'ATSP6',
      name: 'Set CAN 11/500',
      description: '11-bit CAN at 500 kbit/s. Compatible with 2012 Fiesta.',
    ),
  ];

  static const carCommands = [
    DiagnosticCommand(
      command: '010C',
      name: 'Read engine RPM',
      description: 'Read current engine speed in revolutions per minute.',
      responseBuilder: EngineSpeedResponse.new,
    ),
    DiagnosticCommand(
      command: '0100',
      name: 'Read supported data',
      description: 'Query supported live-data identifiers 01-20 (hex). '
          'A valid reply confirms the engine computer is responding.',
        responseBuilder: SupportedDataResponse.new,
    ),
    DiagnosticCommand(
      command: "0101",
      name: "Emissions-monitor readiness",
      description: "Emissions-monitor readiness since codes were last cleared, plus check-engine-light status and stored-code count",
      responseBuilder: EmissionsReadinessResponse.new,
    ),
    DiagnosticCommand(
      command: "0141",
      name: "Monitor completion",
      description: "Monitor completion during the current driving cycle",
      responseBuilder: DrivingCycleResponse.new,
    ),
    DiagnosticCommand(
      command: "07",
      name: "Read pending trouble codes",
      description: "List pending emissions-related trouble codes.",
      responseBuilder: PendingCodesResponse.new,
    ),
    DiagnosticCommand(
      command: "03",
      name: "Read stored trouble codes",
      description: "List stored emissions-related trouble codes.",
      responseBuilder: StoredCodesResponse.new,
    ),
    DiagnosticCommand(
      command: "0A",
      name: "Read permanent trouble codes",
      description: "List permanent emissions-related trouble codes.",
      responseBuilder: PermanentCodesResponse.new,
    )
  ];
}