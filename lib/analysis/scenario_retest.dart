import '../models/candle.dart';
import '../models/scenario_result.dart';
import 'indicators.dart';
import 'ict_zones.dart';

class ScenarioRetest {
  static ScenarioResult check({
    required List<Candle> higherTfCandles,
    required List<Candle> entryTfCandles,
  }) {
    final closedHigher = higherTfCandles.where((c) => c.isClosed).toList();
    if (closedHigher.length < 2) {
      return ScenarioResult.none(ScenarioType.retest, 'Not enough higher-timeframe data');
    }
    final rangeCandle = closedHigher[closedHigher.length - 2];
    final rangeHigh = rangeCandle.high;

    final closedEntry = entryTfCandles.where((c) => c.isClosed).toList();
    if (closedEntry.length < 25) {
      return ScenarioResult.none(ScenarioType.retest, 'Not enough entry-timeframe data');
    }

    final recent = closedEntry.sublist(closedEntry.length - 15);
    final swingHigh = recent.map((c) => c.high).reduce((a, b) => a > b ? a : b);
    if (swingHigh <= rangeHigh) {
      return ScenarioResult.none(ScenarioType.retest, 'No prior breakout above range found');
    }

    final last = closedEntry.last;
    final inFibZone = IctZones.isInFibRetraceZone(swingHigh, rangeHigh, last.close);
    if (!inFibZone) {
      return ScenarioResult.none(ScenarioType.retest, 'Price not yet in 60-70% retracement zone');
    }

    final bullishCandle = last.close > last.open;
    final closedInUpperHalf = (last.close - last.low) / (last.high - last.low + 0.0000001) > 0.6;
    if (!bullishCandle || !closedInUpperHalf) {
      return ScenarioResult.none(ScenarioType.retest, 'In fib zone but no reversal candle confirmation yet');
    }

    final rsi = Indicators.rsi(entryTfCandles);
    double score = 60;
    if (rsi > 45) score += 10;
    final avgVol = Indicators.avgVolume(entryTfCandles, period: 20);
    if (avgVol > 0 && last.volume >= avgVol * 1.2) score += 15;

    final entry = last.close;
    final stopLoss = (rangeHigh * 0.997) < entry ? rangeHigh * 0.997 : entry * 0.985;
    final riskDistance = entry - stopLoss;
    final tps = [
      entry + riskDistance * 2,
      swingHigh,
      entry + riskDistance * 3.5,
    ];

    return ScenarioResult(
      type: ScenarioType.retest,
      triggered: true,
      score: score.clamp(0, 100).toDouble(),
      entry: entry,
      stopLoss: stopLoss,
      takeProfits: tps,
      reason: 'Retraced into 60-70% fib zone after breakout, reversal candle confirmed',
    );
  }
}
