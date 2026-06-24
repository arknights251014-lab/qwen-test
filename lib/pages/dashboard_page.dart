// dashboard_page.dart
import 'package:flutter/material.dart';
import '../strategy_state.dart';
import '../strategy_engine.dart';
import '../persistence_service.dart';
import 'create_strategy_page.dart';
import 'cycle_result_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  StrategyState? _state;
  DayResult? _lastDayResult;

  final _prevCloseController = TextEditingController();
  final _prevHighController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadState();
  }

  Future<void> _loadState() async {
    final state = await PersistenceService().loadState();
    if (state == null) {
      if (mounted) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const CreateStrategyPage()));
      }
    } else {
      setState(() => _state = state);
    }
  }

  double _getSMA5() {
    if (_state!.closeHistory.isEmpty) return 0;
    return _state!.closeHistory.reduce((a, b) => a + b) / 5;
  }

  double _getCurrentAsset(double prevClose) => _state!.cash + (_state!.qty * prevClose);
  double _getCyclePnL(double prevClose) => _getCurrentAsset(prevClose) - _state!.startCapital;
  double _getCycleReturn(double prevClose) => (_getCyclePnL(prevClose) / _state!.startCapital) * 100;

  double _getBuyAmount() => _state!.cash / (_state!.splitCount - _state!.t);
  double _getStarPct() =>
    _state!.targetProfit -
    ((_state!.targetProfit / _state!.splitCount) * 2 * _state!.t);
  double _getStarPrice() => _state!.avg * (1 + _getStarPct() / 100);
  double _getBuyStar() => _getStarPrice() - 0.01;
  double _getSellStar() => _getStarPrice();
  double _getFinalSellPrice() => _state!.avg * (1 + _state!.targetProfit / 100);

  double _getStarQty() {
    bool is1stHalf = _state!.t < (_state!.splitCount / 2);
    if (is1stHalf) {
      return (_getBuyAmount() / 2 / _getBuyStar()).floorToDouble();
    } else {
      return (_getBuyAmount() / _getBuyStar()).floorToDouble();
    }
  }

  double _getAvgQty() {
    bool is1stHalf = _state!.t < (_state!.splitCount / 2);
    if (is1stHalf) {
      return (_getBuyAmount() / 2 / _state!.avg).roundToDouble();
    }
    return 0;
  }

  double _getQuarterQty() => (_state!.qty * 0.25).floorToDouble();
  double _getFinalQty() => _state!.qty - _getQuarterQty();

  Future<void> _runDay() async {
    final prevClose = double.tryParse(_prevCloseController.text);
    final prevHigh = double.tryParse(_prevHighController.text);

    if (prevClose == null || prevHigh == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('PrevClose와 PrevHigh를 정확히 입력하세요.')));
      return;
    }

    final engine = StrategyEngine();
    final result = engine.processDay(_state!, prevClose, prevHigh);

    await PersistenceService().saveState(result.state);

    setState(() {
      _state = result.state;
      _lastDayResult = result;
    });

    if (result.cycleResult != null) {
      await PersistenceService().clearState();
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => CycleResultPage(result: result.cycleResult!)),
        );
      }
    }
  }

  Future<void> _forceExit() async {
    final controller = TextEditingController();
    final price = await showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('강제 종료'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Force Exit Price'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('취소')),
          TextButton(
            onPressed: () => Navigator.pop(context, double.tryParse(controller.text)),
            child: const Text('종료'),
          ),
        ],
      ),
    );

    if (price != null && _state != null) {
      final engine = StrategyEngine();
      final result = engine.forceClose(_state!, price);
      await PersistenceService().clearState();
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => CycleResultPage(result: result.cycleResult!)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_state == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final prevClose = double.tryParse(_prevCloseController.text) ?? 0.0;

    return Scaffold(
      appBar: AppBar(
        title: Text('${_state!.symbol} Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: _forceExit,
            tooltip: '강제 종료',
          ),
        ],
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('계좌정보', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ListTile(title: const Text('Cash'), subtitle: Text(_state!.cash.toStringAsFixed(2))),
                    ListTile(title: const Text('Qty'), subtitle: Text(_state!.qty.toStringAsFixed(2))),
                    ListTile(title: const Text('Avg'), subtitle: Text(_state!.avg.toStringAsFixed(2))),
                    ListTile(title: const Text('T'), subtitle: Text(_state!.t.toStringAsFixed(2))),
                    ListTile(title: const Text('Mode'), subtitle: Text(_state!.mode.name.toUpperCase())),
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
                    const Text('지표', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ListTile(title: const Text('SMA5'), subtitle: Text(_getSMA5().toStringAsFixed(2))),
                    ListTile(title: const Text('현재 자산'), subtitle: Text(_getCurrentAsset(prevClose).toStringAsFixed(2))),
                    ListTile(title: const Text('사이클 손익'), subtitle: Text(_getCyclePnL(prevClose).toStringAsFixed(2))),
                    ListTile(title: const Text('사이클 수익률'), subtitle: Text('${_getCycleReturn(prevClose).toStringAsFixed(2)}%')),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    TextField(
                      controller: _prevCloseController,
                      decoration: const InputDecoration(labelText: 'PrevClose'),
                      keyboardType: TextInputType.number,
                      onChanged: (_) => setState(() {}),
                    ),
                    TextField(
                      controller: _prevHighController,
                      decoration: const InputDecoration(labelText: 'PrevHigh'),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: _runDay,
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('오늘 계산 실행'),
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
                    const Text('오늘 계산값 (예상)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ListTile(title: const Text('BuyAmount'), subtitle: Text(_getBuyAmount().toStringAsFixed(2))),
                    ListTile(title: const Text('StarPct'), subtitle: Text(_getStarPct().toStringAsFixed(2))),
                    ListTile(title: const Text('StarPrice'), subtitle: Text(_getStarPrice().toStringAsFixed(2))),
                    ListTile(title: const Text('BuyStar'), subtitle: Text(_getBuyStar().toStringAsFixed(2))),
                    ListTile(title: const Text('SellStar'), subtitle: Text(_getSellStar().toStringAsFixed(2))),
                    ListTile(title: const Text('FinalSellPrice'), subtitle: Text(_getFinalSellPrice().toStringAsFixed(2))),
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
                    const Text('오늘 주문 (예상 수량)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ListTile(title: const Text('StarQty'), subtitle: Text(_getStarQty().toStringAsFixed(2))),
                    ListTile(title: const Text('AvgQty'), subtitle: Text(_getAvgQty().toStringAsFixed(2))),
                    ListTile(title: const Text('QuarterQty'), subtitle: Text(_getQuarterQty().toStringAsFixed(2))),
                    ListTile(title: const Text('FinalQty'), subtitle: Text(_getFinalQty().toStringAsFixed(2))),
                  ],
                ),
              ),
            ),
            if (_lastDayResult != null) ...[
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('오늘 생성된 주문', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ..._lastDayResult!.todaysOrders.map((o) => ListTile(
                        title: Text(o.type.name),
                        subtitle: Text('Price: ${o.orderPrice.toStringAsFixed(2)} / Qty: ${o.qty.toStringAsFixed(2)}'),
                      )),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}