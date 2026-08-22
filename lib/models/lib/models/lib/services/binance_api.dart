hereimport 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/candle.dart';

class BinanceApi {
  static const String _base = 'https://api.binance.com/api/v3';

  Future<List<Candle>> getCandles(String symbol, String interval, {int limit = 100}) async {
    final url = Uri.parse('$_base/klines?symbol=$symbol&interval=$interval&limit=$limit');
    final res = await http.get(url).timeout(const Duration(seconds: 15));
    if (res.statusCode != 200) {
      throw Exception('Binance API error ${res.statusCode}: ${res.body}');
    }
    final List<dynamic> data = jsonDecode(res.body);
    final candles = <Candle>[];
    for (int i = 0; i < data.length; i++) {
      candles.add(Candle.fromBinance(data[i] as List<dynamic>, isLast: i == data.length - 1));
    }
    return candles;
  }

  Future<double> getCurrentPrice(String symbol) async {
    final url = Uri.parse('$_base/ticker/price?symbol=$symbol');
    final res = await http.get(url).timeout(const Duration(seconds: 15));
    if (res.statusCode != 200) {
      throw Exception('Binance API error ${res.statusCode}: ${res.body}');
    }
    final data = jsonDecode(res.body);
    return double.parse(data['price'].toString());
  }
}
