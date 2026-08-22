hereimport '../models/candle.dart';

class Indicators {
  static double rsi(List<Candle> candles, {int period = 14}) {
    if (candles.length < period + 1) return 50.0;
    double gains = 0;
    double losses = 0;
    final start = candles.length - period - 1;
    for (int i = start + 1; i < candles.length; i++) {
      final diff = candles[i].close - candles[i - 1].close;
      if (diff >= 0) {
        gains += diff;
      } else {
        losses += -diff;
      }
    }
    final avgGain = gains / period;
    final avgLoss = losses / period;
    if (avgLoss == 0) return 100.0;
    final rs = avgGain / avgLoss;
    return 100 - (100 / (1 + rs));
  }

  static double atr(List<Candle> candles, {int period = 14}) {
    if (candles.length < period + 1) return 0.0;
    final trs = <double>[];
    for (int i = candles.length - period; i < candles.length; i++) {
      final c = candles[i];
      final prevClose = candles[i - 1].close;
      final tr = [
        c.high - c.low,
        (c.high - prevClose).abs(),
        (c.low - prevClose).abs(),
      ].reduce((a, b) => a > b ? a : b);
      trs.add(tr);
    }
    return trs.reduce((a, b) => a + b) / trs.length;
  }

  static double avgVolume(List<Candle> candles, {int period = 20}) {
    final closed = candles.where((c) => c.isClosed).toList();
    if (closed.length < 2) return 0.0;
    final usable = closed.length > period
        ? closed.sublist(closed.length - period - 1, closed.length - 1)
        : closed.sublist(0, closed.length - 1);
    if (usable.isEmpty) return 0.0;
    return usable.map((c) => c.volume).reduce((a, b) => a + b) / usable.length;
  }

  static bool isBullishMomentum(List<Candle> candles, {int shortPeriod = 5, int longPeriod = 20}) {
    final closed = candles.where((c) => c.isClosed).toList();
    if (closed.length < longPeriod) return false;
    double shortMA(List<Candle> list, int p) =>
        list.sublist(list.length - p).map((c) => c.close).reduce((a, b) => a + b) / p;
    final shortNow = shortMA(closed, shortPeriod);
    final longNow = shortMA(closed, longPeriod);
    return shortNow > longNow;
  }
}
