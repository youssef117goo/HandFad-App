// HandFab App — gesture_model.dart

import 'dart:convert';
import 'constants.dart';

class GestureModel {
  final int slot;
  String name;
  GestureAction action;
  int sampleCount;

  GestureModel({
    required this.slot,
    required this.name,
    required this.action,
    this.sampleCount = 0,
  });

  Map<String, dynamic> toJson() => {
    'slot': slot,
    'name': name,
    'action': action.id,
    'sampleCount': sampleCount,
  };

  factory GestureModel.fromJson(Map<String, dynamic> j) => GestureModel(
    slot: j['slot'] as int,
    name: j['name'] as String,
    action: GestureAction.fromId(j['action'] as int),
    sampleCount: j['sampleCount'] as int? ?? 0,
  );

  static List<GestureModel> listFromJsonString(String s) {
    final list = jsonDecode(s) as List;
    return list.map((e) => GestureModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  static String listToJsonString(List<GestureModel> gestures) =>
      jsonEncode(gestures.map((g) => g.toJson()).toList());
}
