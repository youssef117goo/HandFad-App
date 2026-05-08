// HandFab App — gesture_card.dart
import 'package:flutter/material.dart';
import '../models/gesture_model.dart';

class GestureCard extends StatelessWidget {
  final GestureModel gesture;
  final VoidCallback onDelete;
  final VoidCallback onTrain;

  const GestureCard({
    super.key,
    required this.gesture,
    required this.onDelete,
    required this.onTrain,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key('gesture_${gesture.slot}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.2),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.redAccent),
      ),
      confirmDismiss: (_) async {
        onDelete();
        return false; // provider handles removal + notify
      },
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1A2235),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.07)),
        ),
        child: ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF00D4FF).withOpacity(0.15),
            ),
            child: Center(
              child: Text('${gesture.slot + 1}',
                  style: const TextStyle(
                      color: Color(0xFF00D4FF), fontWeight: FontWeight.w700)),
            ),
          ),
          title: Text(gesture.name,
              style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Row(
            children: [
              const Icon(Icons.bolt, size: 12, color: Color(0xFF7B61FF)),
              const SizedBox(width: 4),
              Text(gesture.action.label,
                  style: const TextStyle(
                      color: Color(0xFF7B61FF), fontSize: 12)),
            ],
          ),
          trailing: IconButton(
            icon: const Icon(Icons.fitness_center_outlined,
                color: Color(0xFF00D4FF), size: 20),
            tooltip: 'Retrain',
            onPressed: onTrain,
          ),
        ),
      ),
    );
  }
}
