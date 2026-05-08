// HandFab App — haptic_settings_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/handfab_provider.dart';

class HapticSettingsScreen extends StatelessWidget {
  const HapticSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<HandFabProvider>();
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle('Vibration'),
          const SizedBox(height: 12),
          _SettingCard(
            title: 'Haptic Intensity',
            subtitle: 'How strong the glove vibrates on gesture trigger',
            icon: Icons.vibration,
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(Icons.volume_down, color: Colors.white38, size: 18),
                    Expanded(
                      child: Slider(
                        value: prov.hapticDuty,
                        min: 0, max: 1, divisions: 20,
                        onChanged: (v) {
                          prov.hapticDuty = v;
                          prov.notifyListeners();
                        },
                        onChangeEnd: (_) => prov.applySettings(),
                      ),
                    ),
                    const Icon(Icons.volume_up, color: Colors.white38, size: 18),
                  ],
                ),
                Text('${(prov.hapticDuty * 100).round()}%',
                    style: const TextStyle(
                        color: Color(0xFF00D4FF), fontWeight: FontWeight.w700, fontSize: 18)),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => prov.testHaptic(),
                    icon: const Icon(Icons.play_circle_outline),
                    label: const Text('Test Vibration'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF00D4FF),
                      side: const BorderSide(color: Color(0xFF00D4FF)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _SectionTitle('AI Sensitivity'),
          const SizedBox(height: 12),
          _SettingCard(
            title: 'Detection Threshold',
            subtitle: 'Minimum confidence to trigger a gesture (higher = stricter)',
            icon: Icons.tune,
            child: Column(
              children: [
                Slider(
                  value: prov.threshold,
                  min: 0.5, max: 0.99, divisions: 49,
                  onChanged: (v) {
                    prov.threshold = v;
                    prov.notifyListeners();
                  },
                  onChangeEnd: (_) => prov.applySettings(),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Loose', style: TextStyle(
                        color: Colors.white.withOpacity(0.4), fontSize: 12)),
                    Text('${(prov.threshold * 100).round()}%',
                        style: const TextStyle(
                            color: Color(0xFF7B61FF),
                            fontWeight: FontWeight.w700, fontSize: 18)),
                    Text('Strict', style: TextStyle(
                        color: Colors.white.withOpacity(0.4), fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _SettingCard(
            title: 'Mouse Sensitivity',
            subtitle: 'Cursor movement speed multiplier',
            icon: Icons.mouse,
            child: Column(
              children: [
                Slider(
                  value: prov.sensitivity,
                  min: 0.2, max: 3.0, divisions: 28,
                  onChanged: (v) {
                    prov.sensitivity = v;
                    prov.notifyListeners();
                  },
                  onChangeEnd: (_) => prov.applySettings(),
                ),
                Text('${prov.sensitivity.toStringAsFixed(1)}×',
                    style: const TextStyle(
                        color: Color(0xFF00FF87),
                        fontWeight: FontWeight.w700, fontSize: 18)),
              ],
            ),
          ),
          const SizedBox(height: 32),
          _SectionTitle('Danger Zone'),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.redAccent.withOpacity(0.4)),
              borderRadius: BorderRadius.circular(16),
            ),
            child: ListTile(
              leading: const Icon(Icons.delete_forever, color: Colors.redAccent),
              title: const Text('Factory Reset', style: TextStyle(color: Colors.redAccent)),
              subtitle: const Text('Erase all gestures from the glove'),
              trailing: const Icon(Icons.chevron_right, color: Colors.redAccent),
              onTap: () => _confirmReset(context),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmReset(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A2235),
        title: const Text('Factory Reset', style: TextStyle(color: Colors.redAccent)),
        content: const Text(
            'This will erase ALL stored gestures from the glove permanently.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<HandFabProvider>().factoryReset();
            },
            child: const Text('Reset', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(left: 4),
    child: Text(text, style: TextStyle(
        color: Colors.white.withOpacity(0.5),
        fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
  );
}

class _SettingCard extends StatelessWidget {
  final String title, subtitle;
  final IconData icon;
  final Widget child;
  const _SettingCard({
    required this.title, required this.subtitle,
    required this.icon, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2235),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.07)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, color: const Color(0xFF00D4FF), size: 18),
            const SizedBox(width: 8),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
          ]),
          const SizedBox(height: 4),
          Text(subtitle, style: TextStyle(
              color: Colors.white.withOpacity(0.4), fontSize: 12)),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}
