// HandFab App — constants.dart
// BLE UUIDs and command/packet byte constants (must match firmware exactly)

class BleUUIDs {
  static const serviceUUID  = '4fafc201-1fb5-459e-8fcc-c5c9c331914b';
  static const cmdRxUUID    = '4fafc201-1fb5-459e-8fcc-c5c9c3319101';
  static const dataTxUUID   = '4fafc201-1fb5-459e-8fcc-c5c9c3319102';
  static const logTxUUID    = '4fafc201-1fb5-459e-8fcc-c5c9c3319103';
  static const configRwUUID = '4fafc201-1fb5-459e-8fcc-c5c9c3319104';
  static const deviceName   = 'HandFab Glove';
}

class CmdID {
  static const startTraining  = 0x01;
  static const stopTraining   = 0x02;
  static const deleteGesture  = 0x03;
  static const setThreshold   = 0x04;
  static const setSensitivity = 0x05;
  static const hapticTest     = 0x06;
  static const getGestureList = 0x07;
  static const getBattery     = 0x08;
  static const factoryReset   = 0xFF;
}

class PktType {
  static const sensorData    = 0x01;
  static const gestureEvent  = 0x02;
  static const batteryLevel  = 0x03;
}

enum GestureAction {
  none(0x00,        'None'),
  mouseClick(0x01,  'Mouse Click'),
  ctrlC(0x02,       'Copy (Ctrl+C)'),
  ctrlV(0x03,       'Paste (Ctrl+V)'),
  ctrlZ(0x04,       'Undo (Ctrl+Z)'),
  scrollUp(0x05,    'Scroll Up'),
  scrollDown(0x06,  'Scroll Down'),
  customKey(0x07,   'Custom Key');

  final int id;
  final String label;
  const GestureAction(this.id, this.label);

  static GestureAction fromId(int id) =>
      GestureAction.values.firstWhere((e) => e.id == id,
          orElse: () => GestureAction.none);
}
