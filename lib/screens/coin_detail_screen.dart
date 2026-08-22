import 'package:flutter/material.dart';
import '../analysis/signal_engine.dart';
import '../models/scenario_result.dart';
import '../widgets/signal_card.dart';

class CoinDetailScreen extends StatefulWidget {
  final String symbol;

  const CoinDetailScreen({super.key, required this.symbol});

  @override
  State<CoinDetailScreen> createState() => _CoinDetailScreenState();
}

class _CoinDetailScreenState extends State<CoinDetailScreen> {
  final SignalEngine _engine = SignalEngine();
  DailySignal? _signal;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final signal = await _engine.getTodaySignal(widget.symbol);
      setState(() {
        _signal = signal;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.symbol)),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? ListView(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text('خطأ: $_error', style: const TextStyle(color: Colors.red)),
                      ),
                    ],
                  )
                : ListView(
                    children: [
                      if (_signal != null) SignalCard(signal: _signal!),
                    ],
                  ),
      ),
    );
  }
}
