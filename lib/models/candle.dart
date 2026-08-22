class Candle {
  final DateTime openTime;
  final DateTime closeTime;
  final double open;
  final double high;
  final double low;
  final double close;
  final double volume;
  final bool isClosed;

  Candle({
    required this.openTime,
    required this.closeTime,
    required this.open,
    required this.high,
    required this.low,
    required this.close,
    required this.volume,
    required this.isClosed,
  });

  factory Candle.fromBinance(List<dynamic> k, {required bool isLast}) {
    final openTime = DateTime.fromMillisecondsSinceEpoch(k[0] as int);
    final closeTime = DateTime.fromMillisecondsSinceEpoch(k[6] as int);
    final isClosed = !isLast || DateTime.now().isAfter(closeTime);
    return Candle(
      openTime: openTime,
      closeTime: closeTime,
      open: double.parse(k[1].toString()),
      high: double.parse(k[2].toString()),
      low: double.parse(k[3].toString()),
      close: double.parse(k[4].toString()),
      volume: double.parse(k[5].toString()),
      isClosed: isClosed,
    );
  }
}
