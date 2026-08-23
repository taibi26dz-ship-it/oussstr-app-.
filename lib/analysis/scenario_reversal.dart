import '../models/candle.dart';
import '../models/scenario_result.dart';
import 'indicators.dart';

class ScenarioReversal {
  static ScenarioResult check({
    required List<Candle> higherTfCandles,
    required List<Candle> entryTfCandles,
  }) {
    final closedHigher = higherTfCandles.where((c) => c.isClosed).toList();
    if (closedHigher.length < 2) {
      return ScenarioResult.none(ScenarioType.reversal, 'Not enough higher-timeframe data');
    }
    final rangeCandle = closedHigher[closedHigher.length - 2];
    final rangeHigh = rangeCandle.high;
    final rangeLow = rangeCandle.low;

    final closedEntry = entryTfCandles.where((c) => c.isClosed).toList();
    if (closedEntry.length < 21) {
      return ScenarioResult.none(ScenarioType.reversal, 'Not enough entry-timeframe data');
    }

    final recent = closedEntry.sublist(closedEntry.length - 10);
    Candle? sweepCandle;
    for (final c in recent) {
      if (c.low <= rangeLow && c.close > rangeLow) {
        sweepCandle = c;
      }
    }
    if (sweepCandle == null) {
      return ScenarioResult.none(ScenarioType.reversal, 'No liquidity sweep of range low found');
    }

    final last = closedEntry.last;
    final bullishCandle = last.close > last.open;
    final aboveSweepLow = last.close > sweepCandle.low;
    if (!bullishCandle || !aboveSweepLow) {
      return ScenarioResult.none(ScenarioType.reversal, 'Sweep found but no reversal confirmation yet');
    }

    final rsi = Indicators.rsi(entryTfCandles);
    double score = 55;
    if (rsi > 35 && rsi < 65) score += 10;
    final avgVol = Indicators.avgVolume(entryTfCandles, period: 20);
    if (avgVol > 0 && last.volume >= avgVol * 1.2) score += 15;
    if (last.close > (rangeHigh + rangeLow) / 2) score += 5;

    final entry = last.close;
    final stopLoss = sweepCandle.low * 0.998;
    final riskDistance = entry - stopLoss;
    final tps = [
      entry + riskDistance * 2,
      rangeHigh,
      entry + riskDistance * 3.5,
    ];

    return ScenarioResult(
      type: ScenarioType.reversal,
      triggered: true,
      score: score.clamp(0, 100).toDouble(),
      entry: entry,
      stopLoss: stopLoss,
      takeProfits: tps,
      reason: 'Liquidity sweep below range low, reversal candle confirmed back toward range high',
      triggerTime: last.closeTime,
    );
  }
}
