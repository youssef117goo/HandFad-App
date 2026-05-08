// HandFab App — home_screen.dart
// Bottom navigation shell + connection top bar

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/handfab_provider.dart';
import '../core/ble_manager.dart';
import '../widgets/connection_badge.dart';
import 'dashboard_screen.dart';
import 'gesture_manager_screen.dart';
import 'haptic_settings_screen.dart';
import 'terminal_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tab = 0;

  final _screens = const [
    DashboardScreen(),
    GestureManagerScreen(),
    HapticSettingsScreen(),
    TerminalScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<HandFabProvider>();
    final connected = prov.bleStatus == BleStatus.connected;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/logo.png', height: 28,
                errorBuilder: (_, __, ___) => const SizedBox()),
            const SizedBox(width: 8),
            const Text('HandFab'),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: ConnectionBadge(status: prov.bleStatus),
          ),
          if (!connected)
            IconButton(
              icon: const Icon(Icons.bluetooth_searching, color: Color(0xFF00D4FF)),
              tooltip: 'Connect',
              onPressed: () => prov.connect(),
            )
          else
            IconButton(
              icon: const Icon(Icons.bluetooth_disabled, color: Colors.redAccent),
              tooltip: 'Disconnect',
              onPressed: () => prov.disconnect(),
            ),
          const SizedBox(width: 4),
        ],
      ),
      body: IndexedStack(index: _tab, children: _screens),
      bottomNavigationBar: _buildNavBar(),
    );
  }

  Widget _buildNavBar() {
    return BottomNavigationBar(
      currentIndex: _tab,
      onTap: (i) => setState(() => _tab = i),
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.dashboard_outlined),
          activeIcon: Icon(Icons.dashboard),
          label: 'Dashboard',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.back_hand_outlined),
          activeIcon: Icon(Icons.back_hand),
          label: 'Gestures',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.vibration_outlined),
          activeIcon: Icon(Icons.vibration),
          label: 'Haptic',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.terminal_outlined),
          activeIcon: Icon(Icons.terminal),
          label: 'Terminal',
        ),
      ],
    );
  }
}
