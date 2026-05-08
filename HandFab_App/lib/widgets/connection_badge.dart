// HandFab App — connection_badge.dart
import 'package:flutter/material.dart';
import '../core/ble_manager.dart';

class ConnectionBadge extends StatelessWidget {
  final BleStatus status;
  const ConnectionBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final (color, label) = switch (status) {
      BleStatus.connected    => (const Color(0xFF00FF87), 'Connected'),
      BleStatus.scanning     => (const Color(0xFFFFB347), 'Scanning…'),
      BleStatus.connecting   => (const Color(0xFFFFB347), 'Connecting…'),
      _                      => (Colors.grey, 'Offline'),
    };

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8, height: 8,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color,
              boxShadow: [BoxShadow(color: color.withOpacity(0.6), blurRadius: 6)]),
        ),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(fontSize: 12, color: color,
            fontWeight: FontWeight.w600)),
      ],
    );
  }
}
