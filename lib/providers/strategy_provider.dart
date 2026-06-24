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

  // ==========================================================
  // 신규 시작
  // ==========================================================

  Future<void> startStrategy({
    required String symbol,
    required double capital,
    required int splitCount,
    required double targetProfit,
  }) async {
    _state = StrategyState(
      symbol: symbol,

      splitCount: splitCount,

      targetProfit: targetProfit,

      cash: capital,

      qty: 0,

      avg: 0,

      t: 0,

      startCapital: capital,

      startDate: DateTime.now(),

      hasPosition: false,
    );

    _lastBuyOrders = [];

    _lastSellOrders = [];

    _lastLog = '';

    _cycleJustCompleted = false;

    await LocalStorage.saveState(_state!);

    notifyListeners();
  }

  // ==========================================================
  // 중간 진입
  // ==========================================================

  Future<void> startMidPosition({
    required String symbol,

    required double cash,

    required int qty,

    required double avg,

    required double t,

    required int splitCount,

    required double targetProfit,
  }) async {
    _state = StrategyState(
      symbol: symbol,

      splitCount: splitCount,

      targetProfit: targetProfit,

      cash: cash,

      qty: qty,

      avg: avg,

      t: t,

      hasPosition: qty > 0,

      startCapital: cash + (qty * avg),

      startDate: DateTime.now(),
    );

    _lastBuyOrders = [];

    _lastSellOrders = [];

    _lastLog = '';

    _cycleJustCompleted = false;

    await LocalStorage.saveState(_state!);

    notifyListeners();
  }

  // ==========================================================
  // 하루 계산
  // ==========================================================

  Future<void> calculate({
    required double prevClose,
    required double prevHigh,
  }) async {
    if (_state == null) return;

    final prevCycleCount =
        _state!.cycleResults.length;

    final result = StrategyEngine.calculate(
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
            prevCycleCount;

    await LocalStorage.saveState(_state!);

    notifyListeners();
  }

  // ==========================================================
  // 강제 종료
  // ==========================================================

  Future<void> forceCompleteCycle(
    double exitPrice,
  ) async {
    if (_state == null) return;

    StrategyEngine.forceCompleteCycle(
      _state!,
      exitPrice,
    );

    _cycleJustCompleted = true;

    await LocalStorage.saveState(_state!);

    notifyListeners();
  }

  // ==========================================================
  // 전략 초기화
  // ==========================================================

  Future<void> resetStrategy() async {
    await LocalStorage.clearState();

    _state = null;

    _lastBuyOrders = [];

    _lastSellOrders = [];

    _lastLog = '';

    _cycleJustCompleted = false;

    notifyListeners();
  }

  // ==========================================================
  // 사이클 완료 플래그 제거
  // ==========================================================

  void clearCycleFlag() {
    _cycleJustCompleted = false;

    notifyListeners();
  }
}