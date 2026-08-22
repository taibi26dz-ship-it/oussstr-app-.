import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/candle.dart';
import '../models/scenario_result.dart';
import '../models/journal_entry.dart';
import '../services/binance_api.dart';
import '../services/journal_service.dart';
import 'wyckoff_filter.dart';
import 'ict_zones.dart';
import 'scenario_breakout.dart';
import 'scenario_retest.dart';
import 'scenario_reversal.dart';
import 'scenario_continuation.dart';
import 'mtf_confluence.dart';

class SignalEngine {
  final BinanceApi api = BinanceApi();
  final JournalService journal = JournalService();

  Future<DailySignal> getTodaySignal(String symbol) async {
    DailySignal signal;
    final persisted = await _loadPersistedSignal(symbol);

    if (persisted != null) {
      signal = persisted;
    } else {
      signal = await _generateNewSignal(symbol);
      await _persistSignal(symbol, signal);
      if (signal.scenario.entry != null) {
        await journal.upsertPending(JournalEntry(
          symbol: symbol,
          dateKey: _todayKey(),
          scenarioType: signal.scenario.type.toString(),
          strength: signal.strength.toString(),
          timeframePair: signal.timeframePair,
          score: signal.scenario.score,
        ));
      }
    }

    if (signal.scenario.entry != null) {
      try {
        final currentPrice = await api.getCurrentPrice(symbol);
        signal.currentPrice = currentPrice;
        signal.tradeStatus = _computeTradeStatus(signal.scenario, currentPrice);

        if (signal.tradeStatus == TradeStatus.hitStopLoss) {
          await journal.updateResult(symbol, _todayKey(), JournalResult.loss);
        } else if (signal.tradeStatus == TradeStatus.hitTp1 ||
            signal.tradeStatus == TradeStatus.hitTp2 ||
            signal.tradeStatus == TradeStatus.hitTp3) {
          await journal.updateResult(symbol, _todayKey(), JournalResult.win);
        }
      } catch (_) {}
    }

    return signal;
  }

  TradeStatus _computeTradeStatus(ScenarioResult scenario, double currentPrice) {
    final sl = scenario.stopLoss;
    final tps = scenario.takeProfits;
    if (sl == null) return TradeStatus.noTrade;

    if (currentPrice <= sl) {
      return TradeStatus.hitStopLoss;
    }
    if (tps != null && tps.isNotEmpty) {
      if (tps.length >= 3 && currentPrice >= tps[2]) return TradeStatus.hitTp3;
      if (tps.length >= 2 && currentPrice >= tps[1]) return TradeStatus.hitTp2;
      if (currentPrice >= tps[0]) return TradeStatus.hitTp1;
    }
    return TradeStatus.active;
  }

  Future<DailySignal> _generateNewSignal(String symbol) async {
    final daily = await api.getCandles(symbol, '1d', limit: 30);
    final h1 = await api.getCandles(symbol, '1h', limit: 100);
    final h4 = await api.getCandles(symbol, '4h', limit: 60);
    final m15 = await api.getCandles(symbol, '15m', limit: 100);
    final weekly = await api.getCandles(symbol, '1w', limit: 20);

    final resultsDaily = _evaluatePair(higherTf: daily, entryTf: h1, mtfReference: weekly);
    final results4h = _evaluatePair(higherTf: h4, entryTf: m15, mtfReference: daily);

    final allCandidates = <MapEntry<String, ScenarioResult>>[];
    resultsDaily.forEach((k, v) {
      if (v.triggered) allCandidates.add(MapEntry('daily_1h', v));
    });
    results4h.forEach((k, v) {
      if (v.triggered) allCandidates.add(MapEntry('4h_15m', v));
    });

    ScenarioResult? best;
    String bestPair = 'daily_1h';
    double bestScore = -1;
    for (final entry in allCandidates) {
      if (entry.value.score > bestScore) {
        bestScore = entry.value.score;
        best = entry.value;
        bestPair = entry.key;
      }
    }

    SignalStrength strength;
    ScenarioResult finalScenario;
    String notes;

    if (best != null && best.score >= 70) {
      strength = SignalStrength.strong;
      finalScenario = best;
      notes = 'Strong setup found';
    } else if (best != null && best.score >= 55) {
      strength = SignalStrength.medium;
      finalScenario = best;
      notes = 'Medium-confidence setup';
    } else if (best != null) {
      strength = SignalStrength.weakForced;
      finalScenario = best;
      notes = 'No scenario met the normal quality bar — best available setup today, flagged as weak/forced';
    } else {
      strength = SignalStrength.weakForced;
      finalScenario = ScenarioResult(
        type: ScenarioType.none,
        triggered: false,
        score: 0,
        reason: 'No scenario reached trigger conditions on either timeframe pair today',
      );
      notes = 'No valid setup triggered — manual review recommended, consider skipping today';
    }

    return DailySignal(
      symbol: symbol,
      timeframePair: bestPair,
      scenario: finalScenario,
      strength: strength,
      generatedAt: DateTime.now(),
      notes: notes,
    );
  }

