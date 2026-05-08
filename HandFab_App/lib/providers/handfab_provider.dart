// HandFab App — handfab_provider.dart
// Central ChangeNotifier. Owns all app state and delegates to BleManager.

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/ble_manager.dart';
import '../core/constants.dart';
import '../core/protocol.dart';
import '../models/gesture_model.dart';

class HandFabProvider extends ChangeNotifier {
  final BleManager _ble = BleManager();

  // ─── State ────────────────────────────────────────────────────────────────
  BleStatus bleStatus   = BleStatus.idle;
  int       batteryPct  = 0;
  double    threshold   = 0.78;
  double    sensitivity = 1.0;
  double    hapticDuty  = 0.7;   // 0.0–1.0

  // Sensor history (last 100 samples per axis)
  final List<double> histAx = [];
  final List<double> histAy = [];
  final List<double> histAz = [];
  static const _maxHistory = 100;

  SensorData?   lastSensor;
  GestureEvent? lastGesture;

  // Gestures
  List<GestureModel> gestures = [];

  // Training state
  bool    isTraining      = false;
  int     trainingSamples = 0;

  // Terminal log
  final List<String> logs = [];
  static const _maxLogs = 500;

  // ─── Subscriptions ───────────────────────────────────────────────────────
  late final List<StreamSubscription> _subs;

  HandFabProvider() {
    _subs = [
      _ble.statusStream.listen(_onStatus),
      _ble.sensorStream.listen(_onSensor),
      _ble.gestureStream.listen(_onGesture),
      _ble.batteryStream.listen(_onBattery),
      _ble.logStream.listen(_onLog),
    ];
    _loadLocalGestures();
  }

  // ─── BLE handlers ────────────────────────────────────────────────────────
  void _onStatus(BleStatus s) {
    bleStatus = s;
    if (s == BleStatus.connected) {
      Future.delayed(const Duration(milliseconds: 500),
          () => sendCommand(Protocol.cmdGetGestureList()));
    }
    notifyListeners();
  }

  void _onSensor(SensorData s) {
    lastSensor = s;
    batteryPct = s.batteryPct;
    _addHistory(s.ax, s.ay, s.az);
    notifyListeners();
  }

  void _onGesture(GestureEvent g) {
    lastGesture = g;
    notifyListeners();
  }

  void _onBattery(int pct) {
    batteryPct = pct;
    notifyListeners();
  }

  void _onLog(String msg) {
    // Parse gesture list entries
    final entry = Protocol.parseGestureListEntry(msg);
    if (entry != null) {
      _upsertGesture(GestureModel(
        slot:   entry['slot'] as int,
        name:   entry['name'] as String,
        action: GestureAction.fromId(entry['action'] as int),
      ));
    }

    // Add to terminal
    if (logs.length >= _maxLogs) logs.removeAt(0);
    logs.add('[${_ts()}] $msg');
    notifyListeners();
  }

  void _addHistory(double ax, double ay, double az) {
    void push(List<double> list, double val) {
      list.add(val);
      if (list.length > _maxHistory) list.removeAt(0);
    }
    push(histAx, ax);
    push(histAy, ay);
    push(histAz, az);
  }

  // ─── Gesture CRUD ────────────────────────────────────────────────────────
  void _upsertGesture(GestureModel g) {
    final idx = gestures.indexWhere((x) => x.slot == g.slot);
    if (idx >= 0) gestures[idx] = g; else gestures.add(g);
    gestures.sort((a, b) => a.slot.compareTo(b.slot));
    _saveLocalGestures();
    notifyListeners();
  }

  Future<bool> startTraining(int slot, String name, GestureAction action) async {
    isTraining      = true;
    trainingSamples = 0;
    notifyListeners();
    final ok = await sendCommand(
      Protocol.cmdStartTraining(slot, action.id, name));
    if (ok) {
      // Simulate sample counting via log messages from ESP32
    }
    return ok;
  }

  Future<bool> stopTraining() async {
    isTraining = false;
    notifyListeners();
    return sendCommand(Protocol.cmdStopTraining());
  }

  Future<bool> deleteGesture(int slot) async {
    final ok = await sendCommand(Protocol.cmdDeleteGesture(slot));
    if (ok) {
      gestures.removeWhere((g) => g.slot == slot);
      _saveLocalGestures();
      notifyListeners();
    }
    return ok;
  }

  // ─── Settings ────────────────────────────────────────────────────────────
  Future<void> applySettings() async {
    await _ble.writeConfig(threshold, sensitivity);
    _savePrefs();
  }

  Future<bool> testHaptic() async =>
      sendCommand(Protocol.cmdHapticTest((hapticDuty * 300).round()));

  Future<bool> factoryReset() async =>
      sendCommand(Protocol.cmdFactoryReset());

  // ─── BLE control ─────────────────────────────────────────────────────────
  Future<void> connect() => _ble.startScan();
  Future<void> disconnect() => _ble.disconnect();
  Future<bool> sendCommand(List<int> bytes) => _ble.sendCommand(bytes);

  // ─── Persistence ─────────────────────────────────────────────────────────
  Future<void> _loadLocalGestures() async {
    final prefs = await SharedPreferences.getInstance();
    final raw   = prefs.getString('gestures');
    if (raw != null && raw.isNotEmpty) {
      gestures = GestureModel.listFromJsonString(raw);
      notifyListeners();
    }
    threshold   = prefs.getDouble('threshold')   ?? 0.78;
    sensitivity = prefs.getDouble('sensitivity') ?? 1.0;
    hapticDuty  = prefs.getDouble('hapticDuty')  ?? 0.7;
  }

  Future<void> _saveLocalGestures() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('gestures', GestureModel.listToJsonString(gestures));
  }

  Future<void> _savePrefs() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setDouble('threshold',   threshold);
    prefs.setDouble('sensitivity', sensitivity);
    prefs.setDouble('hapticDuty',  hapticDuty);
  }

  String _ts() {
    final t = DateTime.now();
    return '${t.hour.toString().padLeft(2,'0')}:'
        '${t.minute.toString().padLeft(2,'0')}:'
        '${t.second.toString().padLeft(2,'0')}';
  }

  @override
  void dispose() {
    for (final s in _subs) s.cancel();
    _ble.dispose();
    super.dispose();
  }
}
