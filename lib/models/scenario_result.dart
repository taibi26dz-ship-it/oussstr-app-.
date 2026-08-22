enum ScenarioType { breakout, retest, reversal, continuation }
enum SignalStrength { strong, medium, weakForced }

class ScenarioResult {
  final ScenarioType type;
  final bool triggered;
  final double score;
  final double? entry;
  final double? stopLoss;
  final List<double>? takeProfits;
  final String reason;

  ScenarioResult({
    required this.type,
    required this.triggered,
    required this.score,
    this.entry,
    this.stopLoss,
    this.takeProfits,
    required this.reason,
  });

  static ScenarioResult none(ScenarioType type, String reason) => ScenarioResult(
        type: type,
        triggered: false,
        score: 0,
        reason: reason,
      );
}

class DailySignal {
  final String symbol;
  final String timeframePair;
  final ScenarioResult scenario;
  final SignalStrength strength;
  final DateTime generatedAt;
  final String notes;

  DailySignal({
    required this.symbol,
    required this.timeframePair,
    required this.scenario,
    required this.strength,
    required this.generatedAt,
    required this.notes,
  });

  Map<String, dynamic> toJson() => {
        'symbol': symbol,
        'timeframePair': timeframePair,
        'type': scenario.type.toString(),
        'score': scenario.score,
        'entry': scenario.entry,
        'stopLoss': scenario.stopLoss,
        'takeProfits': scenario.takeProfits,
        'strength': strength.toString(),
        'generatedAt': generatedAt.toIso8601String(),
        'notes': notes,
      };

  static DailySignal fromJson(Map<String, dynamic> j) => DailySignal(
        symbol: j['symbol'],
        timeframePair: j['timeframePair'],
        scenario: ScenarioResult(
          type: ScenarioType.values.firstWhere((e) => e.toString() == j['type']),
          triggered: true,
          score: (j['score'] as num).toDouble(),
          entry: j['entry'] != null ? (j['entry'] as num).toDouble() : null,
          stopLoss: j['stopLoss'] != null ? (j['stopLoss'] as num).toDouble() : null,
          takeProfits: j['takeProfits'] != null
              ? (j['takeProfits'] as List).map((e) => (e as num).toDouble()).toList()
              : null,
          reason: j['notes'] ?? '',
        ),
        strength: SignalStrength.values.firstWhere((e) => e.toString() == j['strength']),
        generatedAt: DateTime.parse(j['generatedAt']),
        notes: j['notes'] ?? '',
      );
}
