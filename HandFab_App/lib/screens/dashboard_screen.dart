// HandFab App — dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/handfab_provider.dart';
import '../core/ble_manager.dart';
import '../widgets/sensor_chart.dart';
import '../widgets/battery_indicator.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<HandFabProvider>();
    final connected = prov.bleStatus == BleStatus.connected;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StatusCard(prov: prov, connected: connected),
          const SizedBox(height: 16),
          _SensorChartCard(prov: prov),
          const SizedBox(height: 16),
          _GestureCard(prov: prov),
          const SizedBox(height: 16),
          _StatsRow(prov: prov),
        ],
      ),
    );
  }
}

// ─── Status card ──────────────────────────────────────────────────────────────
class _StatusCard extends StatelessWidget {
  final HandFabProvider prov;
  final bool connected;
  const _StatusCard({required this.prov, required this.connected});

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      child: Row(
        children: [
          // Glove icon with pulse animation
          _PulseIcon(connected: connected),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  connected ? 'HandFab Connected' : _scanText(prov.bleStatus),
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                ),
                const SizedBox(height: 4),
                Text(
                  connected
                      ? 'Streaming at 100 Hz'
                      : 'Tap scan to connect your glove',
                  style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12),
                ),
              ],
            ),
          ),
          if (connected)
            BatteryIndicator(pct: prov.batteryPct),
        ],
      ),
    );
  }

  String _scanText(BleStatus s) {
    switch (s) {
      case BleStatus.scanning: return 'Scanning…';
      case BleStatus.connecting: return 'Connecting…';
      default: return 'Not Connected';
    }
  }
}

// ─── Sensor chart card ───────────────────────────────────────────────────────
class _SensorChartCard extends StatelessWidget {
  final HandFabProvider prov;
  const _SensorChartCard({required this.prov});

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardHeader(title: 'Accelerometer', icon: Icons.show_chart),
          const SizedBox(height: 12),
          SizedBox(
            height: 180,
            child: SensorChart(
              axHistory: prov.histAx,
              ayHistory: prov.histAy,
              azHistory: prov.histAz,
            ),
          ),
          const SizedBox(height: 12),
          // Live values
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _AxisLabel('X', prov.lastSensor?.ax ?? 0, const Color(0xFF00D4FF)),
              _AxisLabel('Y', prov.lastSensor?.ay ?? 0, const Color(0xFF7B61FF)),
              _AxisLabel('Z', prov.lastSensor?.az ?? 0, const Color(0xFF00FF87)),
            ],
          ),
        ],
      ),
    );
  }
}

class _AxisLabel extends StatelessWidget {
  final String axis;
  final double value;
  final Color color;
  const _AxisLabel(this.axis, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(axis, style: TextStyle(color: color, fontWeight: FontWeight.w700)),
        Text(value.toStringAsFixed(2),
            style: const TextStyle(fontSize: 13, fontFamily: 'monospace')),
      ],
    );
  }
}

// ─── Gesture detection card ───────────────────────────────────────────────────
class _GestureCard extends StatelessWidget {
  final HandFabProvider prov;
  const _GestureCard({required this.prov});

  @override
  Widget build(BuildContext context) {
    final g    = prov.lastGesture;
    final name = (g != null && g.gestureId >= 0 &&
                  g.gestureId < prov.gestures.length)
        ? prov.gestures[g.gestureId].name
        : '—';
    final conf = g?.confidence ?? 0;

    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardHeader(title: 'Gesture Detection', icon: Icons.back_hand),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Text(
                  name,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF00D4FF).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('$conf%',
                    style: const TextStyle(
                        color: Color(0xFF00D4FF), fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: conf / 100,
              minHeight: 6,
              backgroundColor: const Color(0xFF1A2235),
              valueColor: AlwaysStoppedAnimation<Color>(
                  conf > 70 ? const Color(0xFF00D4FF) : const Color(0xFFFFB347)),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Stats row ────────────────────────────────────────────────────────────────
class _StatsRow extends StatelessWidget {
  final HandFabProvider prov;
  const _StatsRow({required this.prov});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _StatTile('Gestures', '${prov.gestures.length}',
            Icons.gesture, const Color(0xFF7B61FF))),
        const SizedBox(width: 12),
        Expanded(child: _StatTile('Threshold',
            '${(prov.threshold * 100).round()}%',
            Icons.tune, const Color(0xFF00D4FF))),
        const SizedBox(width: 12),
        Expanded(child: _StatTile('Logs', '${prov.logs.length}',
            Icons.terminal, const Color(0xFF00FF87))),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const _StatTile(this.label, this.value, this.icon, this.color);

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          Text(value, style: TextStyle(
              color: color, fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(
              color: Colors.white.withOpacity(0.5), fontSize: 11)),
        ],
      ),
    );
  }
}

// ─── Shared widgets ───────────────────────────────────────────────────────────
class _GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  const _GlassCard({required this.child, this.padding});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2235),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.07)),
      ),
      child: child,
    );
  }
}

class _CardHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  const _CardHeader({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF00D4FF), size: 18),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(
            fontWeight: FontWeight.w600, fontSize: 14,
            color: Color(0xFF00D4FF))),
      ],
    );
  }
}

class _PulseIcon extends StatefulWidget {
  final bool connected;
  const _PulseIcon({required this.connected});
  @override
  State<_PulseIcon> createState() => _PulseIconState();
}

class _PulseIconState extends State<_PulseIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat(reverse: true);
    _anim = Tween(begin: 0.6, end: 1.0).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final color = widget.connected
        ? const Color(0xFF00D4FF)
        : Colors.grey.withOpacity(0.5);
    return FadeTransition(
      opacity: _anim,
      child: Container(
        width: 48, height: 48,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withOpacity(0.15),
        ),
        child: Icon(Icons.back_hand, color: color, size: 26),
      ),
    );
  }
}
