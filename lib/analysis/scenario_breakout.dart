import '../models/candle.dart';
import '../models/scenario_result.dart';
import 'indicators.dart';

class ScenarioBreakout {
  static ScenarioResult check({
    required List<Candle> higherTfCandles,
    required List<Candle> entryTfCandles,
  }) {
    final closedHigher = higherTfCandles.where((c) => c.isClosed).toList();
    if (closedHigher.length < 2) {
      return ScenarioResult.none(ScenarioType.breakout, 'Not enough higher-timeframe data');
    }
    final rangeCandle = closedHigher[closedHigher.length - 2];
    final rangeHigh = rangeCandle.high;

    final closedEntry = entryTfCandles.where((c) => c.isClosed).toList();
    if (closedEntry.length < 21) {
      return ScenarioResult.none(ScenarioType.breakout, 'Not enough entry-timeframe data');
    }
    final lastClosed = closedEntry.last;

    if (lastClosed.close <= rangeHigh) {
      return ScenarioResult.none(ScenarioType.breakout, 'No close above range high yet');
    }

    final avgVol = Indicators.avgVolume(entryTfCandles, period: 20);
    final volumeOk = avgVol > 0 && lastClosed.volume >= avgVol * 1.5;
    final momentumOk = Indicators.isBullishMomentum(entryTfCandles);
    final rsi = Indicators.rsi(entryTfCandles);

    if (!volumeOk) {
      return ScenarioResult.none(ScenarioType.breakout, 'Closed above range but volume too low');
    }

    double score = 55;
    if (volumeOk) score += 15;
    if (momentumOk) score += 15;
    if (rsi > 55 && rsi < 80) score += 10;
    if (rsi >= 80) score -= 10;

    final atr = Indicators.atr(entryTfCandles);
    final entry = lastClosed.close;
    final stopLoss = (rangeHigh - atr * 0.5) < entry ? rangeHigh - atr * 0.5 : entry - atr;
    final riskDistance = entry - stopLoss;
    final tps = [
      entry + riskDistance * 2,
      entry + riskDistance * 3,
      entry + riskDistance * 4,
    ];

    return ScenarioResult(
      type: ScenarioType.breakout,
      triggered: true,
      score: score.clamp(0, 100).toDouble(),
      entry: entry,
      stopLoss: stopLoss,
      takeProfits: tps,
      reason: 'Closed above range high with volume confirmed and RSI ${rsi.toStringAsFixed(1)}',
    );
  }
}
