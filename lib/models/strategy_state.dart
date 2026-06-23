import 'dart:convert';
import 'order.dart';
import 'cycle_result.dart';

enum StrategyMode { normal, reverse }

class StrategyState {
  // 기본 설정
  double capital;
  int splitCount;
  double targetProfit;

  // 상태 변수
  double cash;
  int qty;
  double avg;
  double t;
  StrategyMode mode;

  // 이력
  List<double> closeHistory;
  DateTime startDate;
  double startCapital;

  // 통계
  double maxT;
  int maxQty;
  double maxExposure;

  // 주문 목록
  List<Order> buyOrders;
  List<Order> sellOrders;

  // 사이클 결과
  List<CycleResult> cycleResults;
  int currentCycle;

  StrategyState({
    required this.capital,
    required this.splitCount,
    required this.targetProfit,
    double? cash,
    this.qty = 0,
    this.avg = 0,
    this.t = 0,
    this.mode = StrategyMode.normal,
    List<double>? closeHistory,
    DateTime? startDate,
    double? startCapital,
    this.maxT = 0,
    this.maxQty = 0,
    this.maxExposure = 0,
    List<Order>? buyOrders,
    List<Order>? sellOrders,
    List<CycleResult>? cycleResults,
    this.currentCycle = 1,
  })  : cash = cash ?? capital,
        closeHistory = closeHistory ?? [],
        startDate = startDate ?? DateTime.now(),
        startCapital = startCapital ?? capital,
        buyOrders = buyOrders ?? [],
        sellOrders = sellOrders ?? [],
        cycleResults = cycleResults ?? [];

  // 파생 계산값
  double get sma5 {
    if (closeHistory.length < 5) {
      if (closeHistory.isEmpty) return 0;
      final sum = closeHistory.reduce((a, b) => a + b);
      return sum / closeHistory.length;
    }
    final recent = closeHistory.sublist(closeHistory.length - 5);
    return recent.reduce((a, b) => a + b) / 5;
  }

  double get starPct =>
      targetProfit - (targetProfit / splitCount) * 2 * t;

  double get starPrice => avg > 0 ? avg * (1 + starPct / 100) : 0;

  double get buyStar => starPrice > 0 ? starPrice - 0.01 : 0;

  double get sellStar => starPrice;

  double get buyAmount {
    final denom = splitCount - t;
    if (denom <= 0) return 0;
    return cash / denom;
  }

  double get finalSellPrice =>
      avg > 0 ? avg * (1 + targetProfit / 100) : 0;

  double get totalExposure => qty * avg;

  bool get isActive => qty > 0 || t > 0;

  Map<String, dynamic> toJson() => {
        'capital': capital,
        'splitCount': splitCount,
        'targetProfit': targetProfit,
        'cash': cash,
        'qty': qty,
        'avg': avg,
        't': t,
        'mode': mode.index,
        'closeHistory': closeHistory,
        'startDate': startDate.toIso8601String(),
        'startCapital': startCapital,
        'maxT': maxT,
        'maxQty': maxQty,
        'maxExposure': maxExposure,
        'buyOrders': buyOrders.map((o) => o.toJson()).toList(),
        'sellOrders': sellOrders.map((o) => o.toJson()).toList(),
        'cycleResults': cycleResults.map((r) => r.toJson()).toList(),
        'currentCycle': currentCycle,
      };

  factory StrategyState.fromJson(Map<String, dynamic> json) {
    return StrategyState(
      capital: (json['capital'] as num).toDouble(),
      splitCount: json['splitCount'],
      targetProfit: (json['targetProfit'] as num).toDouble(),
      cash: (json['cash'] as num).toDouble(),
      qty: json['qty'],
      avg: (json['avg'] as num).toDouble(),
      t: (json['t'] as num).toDouble(),
      mode: StrategyMode.values[json['mode'] ?? 0],
      closeHistory: (json['closeHistory'] as List<dynamic>)
          .map((e) => (e as num).toDouble())
          .toList(),
      startDate: DateTime.parse(json['startDate']),
      startCapital: (json['startCapital'] as num).toDouble(),
      maxT: (json['maxT'] as num).toDouble(),
      maxQty: json['maxQty'],
      maxExposure: (json['maxExposure'] as num).toDouble(),
      buyOrders: (json['buyOrders'] as List<dynamic>)
          .map((o) => Order.fromJson(o as Map<String, dynamic>))
          .toList(),
      sellOrders: (json['sellOrders'] as List<dynamic>)
          .map((o) => Order.fromJson(o as Map<String, dynamic>))
          .toList(),
      cycleResults: (json['cycleResults'] as List<dynamic>)
          .map((r) => CycleResult.fromJson(r as Map<String, dynamic>))
          .toList(),
      currentCycle: json['currentCycle'] ?? 1,
    );
  }

  StrategyState copyWith({
    double? capital,
    int? splitCount,
    double? targetProfit,
    double? cash,
    int? qty,
    double? avg,
    double? t,
    StrategyMode? mode,
    List<double>? closeHistory,
    DateTime? startDate,
    double? startCapital,
    double? maxT,
    int? maxQty,
    double? maxExposure,
    List<Order>? buyOrders,
    List<Order>? sellOrders,
    List<CycleResult>? cycleResults,
    int? currentCycle,
  }) {
    return StrategyState(
      capital: capital ?? this.capital,
      splitCount: splitCount ?? this.splitCount,
      targetProfit: targetProfit ?? this.targetProfit,
      cash: cash ?? this.cash,
      qty: qty ?? this.qty,
      avg: avg ?? this.avg,
      t: t ?? this.t,
      mode: mode ?? this.mode,
      closeHistory: closeHistory ?? List.from(this.closeHistory),
      startDate: startDate ?? this.startDate,
      startCapital: startCapital ?? this.startCapital,
      maxT: maxT ?? this.maxT,
      maxQty: maxQty ?? this.maxQty,
      maxExposure: maxExposure ?? this.maxExposure,
      buyOrders: buyOrders ?? List.from(this.buyOrders),
      sellOrders: sellOrders ?? List.from(this.sellOrders),
      cycleResults: cycleResults ?? List.from(this.cycleResults),
      currentCycle: currentCycle ?? this.currentCycle,
    );
  }
}
