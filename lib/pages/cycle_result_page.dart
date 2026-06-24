// cycle_result_page.dart
import 'package:flutter/material.dart';
import '../cycle_result.dart';
import '../persistence_service.dart';
import 'create_strategy_page.dart';

class CycleResultPage extends StatelessWidget {
  final CycleResult result;
  
  const CycleResultPage({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('사이클 결과')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    ListTile(title: const Text('종목'), subtitle: Text(result.symbol)),
                    ListTile(title: const Text('분할수'), subtitle: Text('${result.splitCount}')),
                    ListTile(title: const Text('목표수익률'), subtitle: Text('${result.targetProfit}%')),
                    ListTile(title: const Text('시작원금'), subtitle: Text('${result.startCapital.toStringAsFixed(2)}')),
                    ListTile(title: const Text('종료자산'), subtitle: Text('${result.endAsset.toStringAsFixed(2)}')),
                    ListTile(title: const Text('총 수익금'), subtitle: Text('${result.totalProfit.toStringAsFixed(2)}')),
                    ListTile(title: const Text('수익률'), subtitle: Text('${result.returnRate.toStringAsFixed(2)}%')),
                    ListTile(title: const Text('투자기간'), subtitle: Text('${result.investmentPeriod}일')),
                    ListTile(title: const Text('최대 T'), subtitle: Text('${result.maxT.toStringAsFixed(2)}')),
                    ListTile(title: const Text('최대 보유수량'), subtitle: Text('${result.maxQty.toStringAsFixed(2)}')),
                    ListTile(title: const Text('최대 투자금'), subtitle: Text('${result.maxExposure.toStringAsFixed(2)}')),
                    ListTile(title: const Text('종료사유'), subtitle: Text(result.completionReason.name.toUpperCase())),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () async {
                await PersistenceService().clearState();
                if (context.mounted) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const CreateStrategyPage()),
                    (route) => false,
                  );
                }
              },
              icon: const Icon(Icons.add),
              label: const Text('새 전략 생성'),
            ),
          ],
        ),
      ),
    );
  }
}