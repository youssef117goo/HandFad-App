// HandFab App — terminal_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/handfab_provider.dart';

enum _LogFilter { all, info, warn, error }

class TerminalScreen extends StatefulWidget {
  const TerminalScreen({super.key});
  @override
  State<TerminalScreen> createState() => _TerminalScreenState();
}

class _TerminalScreenState extends State<TerminalScreen> {
  _LogFilter _filter = _LogFilter.all;
  final _scrollCtrl = ScrollController();

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<HandFabProvider>();
    final filtered = _applyFilter(prov.logs);

    // Auto-scroll to bottom
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(_scrollCtrl.position.maxScrollExtent,
            duration: const Duration(milliseconds: 150), curve: Curves.easeOut);
      }
    });

    return Column(
      children: [
        _Toolbar(
          filter: _filter,
          onFilter: (f) => setState(() => _filter = f),
          onCopy: () {
            Clipboard.setData(ClipboardData(text: prov.logs.join('\n')));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Logs copied to clipboard')));
          },
          onClear: () => setState(() => prov.logs.clear()),
        ),
        Expanded(
          child: filtered.isEmpty
              ? Center(child: Text('No logs yet',
                  style: TextStyle(color: Colors.white.withOpacity(0.3))))
              : ListView.builder(
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
                  itemCount: filtered.length,
                  itemBuilder: (_, i) => _LogLine(line: filtered[i]),
                ),
        ),
      ],
    );
  }

  List<String> _applyFilter(List<String> logs) {
    switch (_filter) {
      case _LogFilter.info:  return logs.where((l) => l.contains('[INFO]')).toList();
      case _LogFilter.warn:  return logs.where((l) => l.contains('[WARN]')).toList();
      case _LogFilter.error: return logs.where((l) => l.contains('[FATAL]') ||
                                                        l.contains('[ERR')).toList();
      default: return logs;
    }
  }
}

class _Toolbar extends StatelessWidget {
  final _LogFilter filter;
  final ValueChanged<_LogFilter> onFilter;
  final VoidCallback onCopy, onClear;
  const _Toolbar({required this.filter, required this.onFilter,
      required this.onCopy, required this.onClear});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0D1220),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          ..._LogFilter.values.map((f) => _FilterChip(
            label: f.name.toUpperCase(),
            selected: filter == f,
            onTap: () => onFilter(f),
          )),
          const Spacer(),
          IconButton(icon: const Icon(Icons.copy, size: 18),
              onPressed: onCopy, tooltip: 'Copy all'),
          IconButton(icon: const Icon(Icons.delete_outline, size: 18),
              onPressed: onClear, tooltip: 'Clear'),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _FilterChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 6),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF00D4FF).withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? const Color(0xFF00D4FF) : Colors.white24,
          ),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: selected ? const Color(0xFF00D4FF) : Colors.white38)),
      ),
    );
  }
}

class _LogLine extends StatelessWidget {
  final String line;
  const _LogLine({required this.line});

  Color _color() {
    if (line.contains('[FATAL]') || line.contains('[ERR')) return Colors.redAccent;
    if (line.contains('[WARN]')) return const Color(0xFFFFB347);
    if (line.contains('[AI]'))   return const Color(0xFF7B61FF);
    if (line.contains('[BLE]'))  return const Color(0xFF00D4FF);
    if (line.contains('[SYS]'))  return const Color(0xFF00FF87);
    return Colors.white70;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Text(line,
          style: TextStyle(
              fontSize: 11,
              fontFamily: 'monospace',
              color: _color(),
              height: 1.5)),
    );
  }
}