  Map<ScenarioType, ScenarioResult> _evaluatePair({
    required List<Candle> higherTf,
    required List<Candle> entryTf,
    required List<Candle> mtfReference,
  }) {
    final wyckoff = WyckoffFilter.analyze(higherTf);
    final closedHigher = higherTf.where((c) => c.isClosed).toList();
    double rangeHigh = 0, rangeLow = 0;
    if (closedHigher.length >= 2) {
      final rangeCandle = closedHigher[closedHigher.length - 2];
      rangeHigh = rangeCandle.high;
      rangeLow = rangeCandle.low;
    }
    final currentPrice = entryTf.isNotEmpty ? entryTf.last.close : 0.0;
    final ict = IctZones.analyze(rangeHigh, rangeLow, currentPrice);
    final mtfAdjustment = MtfConfluence.check(mtfReference);

    final breakout = ScenarioBreakout.check(higherTfCandles: higherTf, entryTfCandles: entryTf);
    final retest = ScenarioRetest.check(higherTfCandles: higherTf, entryTfCandles: entryTf);
    final reversal = ScenarioReversal.check(higherTfCandles: higherTf, entryTfCandles: entryTf);
    final continuation = ScenarioContinuation.check(higherTfCandles: higherTf, entryTfCandles: entryTf);

    final adjustment = wyckoff.scoreAdjustment + ict.scoreAdjustment + mtfAdjustment;

    return {
      ScenarioType.breakout: _applyAdjustment(breakout, adjustment),
      ScenarioType.retest: _applyAdjustment(retest, adjustment),
      ScenarioType.reversal: _applyAdjustment(reversal, adjustment),
      ScenarioType.continuation: _applyAdjustment(continuation, adjustment),
    };
  }

  ScenarioResult _applyAdjustment(ScenarioResult result, double adjustment) {
    if (!result.triggered) return result;
    final newScore = (result.score + adjustment).clamp(0, 100).toDouble();
    return ScenarioResult(
      type: result.type,
      triggered: result.triggered,
      score: newScore,
      entry: result.entry,
      stopLoss: result.stopLoss,
      takeProfits: result.takeProfits,
      reason: result.reason,
    );
  }

  Future<void> _persistSignal(String symbol, DailySignal signal) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'signal_${symbol}_${_todayKey()}';
    await prefs.setString(key, jsonEncode(signal.toJson()));
  }

  Future<DailySignal?> _loadPersistedSignal(String symbol) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'signal_${symbol}_${_todayKey()}';
    final raw = prefs.getString(key);
    if (raw == null) return null;
    try {
      return DailySignal.fromJson(jsonDecode(raw));
    } catch (_) {
      return null;
    }
  }

  String _todayKey() {
    final now = DateTime.now().toUtc();
    return '${now.year}-${now.month}-${now.day}';
  }
}
