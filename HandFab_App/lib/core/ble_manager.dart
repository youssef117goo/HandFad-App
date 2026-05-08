// HandFab App — ble_manager.dart
// Handles BLE scan, connect, auto-reconnect, and characteristic subscriptions.

import 'dart:async';
import 'dart:convert';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'constants.dart';
import 'protocol.dart';

enum BleStatus { idle, scanning, connecting, connected, disconnected }

class BleManager {
  // ─── Streams ────────────────────────────────────────────────────────────────
  final _sensorController  = StreamController<SensorData>.broadcast();
  final _gestureController = StreamController<GestureEvent>.broadcast();
  final _logController     = StreamController<String>.broadcast();
  final _batteryController = StreamController<int>.broadcast();
  final _statusController  = StreamController<BleStatus>.broadcast();

  Stream<SensorData>   get sensorStream  => _sensorController.stream;
  Stream<GestureEvent> get gestureStream => _gestureController.stream;
  Stream<String>       get logStream     => _logController.stream;
  Stream<int>          get batteryStream => _batteryController.stream;
  Stream<BleStatus>    get statusStream  => _statusController.stream;

  // ─── State ──────────────────────────────────────────────────────────────────
  BluetoothDevice?        _device;
  BluetoothCharacteristic? _cmdChar;
  BluetoothCharacteristic? _configChar;
  BleStatus _status = BleStatus.idle;

  BleStatus get status => _status;

  void _setStatus(BleStatus s) {
    _status = s;
    _statusController.add(s);
  }

  // ─── Scan & Connect ─────────────────────────────────────────────────────────
  Future<void> startScan() async {
    _setStatus(BleStatus.scanning);
    await FlutterBluePlus.startScan(
      timeout: const Duration(seconds: 10),
      withNames: [BleUUIDs.deviceName],
    );

    FlutterBluePlus.scanResults.listen((results) async {
      for (final r in results) {
        if (r.device.platformName == BleUUIDs.deviceName) {
          await FlutterBluePlus.stopScan();
          await _connect(r.device);
          break;
        }
      }
    });

    // Timeout fallback
    FlutterBluePlus.isScanning.where((s) => !s).first.then((_) {
      if (_status == BleStatus.scanning) _setStatus(BleStatus.disconnected);
    });
  }

  Future<void> stopScan() async {
    await FlutterBluePlus.stopScan();
    _setStatus(BleStatus.idle);
  }

  Future<void> _connect(BluetoothDevice device) async {
    _setStatus(BleStatus.connecting);
    _device = device;

    try {
      await device.connect(autoConnect: false);
    } catch (e) {
      _setStatus(BleStatus.disconnected);
      return;
    }

    device.connectionState.listen((state) {
      if (state == BluetoothConnectionState.disconnected) {
        _setStatus(BleStatus.disconnected);
        _cmdChar    = null;
        _configChar = null;
        // Auto-reconnect after 3s
        Future.delayed(const Duration(seconds: 3), startScan);
      }
    });

    await _discoverServices(device);
    _setStatus(BleStatus.connected);
  }

  Future<void> disconnect() async {
    await _device?.disconnect();
    _setStatus(BleStatus.idle);
  }

  // ─── Service Discovery ──────────────────────────────────────────────────────
  Future<void> _discoverServices(BluetoothDevice device) async {
    final services = await device.discoverServices();

    for (final svc in services) {
      if (svc.uuid.toString().toLowerCase() != BleUUIDs.serviceUUID) continue;

      for (final char in svc.characteristics) {
        final uuid = char.uuid.toString().toLowerCase();

        if (uuid == BleUUIDs.cmdRxUUID) {
          _cmdChar = char;
        }

        if (uuid == BleUUIDs.configRwUUID) {
          _configChar = char;
        }

        if (uuid == BleUUIDs.dataTxUUID) {
          await char.setNotifyValue(true);
          char.onValueReceived.listen(_onDataReceived);
        }

        if (uuid == BleUUIDs.logTxUUID) {
          await char.setNotifyValue(true);
          char.onValueReceived.listen(_onLogReceived);
        }
      }
    }
  }

  // ─── Notification Handlers ──────────────────────────────────────────────────
  void _onDataReceived(List<int> bytes) {
    if (bytes.isEmpty) return;
    switch (bytes[0]) {
      case PktType.sensorData:
        final s = Protocol.decodeSensor(bytes);
        if (s != null) {
          _sensorController.add(s);
          _batteryController.add(s.batteryPct);
        }
        break;
      case PktType.gestureEvent:
        final g = Protocol.decodeGestureEvent(bytes);
        if (g != null) _gestureController.add(g);
        break;
      case PktType.batteryLevel:
        final b = Protocol.decodeBattery(bytes);
        if (b != null) _batteryController.add(b);
        break;
    }
  }

  void _onLogReceived(List<int> bytes) {
    final msg = utf8.decode(bytes, allowMalformed: true);
    _logController.add(msg);
  }

  // ─── Send Commands ──────────────────────────────────────────────────────────
  Future<bool> sendCommand(List<int> bytes) async {
    if (_cmdChar == null) return false;
    try {
      await _cmdChar!.write(bytes, withoutResponse: false);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> writeConfig(double threshold, double sensitivity) async {
    if (_configChar == null) return false;
    try {
      final buf = List<int>.filled(8, 0);
      final bd  = ByteData(8);
      bd.setFloat32(0, threshold,   Endian.little);
      bd.setFloat32(4, sensitivity, Endian.little);
      await _configChar!.write(bd.buffer.asUint8List(), withoutResponse: false);
      return true;
    } catch (_) {
      return false;
    }
  }

  void dispose() {
    _sensorController.close();
    _gestureController.close();
    _logController.close();
    _batteryController.close();
    _statusController.close();
  }
}
