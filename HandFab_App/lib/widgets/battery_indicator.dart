// HandFab App — battery_indicator.dart
import 'package:flutter/material.dart';

class BatteryIndicator extends StatelessWidget {
  final int pct;
  const BatteryIndicator({super.key, required this.pct});

  Color get _color {
    if (pct > 60) return const Color(0xFF00FF87);
    if (pct > 25) return const Color(0xFFFFB347);
    return Colors.redAccent;
  }

  IconData get _icon {
    if (pct > 80) return Icons.battery_full;
    if (pct > 60) return Icons.battery_5_bar;
    if (pct > 40) return Icons.battery_4_bar;
    if (pct > 20) return Icons.battery_2_bar;
    return Icons.battery_alert;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(_icon, color: _color, size: 22),
        Text('$pct%', style: TextStyle(
            fontSize: 10, color: _color, fontWeight: FontWeight.w600)),
      ],
    );
  }
}
