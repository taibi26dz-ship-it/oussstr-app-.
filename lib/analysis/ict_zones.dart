enum ZoneType { premium, equilibrium, discount }

class IctZoneResult {
  final ZoneType zone;
  final double rangeHigh;
  final double rangeLow;
  final double midpoint;
  final double scoreAdjustment;

  IctZoneResult({
    required this.zone,
    required this.rangeHigh,
    required this.rangeLow,
    required this.midpoint,
    required this.scoreAdjustment,
  });
}

class IctZones {
  static IctZoneResult analyze(double rangeHigh, double rangeLow, double currentPrice) {
    final midpoint = (rangeHigh + rangeLow) / 2;
    final rangeSize = rangeHigh - rangeLow;
    if (rangeSize <= 0) {
      return IctZoneResult(
        zone: ZoneType.equilibrium,
        rangeHigh: rangeHigh,
        rangeLow: rangeLow,
        midpoint: midpoint,
        scoreAdjustment: 0,
      );
    }
    final position = (currentPrice - rangeLow) / rangeSize;
    if (position <= 0.45) {
      return IctZoneResult(
        zone: ZoneType.discount,
        rangeHigh: rangeHigh,
        rangeLow: rangeLow,
        midpoint: midpoint,
        scoreAdjustment: 8,
      );
    } else if (position >= 0.65) {
      return IctZoneResult(
        zone: ZoneType.premium,
        rangeHigh: rangeHigh,
        rangeLow: rangeLow,
        midpoint: midpoint,
        scoreAdjustment: -8,
      );
    }
    return IctZoneResult(
      zone: ZoneType.equilibrium,
      rangeHigh: rangeHigh,
      rangeLow: rangeLow,
      midpoint: midpoint,
      scoreAdjustment: 0,
    );
  }

  static bool isInFibRetraceZone(double swingHigh, double swingLow, double currentPrice) {
    final range = swingHigh - swingLow;
    if (range <= 0) return false;
    final fib60 = swingHigh - range * 0.60;
    final fib70 = swingHigh - range * 0.70;
    final lower = fib70 < fib60 ? fib70 : fib60;
    final upper = fib70 > fib60 ? fib70 : fib60;
    return currentPrice >= lower && currentPrice <= upper;
  }
}
