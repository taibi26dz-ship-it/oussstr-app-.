hereimport '../models/candle.dart';

class MtfConfluence {
  static double check(List<Candle> higherOrderCandles) {
    final closed = higherOrderCandles.where((c) => c.isClosed).toList();
    if (closed.length < 10) return 0;
    final recent = closed.sublist(closed.length - 10);
    final firstClose = recent.first.close;
    final lastClose = recent.last.close;
    final changePct = (lastClose - firstClose) / firstClose;

    if (changePct > 0.02) return 10;
    if (changePct < -0.02) return -15;
    return 0;
  }
}
