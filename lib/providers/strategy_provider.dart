import 'package:flutter/foundation.dart';
import '../models/strategy_state.dart';
import '../models/order.dart';
import '../services/strategy_engine.dart';
import '../storage/local_storage.dart';

class StrategyProvider extends ChangeNotifier {
  StrategyState? _state;
  bool _isLoading = true;
  String _lastLog = '';
  List<Order> _lastBuyOrders = [];
  List<Order> _lastSellOrders = [];
  bool _cycleJustCompleted = false;

  StrategyState? get state => _state;
  bool get isLoading => _isLoading;
  bool get hasActiveStrategy => _state != null;
  String get lastLog => _lastLog;
  List<Order> get lastBuyOrders => _lastBuyOrders;
  List<Order> get lastSellOrders => _lastSellOrders;
  bool get cycleJustCompleted => _cycleJustCompleted;

  StrategyProvider() {
    _loadFromStorage();
  }

  Future<void> _loadFromStorage() async {
    _isLoading = true;
    notifyListeners();
    _state = await LocalStorage.loadState();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> startStrategy({
    required double capital,
    required int splitCount,
    required double targetProfit,
  }) async {
    _state = StrategyState(
      capital: capital,
      splitCount: splitCount,
      targetProfit: targetProfit,
      startDate: DateTime.now(),
    );
    _lastBuyOrders = [];
    _lastSellOrders = [];
    _lastLog = '';
    _cycleJustCompleted = false;
    await LocalStorage.saveState(_state!);
    notifyListeners();
  }

  Future<void> calculate(double prevClose, double prevHigh) async {
    if (_state == null) return;

    final prevCycleCount = _state!.cycleResults.length;
    final result = StrategyEngine.calculate(_state!, prevClose, prevHigh);

    _state = result.updatedState;
    _lastBuyOrders = result.buyOrders;
    _lastSellOrders = result.sellOrders;
    _lastLog = result.log;
    _cycleJustCompleted = _state!.cycleResults.length > prevCycleCount;

    await LocalStorage.saveState(_state!);
    notifyListeners();
  }

  Future<void> resetStrategy() async {
    await LocalStorage.clearState();
    _state = null;
    _lastBuyOrders = [];
    _lastSellOrders = [];
    _lastLog = '';
    _cycleJustCompleted = false;
    notifyListeners();
  }

  void clearCycleFlag() {
    _cycleJustCompleted = false;
    notifyListeners();
  }
}
