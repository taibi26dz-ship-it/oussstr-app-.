enum JournalResult { pending, win, loss, skipped }

class JournalEntry {
  final String symbol;
  final String dateKey;
  final String scenarioType;
  final String strength;
  final String timeframePair;
  final double score;
  JournalResult result;

  JournalEntry({
    required this.symbol,
    required this.dateKey,
    required this.scenarioType,
    required this.strength,
    required this.timeframePair,
    required this.score,
    this.result = JournalResult.pending,
  });

  Map<String, dynamic> toJson() => {
        'symbol': symbol,
        'dateKey': dateKey,
        'scenarioType': scenarioType,
        'strength': strength,
        'timeframePair': timeframePair,
        'score': score,
        'result': result.toString(),
      };

  static JournalEntry fromJson(Map<String, dynamic> j) => JournalEntry(
        symbol: j['symbol'],
        dateKey: j['dateKey'],
        scenarioType: j['scenarioType'],
        strength: j['strength'],
        timeframePair: j['timeframePair'],
        score: (j['score'] as num).toDouble(),
        result: JournalResult.values.firstWhere((e) => e.toString() == j['result']),
      );
}
