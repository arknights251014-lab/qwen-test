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

  /// 신규 시작 + 중간진입 공용
  Future<void> startStrategy({
    required String symbol,
    required double cash,
    required int splitCount,
    required double targetProfit,

    int qty = 0,
    double avg = 0,
    double t = 0,

    StrategyMode mode = StrategyMode.normal,

    List<double>? closeHistory,
  }) async {
    _state = StrategyState(
      symbol: symbol,

      splitCount: splitCount,
      targetProfit: targetProfit,

      cash: cash,

      qty: qty,
      avg: avg,
      t: t,

      mode: mode,

      hasPosition: qty > 0,

      cycleStatus: CycleStatus.running,

      closeHistory: closeHistory ?? [],

      startDate: DateTime.now(),
      startCapital: cash,

      currentCycle: 1,
    );

    _lastBuyOrders = [];
    _lastSellOrders = [];
    _lastLog = '';

    _cycleJustCompleted = false;

    await LocalStorage.saveState(_state!);

    notifyListeners();
  }

  Future<void> calculate(
    double prevClose,
    double prevHigh,
  ) async {
    if (_state == null) return;

    if (_state!.cycleStatus ==
        CycleStatus.completed) {
      return;
    }

    final beforeCount =
        _state!.cycleResults.length;

    final result =
        StrategyEngine.calculate(
      _state!,
      prevClose,
      prevHigh,
    );

    _state = result.updatedState;

    _lastBuyOrders = result.buyOrders;
    _lastSellOrders = result.sellOrders;

    _lastLog = result.log;

    _cycleJustCompleted =
        _state!.cycleResults.length >
            beforeCount;

    await LocalStorage.saveState(_state!);

    notifyListeners();
  }

  /// 강제 종료
  Future<void> forceCompleteCycle(
      double exitPrice) async {
    if (_state == null) return;

    final s = _state!;

    if (s.qty > 0) {
      s.cash += s.qty * exitPrice;
    }

    s.qty = 0;
    s.avg = 0;
    s.t = 0;

    s.mode = StrategyMode.normal;

    s.hasPosition = false;

    s.cycleStatus =
        CycleStatus.completed;

    s.completionReason =
        CompletionReason.forcedExit;

    await LocalStorage.saveState(s);

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