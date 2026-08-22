import 'package:flutter/material.dart';
import 'coin_detail_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final coins = ['LINKUSDT', 'BCHUSDT'];
    return Scaffold(
      appBar: AppBar(title: const Text('Oussstr')),
      body: ListView.builder(
        itemCount: coins.length,
        itemBuilder: (context, index) {
          final symbol = coins[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: ListTile(
              title: Text(symbol, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              subtitle: const Text('اضغط لعرض إشارة اليوم'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => CoinDetailScreen(symbol: symbol)),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
