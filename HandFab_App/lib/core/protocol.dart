// HandFab App — protocol.dart
// Encode outgoing commands and decode incoming BLE packets from the ESP32.

import 'dart:typed_data';
import 'dart:convert';
import 'constants.dart';

// ─── Incoming Data Models ─────────────────────────────────────────────────────

class SensorData {
  final double ax, ay, az;
  final int gestureId;
  final int confidence;   // 0–100
  final int batteryPct;
  final DateTime timestamp;

  SensorData({
    required this.ax,
    required this.ay,
    required this.az,
    required this.gestureId,
    required this.confidence,
    required this.batteryPct,
  }) : timestamp = DateTime.now();
}

class GestureEvent {
  final int gestureId;
  final int confidence;
  final DateTime timestamp;
  GestureEvent(this.gestureId, this.confidence) : timestamp = DateTime.now();
}

// ─── Decoder ─────────────────────────────────────────────────────────────────

class Protocol {
  /// Decode a DATA_TX notification (20 bytes)
  static SensorData? decodeSensor(List<int> bytes) {
    if (bytes.isEmpty) return null;
    if (bytes[0] != PktType.sensorData || bytes.length < 17) return null;

    final data = ByteData.sublistView(Uint8List.fromList(bytes));
    return SensorData(
      ax: data.getFloat32(1,  Endian.little).toDouble(),
      ay: data.getFloat32(5,  Endian.little).toDouble(),
      az: data.getFloat32(9,  Endian.little).toDouble(),
      gestureId:  data.getInt16(13, Endian.little),
      confidence: bytes[15],
      batteryPct: bytes[16],
    );
  }

  static GestureEvent? decodeGestureEvent(List<int> bytes) {
    if (bytes.length < 3 || bytes[0] != PktType.gestureEvent) return null;
    return GestureEvent(bytes[1], bytes[2]);
  }

  static int? decodeBattery(List<int> bytes) {
    if (bytes.length < 2 || bytes[0] != PktType.batteryLevel) return null;
    return bytes[1];
  }

  // ─── Encoders (CMD_RX commands) ───────────────────────────────────────────

  static Uint8List cmdStartTraining(int slot, int actionId, String name) {
    final nameBytes = utf8.encode(name.substring(0, name.length.clamp(0, 23)));
    final payload   = Uint8List(3 + nameBytes.length);
    payload[0] = CmdID.startTraining;
    payload[1] = slot;
    payload[2] = actionId;
    payload.setRange(3, payload.length, nameBytes);
    return payload;
  }

  static Uint8List cmdStopTraining() =>
      Uint8List.fromList([CmdID.stopTraining]);

  static Uint8List cmdDeleteGesture(int slot) =>
      Uint8List.fromList([CmdID.deleteGesture, slot]);

  static Uint8List cmdSetThreshold(double value) {
    final buf = ByteData(5);
    buf.setUint8(0, CmdID.setThreshold);
    buf.setFloat32(1, value, Endian.little);
    return buf.buffer.asUint8List();
  }

  static Uint8List cmdSetSensitivity(double value) {
    final buf = ByteData(5);
    buf.setUint8(0, CmdID.setSensitivity);
    buf.setFloat32(1, value, Endian.little);
    return buf.buffer.asUint8List();
  }

  static Uint8List cmdHapticTest(int durationMs) {
    final buf = ByteData(3);
    buf.setUint8(0, CmdID.hapticTest);
    buf.setUint16(1, durationMs, Endian.little);
    return buf.buffer.asUint8List();
  }

  static Uint8List cmdGetGestureList() =>
      Uint8List.fromList([CmdID.getGestureList]);

  static Uint8List cmdGetBattery() =>
      Uint8List.fromList([CmdID.getBattery]);

  static Uint8List cmdFactoryReset() =>
      Uint8List.fromList([CmdID.factoryReset]);

  /// Parse a gesture list log line "G0:Wave Left|1"
  static Map<String, dynamic>? parseGestureListEntry(String line) {
    final match = RegExp(r'G(\d+):(.+)\|(\d+)').firstMatch(line);
    if (match == null) return null;
    return {
      'slot': int.parse(match.group(1)!),
      'name': match.group(2)!,
      'action': int.parse(match.group(3)!),
    };
  }
}
