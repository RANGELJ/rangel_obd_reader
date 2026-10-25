List<int>? parseModeOnePayload(
  String response,
  int identifier, {
  int dataLength = 4,
}) {
  final tokens = response.trim().split(RegExp(r'\s+'));
  if (tokens.length != dataLength + 2 ||
      tokens.any((token) => !RegExp(r'^[0-9A-Fa-f]{2}$').hasMatch(token))) {
    return null;
  }
  final bytes = tokens.map((token) => int.parse(token, radix: 16)).toList();
  if (bytes[0] != 0x41 || bytes[1] != identifier) return null;
  return bytes.sublist(2);
}