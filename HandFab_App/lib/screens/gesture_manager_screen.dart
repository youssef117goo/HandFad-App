// HandFab App — gesture_manager_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/handfab_provider.dart';
import '../core/constants.dart';
import '../models/gesture_model.dart';
import '../widgets/gesture_card.dart';

class GestureManagerScreen extends StatelessWidget {
  const GestureManagerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<HandFabProvider>();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: prov.gestures.isEmpty
          ? _EmptyState(onAdd: () => _showAddDialog(context, prov))
          : _GestureList(prov: prov),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddDialog(context, prov),
        backgroundColor: const Color(0xFF00D4FF),
        foregroundColor: Colors.black,
        icon: const Icon(Icons.add),
        label: const Text('Add Gesture', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
    );
  }

  void _showAddDialog(BuildContext context, HandFabProvider prov) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddGestureSheet(prov: prov),
    );
  }
}

class _GestureList extends StatelessWidget {
  final HandFabProvider prov;
  const _GestureList({required this.prov});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: prov.gestures.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (ctx, i) {
        final g = prov.gestures[i];
        return GestureCard(
          gesture: g,
          onDelete: () => _confirmDelete(ctx, prov, g),
          onTrain:  () => _showTrainSheet(ctx, prov, g),
        );
      },
    );
  }

  Future<void> _confirmDelete(
      BuildContext ctx, HandFabProvider prov, GestureModel g) async {
    final ok = await showDialog<bool>(
      context: ctx,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A2235),
        title: const Text('Delete Gesture'),
        content: Text('Delete "${g.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Delete',
                  style: TextStyle(color: Colors.redAccent))),
        ],
      ),
    );
    if (ok == true) prov.deleteGesture(g.slot);
  }

  void _showTrainSheet(BuildContext ctx, HandFabProvider prov, GestureModel g) {
    showModalBottomSheet(
      context: ctx,
      backgroundColor: Colors.transparent,
      builder: (_) => _TrainingSheet(prov: prov, gesture: g),
    );
  }
}

// ─── Add Gesture Sheet ───────────────────────────────────────────────────────
class _AddGestureSheet extends StatefulWidget {
  final HandFabProvider prov;
  const _AddGestureSheet({required this.prov});
  @override
  State<_AddGestureSheet> createState() => _AddGestureSheetState();
}

class _AddGestureSheetState extends State<_AddGestureSheet> {
  final _nameCtrl = TextEditingController();
  GestureAction  _action = GestureAction.mouseClick;
  bool _loading = false;

  int get _nextSlot {
    final slots = widget.prov.gestures.map((g) => g.slot).toSet();
    for (int i = 0; i < 20; i++) { if (!slots.contains(i)) return i; }
    return widget.prov.gestures.length;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF111827),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2)),
            )),
            const SizedBox(height: 20),
            const Text('New Gesture',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
            const SizedBox(height: 20),
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                hintText: 'Gesture name (e.g. Swipe Right)',
                prefixIcon: Icon(Icons.label_outline),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<GestureAction>(
              value: _action,
              decoration: const InputDecoration(
                labelText: 'Action',
                prefixIcon: Icon(Icons.bolt_outlined),
              ),
              dropdownColor: const Color(0xFF1A2235),
              items: GestureAction.values
                  .where((a) => a != GestureAction.none)
                  .map((a) => DropdownMenuItem(value: a, child: Text(a.label)))
                  .toList(),
              onChanged: (v) => setState(() => _action = v!),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _submit,
                child: _loading
                    ? const SizedBox(height: 20, width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2,
                            color: Colors.black))
                    : const Text('Start Training →'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;
    setState(() => _loading = true);
    await widget.prov.startTraining(_nextSlot, name, _action);
    if (mounted) Navigator.pop(context);
    if (mounted) {
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (_) => _TrainingSheet(
          prov: widget.prov,
          gesture: GestureModel(
              slot: _nextSlot, name: name, action: _action),
        ),
      );
    }
  }

  @override
  void dispose() { _nameCtrl.dispose(); super.dispose(); }
}

// ─── Training Progress Sheet ──────────────────────────────────────────────────
class _TrainingSheet extends StatefulWidget {
  final HandFabProvider prov;
  final GestureModel gesture;
  const _TrainingSheet({required this.prov, required this.gesture});
  @override
  State<_TrainingSheet> createState() => _TrainingSheetState();
}

class _TrainingSheetState extends State<_TrainingSheet> {
  int _step = 0; // 0 = instructions, 1 = training, 2 = done
  bool _done = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF111827),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(child: Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: Colors.white24, borderRadius: BorderRadius.circular(2)),
          )),
          const SizedBox(height: 24),
          const Icon(Icons.back_hand, color: Color(0xFF00D4FF), size: 52),
          const SizedBox(height: 16),
          Text('"${widget.gesture.name}"',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text('Perform this gesture 5 times when the glove vibrates.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white.withOpacity(0.6))),
          const SizedBox(height: 24),
          // Progress dots
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (i) => Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: 12, height: 12,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: i < widget.prov.trainingSamples
                    ? const Color(0xFF00D4FF)
                    : Colors.white12,
              ),
            )),
          ),
          const SizedBox(height: 24),
          if (!_done)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  await widget.prov.stopTraining();
                  setState(() => _done = true);
                },
                child: const Text('Finish Training'),
              ),
            )
          else ...[
            const Icon(Icons.check_circle, color: Color(0xFF00D4FF), size: 40),
            const SizedBox(height: 8),
            const Text('Training Complete!',
                style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Done'),
            ),
          ],
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.back_hand_outlined,
              size: 72, color: Colors.white.withOpacity(0.15)),
          const SizedBox(height: 16),
          Text('No gestures yet',
              style: TextStyle(fontSize: 18, color: Colors.white.withOpacity(0.4))),
          const SizedBox(height: 8),
          Text('Tap + to teach your glove a new gesture',
              style: TextStyle(color: Colors.white.withOpacity(0.25))),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: const Text('Add Gesture'),
          ),
        ],
      ),
    );
  }
}
