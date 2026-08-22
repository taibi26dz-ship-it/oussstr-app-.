import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/journal_entry.dart';

class JournalService {
  static const String _key = 'journal_entries';

  Future<List<JournalEntry>> getAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? [];
    return raw.map((e) => JournalEntry.fromJson(jsonDecode(e))).toList();
  }

  Future<void> _saveAll(List<JournalEntry> entries) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = entries.map((e) => jsonEncode(e.toJson())).toList();
    await prefs.setStringList(_key, raw);
  }

  Future<void> upsertPending(JournalEntry entry) async {
    final all = await getAll();
    final exists = all.any((e) => e.symbol == entry.symbol && e.dateKey == entry.dateKey);
    if (!exists) {
      all.add(entry);
      await _saveAll(all);
    }
  }

  Future<void> updateResult(String symbol, String dateKey, JournalResult result) async {
    final all = await getAll();
    final idx = all.indexWhere((e) => e.symbol == symbol && e.dateKey == dateKey);
    if (idx != -1 && all[idx].result == JournalResult.pending) {
      all[idx].result = result;
      await _saveAll(all);
    }
  }

  Future<Map<String, dynamic>> getStats({String? symbol}) async {
    final all = await getAll();
    final filtered = symbol == null ? all : all.where((e) => e.symbol == symbol).toList();
    final resolved = filtered.where((e) => e.result != JournalResult.pending && e.result != JournalResult.skipped).toList();
    final wins = resolved.where((e) => e.result == JournalResult.win).length;
    final total = resolved.length;
    final winRate = total == 0 ? 0.0 : (wins / total) * 100;

    final byScenario = <String, Map<String, int>>{};
    for (final e in resolved) {
      byScenario.putIfAbsent(e.scenarioType, () => {'win': 0, 'total': 0});
      byScenario[e.scenarioType]!['total'] = byScenario[e.scenarioType]!['total']! + 1;
      if (e.result == JournalResult.win) {
        byScenario[e.scenarioType]!['win'] = byScenario[e.scenarioType]!['win']! + 1;
      }
    }

    return {
      'totalResolved': total,
      'wins': wins,
      'winRate': winRate,
      'byScenario': byScenario,
      'allEntries': filtered,
    };
  }
}
