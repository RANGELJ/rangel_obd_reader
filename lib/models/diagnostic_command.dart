class DiagnosticCommand {
  const DiagnosticCommand({
    required this.command,
    required this.name,
    required this.description,
  });

  final String command;
  final String name;
  final String description;

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
      command: '0100',
      name: 'Read supported data',
      description: 'Query supported live-data identifiers 01-20 (hex). '
          'A valid reply confirms the engine computer is responding.',
    ),
    DiagnosticCommand(
      command: "0101",
      name: "Emissions-monitor readiness",
      description: "Emissions-monitor readiness since codes were last cleared, plus check-engine-light status and stored-code count",
    ),
    DiagnosticCommand(
      command: "0141",
      name: "Monitor completion",
      description: "Monitor completion during the current driving cycle",
    ),
    DiagnosticCommand(
      command: "07",
      name: "Read pending trouble codes",
      description: "List pending emissions-related trouble codes.",
    ),
    DiagnosticCommand(
      command: "03",
      name: "Read stored trouble codes",
      description: "List stored emissions-related trouble codes.",
    ),
    DiagnosticCommand(
      command: "0A",
      name: "Read permanent trouble codes",
      description: "List permanent emissions-related trouble codes.",
    )
  ];
}