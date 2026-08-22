import '../models/candle.dart';

enum WyckoffPhase { accumulation, markup, distribution, markdown, unclear }

class WyckoffResult {
  final WyckoffPhase phase;
  final String label;
  final double scoreAdjustment;

  WyckoffResult(this.phase, this.label, this.scoreAdjustment);
}

class WyckoffFilter {
  static WyckoffResult analyze(List<Candle> higherTimeframeCandles) {
    final closed = higherTimeframeCandles.where((c) => c.isClosed).toList();
    if (closed.length < 20) {
      return WyckoffResult(WyckoffPhase.unclear, 'Not enough data', 0);
    }

    final recent = closed.sublist(closed.length - 20);
    final highs = recent.map((c) => c.high).toList();
    final lows = recent.map((c) => c.low).toList();
    final rangeHigh = highs.reduce((a, b) => a > b ? a : b);
    final rangeLow = lows.reduce((a, b) => a < b ? a : b);
    final rangeSize = rangeHigh - rangeLow;

    final firstHalf = recent.sublist(0, 10);
    final secondHalf = recent.sublist(10);
    final avgVolFirst = firstHalf.map((c) => c.volume).reduce((a, b) => a + b) / 10;
    final avgVolSecond = secondHalf.map((c) => c.volume).reduce((a, b) => a + b) / 10;

    final closeNow = recent.last.close;
    final positionInRange = rangeSize == 0 ? 0.5 : (closeNow - rangeLow) / rangeSize;

    final priceRisingOverall = recent.last.close > recent.first.close;
    final volumeRising = avgVolSecond > avgVolFirst * 1.1;

    if (positionInRange < 0.4 && volumeRising && !priceRisingOverall) {
      return WyckoffResult(WyckoffPhase.accumulation, 'Accumulation (range low, volume building)', 8);
    }
    if (priceRisingOverall && positionInRange > 0.5) {
      return WyckoffResult(WyckoffPhase.markup, 'Markup (uptrend, favorable)', 10);
    }
    if (positionInRange > 0.6 && volumeRising && !priceRisingOverall) {
      return WyckoffResult(WyckoffPhase.distribution, 'Distribution (range high, caution)', -12);
    }
    if (!priceRisingOverall && positionInRange < 0.4) {
      return WyckoffResult(WyckoffPhase.markdown, 'Markdown (downtrend, unfavorable)', -15);
    }
    return WyckoffResult(WyckoffPhase.unclear, 'Unclear phase', 0);
  }
}
