hereimport 'package:flutter/material.dart';
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
      case ScenarioType.none:
        return 'لا يوجد سيناريو محدد اليوم';
    }
  }

  Widget _tradeStatusBanner() {
    String label;
    Color color;
    switch (signal.tradeStatus) {
      case TradeStatus.noTrade:
        return const SizedBox.shrink();
      case TradeStatus.active:
        label = '⏳ الصفقة نشطة حالياً';
        color = Colors.blue;
        break;
      case TradeStatus.hitStopLoss:
        label = '❌ تم ضرب وقف الخسارة';
        color = Colors.red;
        break;
      case TradeStatus.hitTp1:
        label = '✅ تم تحقيق الهدف الأول (TP1)';
        color = Colors.green;
        break;
      case TradeStatus.hitTp2:
        label = '✅ تم تحقيق الهدف الثاني (TP2)';
        color = Colors.green;
        break;
      case TradeStatus.hitTp3:
        label = '✅ تم تحقيق الهدف الثالث (TP3)';
        color = Colors.green;
        break;
    }
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color),
      ),
      child: Row(
        children: [
          Expanded(child: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold))),
          if (signal.currentPrice != null)
            Text('السعر: ${signal.currentPrice!.toStringAsFixed(4)}', style: TextStyle(color: color, fontSize: 12)),
        ],
      ),
    );
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
            const SizedBox(height: 10),
            _tradeStatusBanner(),
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
