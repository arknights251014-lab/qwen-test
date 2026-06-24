// create_strategy_page.dart
import 'package:flutter/material.dart';
import '../strategy_state.dart';
import '../persistence_service.dart';
import 'dashboard_page.dart';

class CreateStrategyPage extends StatefulWidget {
  const CreateStrategyPage({super.key});

  @override
  State<CreateStrategyPage> createState() => _CreateStrategyPageState();
}

class _CreateStrategyPageState extends State<CreateStrategyPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final _symbolController = TextEditingController(text: 'BTC');
  final _capitalController = TextEditingController(text: '10000');
  final _splitCountController = TextEditingController(text: '10');
  final _targetProfitController = TextEditingController(text: '10');

  final _closeControllers = List.generate(5, (_) => TextEditingController());

  final _cashController = TextEditingController();
  final _qtyController = TextEditingController();
  final _avgController = TextEditingController();
  final _tController = TextEditingController();
  Mode _mode = Mode.normal;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _symbolController.dispose();
    _capitalController.dispose();
    _splitCountController.dispose();
    _targetProfitController.dispose();
    for (var c in _closeControllers) c.dispose();
    _cashController.dispose();
    _qtyController.dispose();
    _avgController.dispose();
    _tController.dispose();
    super.dispose();
  }

  Future<void> _createStrategy() async {
    try {
      final symbol = _symbolController.text;
      final capital = double.parse(_capitalController.text);
      final splitCount = int.parse(_splitCountController.text);
      final targetProfit = double.parse(_targetProfitController.text);

      final closeHistory = _closeControllers.map((c) => double.parse(c.text)).toList();

      double cash = capital;
      double qty = 0;
      double avg = 0;
      double t = 0;
      Mode mode = Mode.normal;

      if (_tabController.index == 1) {
        cash = double.parse(_cashController.text);
        qty = double.parse(_qtyController.text);
        avg = double.parse(_avgController.text);
        t = double.parse(_tController.text);
        mode = _mode;
      }

      if (cash < 0 || qty < 0 || avg < 0 || t < 0) {
        throw Exception('값은 0 이상이어야 합니다.');
      }

      final state = StrategyState(
        capital: capital,
        symbol: symbol,
        splitCount: splitCount,
        targetProfit: targetProfit,
        cash: cash,
        qty: qty,
        avg: avg,
        t: t,
        mode: mode,
        closeHistory: closeHistory,
        startCapital: cash + (qty * avg),
        startDate: DateTime.now(),
        currentCycle: 1,
        cycleStatus: CycleStatus.running,
        hasPosition: qty > 0,
        maxT: t,
        maxQty: qty,
        maxExposure: 0,
      );

      await PersistenceService().saveState(state);

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const DashboardPage()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('입력값이 올바르지 않습니다: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('전략 생성'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '초기진입'),
            Tab(text: '중간진입'),
          ],
        ),
      ),
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
                    TextField(
                      controller: _symbolController,
                      decoration: const InputDecoration(labelText: 'Symbol'),
                    ),
                    TextField(
                      controller: _capitalController,
                      decoration: const InputDecoration(labelText: 'Capital'),
                      keyboardType: TextInputType.number,
                    ),
                    TextField(
                      controller: _splitCountController,
                      decoration: const InputDecoration(labelText: 'SplitCount (N)'),
                      keyboardType: TextInputType.number,
                    ),
                    TextField(
                      controller: _targetProfitController,
                      decoration: const InputDecoration(labelText: 'TargetProfit (%)'),
                      keyboardType: TextInputType.number,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Close History (최근 5일)', style: TextStyle(fontWeight: FontWeight.bold)),
                    ...List.generate(5, (i) => TextField(
                      controller: _closeControllers[i],
                      decoration: InputDecoration(labelText: 'Close ${i + 1}'),
                      keyboardType: TextInputType.number,
                    )),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (_tabController.index == 1)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      TextField(
                        controller: _cashController,
                        decoration: const InputDecoration(labelText: 'Cash'),
                        keyboardType: TextInputType.number,
                      ),
                      TextField(
                        controller: _qtyController,
                        decoration: const InputDecoration(labelText: 'Qty'),
                        keyboardType: TextInputType.number,
                      ),
                      TextField(
                        controller: _avgController,
                        decoration: const InputDecoration(labelText: 'Avg'),
                        keyboardType: TextInputType.number,
                      ),
                      TextField(
                        controller: _tController,
                        decoration: const InputDecoration(labelText: 'T'),
                        keyboardType: TextInputType.number,
                      ),
                      DropdownButtonFormField<Mode>(
                        value: _mode,
                        items: Mode.values.map((m) => DropdownMenuItem(value: m, child: Text(m.name.toUpperCase()))).toList(),
                        onChanged: (v) => setState(() => _mode = v!),
                        decoration: const InputDecoration(labelText: 'Mode'),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _createStrategy,
              icon: const Icon(Icons.check),
              label: const Text('전략 생성 및 시작'),
            ),
          ],
        ),
      ),
    );
  }
}