import 'package:flutter/material.dart';
import '../services/journal_service.dart';
import '../models/journal_entry.dart';

class JournalScreen extends StatefulWidget {
  const JournalScreen({super.key});

  @override
  State<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen> {
  final JournalService _service = JournalService();
  Map<String, dynamic>? _stats;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final stats = await _service.getStats();
    setState(() {
      _stats = stats;
      _loading = false;
    });
  }

  String _scenarioNameAr(String raw) {
    if (raw.contains('breakout')) return 'اختراق مباشر';
    if (raw.contains('retest')) return 'اختراق + تصحيح';
    if (raw.contains('reversal')) return 'ارتداد';
    if (raw.contains('continuation')) return 'استمرار الاتجاه';
    return 'غير محدد';
  }

  String _resultLabel(JournalResult r) {
    switch (r) {
      case JournalResult.win:
        return '✅ ربح';
      case JournalResult.loss:
        return '❌ خسارة';
      case JournalResult.pending:
        return '⏳ قيد الانتظار';
      case JournalResult.skipped:
        return '⏭️ تم تخطيها';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('سجل الأداء')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Card(
                    color: Colors.blue.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('نسبة النجاح الإجمالية: ${(_stats!['winRate'] as double).toStringAsFixed(1)}%',
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          Text('عدد الصفقات المحسومة: ${_stats!['totalResolved']} (فوز: ${_stats!['wins']})'),
                          const SizedBox(height: 6),
                          const Text(
                            'ملاحظة: كل ما زاد عدد الصفقات المحسومة، صارت النسبة أدق وأكثر تمثيلاً للواقع.',
                            style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('الأداء حسب السيناريو:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ...((_stats!['byScenario'] as Map<String, Map<String, int>>).entries.map((e) {
                    final win = e.value['win'] ?? 0;
                    final total = e.value['total'] ?? 0;
                    final rate = total == 0 ? 0.0 : (win / total) * 100;
                    return Card(
                      child: ListTile(
                        title: Text(_scenarioNameAr(e.key)),
                        subtitle: Text('$win فوز من $total صفقة'),
                        trailing: Text('${rate.toStringAsFixed(0)}%',
                            style: const TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    );
                  })),
                  const SizedBox(height: 16),
                  const Text('سجل الصفقات:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ...((_stats!['allEntries'] as List<JournalEntry>).reversed.map((entry) {
                    return Card(
                      child: ListTile(
                        title: Text('${entry.symbol} — ${_scenarioNameAr(entry.scenarioType)}'),
                        subtitle: Text('${entry.dateKey} · الفريم: ${entry.timeframePair}'),
                        trailing: Text(_resultLabel(entry.result)),
                      ),
                    );
                  })),
                ],
              ),
            ),
    );
  }
}
