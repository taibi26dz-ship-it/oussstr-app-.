hereimport '../models/candle.dart';
import '../models/scenario_result.dart';
import 'indicators.dart';

class ScenarioContinuation {
  static ScenarioResult check({
    required List<Candle> higherTfCandles,
    required List<Candle> entryTfCandles,
  }) {
    final closedHigher = higherTfCandles.where((c) => c.isClosed).toList();
    if (closedHigher.length < 5) {
      return ScenarioResult.none(ScenarioType.continuation, 'Not enough higher-timeframe data');
    }
    final lastFive = closedHigher.sublist(closedHigher.length - 5);
    final highsRising = lastFive[4].high > lastFive[2].high && lastFive[2].high > lastFive[0].high;
    final lowsRising = lastFive[4].low > lastFive[2].low && lastFive[2].low > lastFive[0].low;
    if (!highsRising || !lowsRising) {
      return ScenarioResult.none(ScenarioType.continuation, 'Higher-timeframe trend is not a clear uptrend');
    }

    final closedEntry = entryTfCandles.where((c) => c.isClosed).toList();
    if (closedEntry.length < 21) {
      return ScenarioResult.none(ScenarioType.continuation, 'Not enough entry-timeframe data');
    }

    final recent = closedEntry.sublist(closedEntry.length - 8);
    final recentHigh = recent.map((c) => c.high).reduce((a, b) => a > b ? a : b);
    final last = closedEntry.last;
    final pullbackDepth = (recentHigh - last.low) / recentHigh;
    final shallowPullback = pullbackDepth > 0.01 && pullbackDepth < 0.06;
    final bullishResumption = last.close > last.open && last.close > closedEntry[closedEntry.length - 2].close;

    if (!shallowPullback || !bullishResumption) {
      return ScenarioResult.none(ScenarioType.continuation, 'Uptrend confirmed but no valid resumption yet');
    }

    final rsi = Indicators.rsi(entryTfCandles);
    double score = 55;
    if (rsi > 50 && rsi < 75) score += 15;
    final momentumOk = Indicators.isBullishMomentum(entryTfCandles);
    if (momentumOk) score += 15;

    final entry = last.close;
    final atr = Indicators.atr(entryTfCandles);
    final stopLoss = last.low - atr * 0.3;
    final riskDistance = entry - stopLoss;
    final tps = [
      entry + riskDistance * 2,
      entry + riskDistance * 3,
      entry + riskDistance * 4.5,
    ];

    return ScenarioResult(
      type: ScenarioType.continuation,
      triggered: true,
      score: score.clamp(0, 100).toDouble(),
      entry: entry,
      stopLoss: stopLoss,
      takeProfits: tps,
      reason: 'Higher-timeframe uptrend (HH+HL) with shallow pullback and bullish resumption',
    );
  }
}
