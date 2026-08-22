import 'package:flutter/material.dart';
import '../models/scenario_result.dart';

class SignalCard extends StatelessWidget {
  final DailySignal signal;

  const SignalCard({super.key, required this.signal});

  Color _strengthColor() {
    switch (signal.strength) {
      case SignalStrength.strong:
        return Colors.green;
      case SignalStrength.medium:
        return Colors.orange;
      case SignalStrength.weakForced:
        return Colors.red;
    }
  }

  String _strengthLabel() {
    switch (signal.strength) {
      case SignalStrength.strong:
        return 'قوية 🟢';
      case SignalStrength.medium:
        return 'متوسطة 🟡';
      case SignalStrength.weakForced:
        return 'ضعيفة (مضطرة) 🔴';
    }
  }

  String _scenarioLabel() {
    switch (signal.scenario.type) {
      case ScenarioType.breakout:
        return 'اختراق مباشر';
      case ScenarioType.retest:
        return 'اختراق + تصحيح + استكمال';
      case ScenarioType.reversal:
        return 'ارتداد من الدعم';
      case ScenarioType.continuation:
        return 'استمرار الاتجاه';
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = signal.scenario;
    return Card(
      margin: const EdgeInsets.all(12),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: _strengthColor(), width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(signal.symbol, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                Chip(
                  label: Text(_strengthLabel(), style: const TextStyle(color: Colors.white)),
                  backgroundColor: _strengthColor(),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('السيناريو: ${_scenarioLabel()}', style: const TextStyle(fontSize: 15)),
            Text('الفريم: ${signal.timeframePair == 'daily_1h' ? 'يومي → 1H' : '4H → 15m'}'),
            const Divider(),
            if (s.entry != null) Text('نقطة الدخول: ${s.entry!.toStringAsFixed(4)}'),
            if (s.stopLoss != null) Text('وقف الخسارة: ${s.stopLoss!.toStringAsFixed(4)}'),
            if (s.takeProfits != null)
              Text('الأهداف: ${s.takeProfits!.map((t) => t.toStringAsFixed(4)).join(' / ')}'),
            const SizedBox(height: 8),
            Text(signal.notes, style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}
