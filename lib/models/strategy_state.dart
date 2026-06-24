import 'order.dart';
import 'cycle_result.dart';

enum StrategyMode {
  normal,
  reverse,
}

enum CycleStatus {
  running,
  completed,
}

enum CompletionReason {
  normalExit,
  forcedExit,
}

class StrategyState {
  // 전략 설정
  String symbol;
  int splitCount;
  double targetProfit;

  // 계좌 상태
  double cash;
  int qty;
  double avg;
  double t;

  StrategyMode mode;

  // 포지션 여부
  bool hasPosition;

  // 사이클 상태
  CycleStatus cycleStatus;
  CompletionReason? completionReason;

  // 종가 이력
  List<double> closeHistory;

  // 사이클 정보
  DateTime startDate;
  double startCapital;
  int currentCycle;

  // 통계
  double maxT;
  int maxQty;
  double maxExposure;

  // 주문
  List<Order> buyOrders;
  List<Order> sellOrders;

  // 결과
  List<CycleResult> cycleResults;

  StrategyState({
    this.symbol = 'SOXL',
    required this.splitCount,
    required this.targetProfit,

    required this.cash,

    this.qty = 0,
    this.avg = 0,
    this.t = 0,

    this.mode = StrategyMode.normal,

    this.hasPosition = false,

    this.cycleStatus = CycleStatus.running,
    this.completionReason,

    List<double>? closeHistory,

    DateTime? startDate,
    double? startCapital,

    this.currentCycle = 1,

    this.maxT = 0,
    this.maxQty = 0,
    this.maxExposure = 0,

    List<Order>? buyOrders,
    List<Order>? sellOrders,

    List<CycleResult>? cycleResults,
  })  : closeHistory = closeHistory ?? [],
        startDate = startDate ?? DateTime.now(),
        startCapital = startCapital ?? cash,
        buyOrders = buyOrders ?? [],
        sellOrders = sellOrders ?? [],
        cycleResults = cycleResults ?? [];

  // ==========================
  // 계산값
  // ==========================

  double get sma5 {
    if (closeHistory.isEmpty) return 0;

    if (closeHistory.length < 5) {
      return closeHistory.reduce((a, b) => a + b) /
          closeHistory.length;
    }

    final recent =
        closeHistory.sublist(closeHistory.length - 5);

    return recent.reduce((a, b) => a + b) / 5;
  }

  double get starPct =>
      targetProfit -
      (targetProfit / splitCount) * 2 * t;

  double get starPrice =>
      avg > 0
          ? avg * (1 + starPct / 100)
          : 0;

  double get buyStar =>
      starPrice > 0
          ? starPrice - 0.01
          : 0;

  double get sellStar => starPrice;

  double get buyAmount {
    final remain = splitCount - t;

    if (remain <= 0) {
      return 0;
    }

    return cash / remain;
  }

  double get finalSellPrice =>
      avg > 0
          ? avg * (1 + targetProfit / 100)
          : 0;

  bool get isRunning =>
      cycleStatus == CycleStatus.running;

  bool get isCompleted =>
      cycleStatus == CycleStatus.completed;

  // ==========================
  // JSON
  // ==========================

  Map<String, dynamic> toJson() {
    return {
      'symbol': symbol,

      'splitCount': splitCount,
      'targetProfit': targetProfit,

      'cash': cash,
      'qty': qty,
      'avg': avg,
      't': t,

      'mode': mode.index,

      'hasPosition': hasPosition,

      'cycleStatus': cycleStatus.index,
      'completionReason': completionReason?.index,

      'closeHistory': closeHistory,

      'startDate': startDate.toIso8601String(),
      'startCapital': startCapital,

      'currentCycle': currentCycle,

      'maxT': maxT,
      'maxQty': maxQty,
      'maxExposure': maxExposure,

      'buyOrders':
          buyOrders.map((e) => e.toJson()).toList(),

      'sellOrders':
          sellOrders.map((e) => e.toJson()).toList(),

      'cycleResults':
          cycleResults.map((e) => e.toJson()).toList(),
    };
  }

  factory StrategyState.fromJson(
      Map<String, dynamic> json) {
    return StrategyState(
      symbol: json['symbol'] ?? 'SOXL',

      splitCount: json['splitCount'] ?? 20,

      targetProfit:
          (json['targetProfit'] ?? 20).toDouble(),

      cash: (json['cash'] ?? 0).toDouble(),

      qty: json['qty'] ?? 0,

      avg: (json['avg'] ?? 0).toDouble(),

      t: (json['t'] ?? 0).toDouble(),

      mode: StrategyMode.values[
          json['mode'] ?? 0],

      hasPosition:
          json['hasPosition'] ??
              ((json['qty'] ?? 0) > 0),

      cycleStatus: CycleStatus.values[
          json['cycleStatus'] ?? 0],

      completionReason:
          json['completionReason'] != null
              ? CompletionReason.values[
                  json['completionReason']]
              : null,

      closeHistory:
          (json['closeHistory'] as List?)
                  ?.map(
                    (e) =>
                        (e as num).toDouble(),
                  )
                  .toList() ??
              [],

      startDate:
          DateTime.parse(json['startDate']),

      startCapital:
          (json['startCapital'] ?? 0)
              .toDouble(),

      currentCycle:
          json['currentCycle'] ?? 1,

      maxT:
          (json['maxT'] ?? 0).toDouble(),

      maxQty:
          json['maxQty'] ?? 0,

      maxExposure:
          (json['maxExposure'] ?? 0)
              .toDouble(),

      buyOrders:
          (json['buyOrders'] as List?)
                  ?.map(
                    (e) => Order.fromJson(
                      e as Map<String, dynamic>,
                    ),
                  )
                  .toList() ??
              [],

      sellOrders:
          (json['sellOrders'] as List?)
                  ?.map(
                    (e) => Order.fromJson(
                      e as Map<String, dynamic>,
                    ),
                  )
                  .toList() ??
              [],

      cycleResults:
          (json['cycleResults'] as List?)
                  ?.map(
                    (e) =>
                        CycleResult.fromJson(
                      e as Map<String, dynamic>,
                    ),
                  )
                  .toList() ??
              [],
    );
  }

  StrategyState copyWith({
    String? symbol,

    int? splitCount,
    double? targetProfit,

    double? cash,
    int? qty,
    double? avg,
    double? t,

    StrategyMode? mode,

    bool? hasPosition,

    CycleStatus? cycleStatus,
    CompletionReason? completionReason,

    List<double>? closeHistory,

    DateTime? startDate,
    double? startCapital,

    int? currentCycle,

    double? maxT,
    int? maxQty,
    double? maxExposure,

    List<Order>? buyOrders,
    List<Order>? sellOrders,

    List<CycleResult>? cycleResults,
  }) {
    return StrategyState(
      symbol: symbol ?? this.symbol,

      splitCount:
          splitCount ?? this.splitCount,

      targetProfit:
          targetProfit ?? this.targetProfit,

      cash: cash ?? this.cash,

      qty: qty ?? this.qty,

      avg: avg ?? this.avg,

      t: t ?? this.t,

      mode: mode ?? this.mode,

      hasPosition:
          hasPosition ?? this.hasPosition,

      cycleStatus:
          cycleStatus ?? this.cycleStatus,

      completionReason:
          completionReason ??
              this.completionReason,

      closeHistory:
          closeHistory ??
              List.from(this.closeHistory),

      startDate:
          startDate ?? this.startDate,

      startCapital:
          startCapital ??
              this.startCapital,

      currentCycle:
          currentCycle ??
              this.currentCycle,

      maxT: maxT ?? this.maxT,

      maxQty: maxQty ?? this.maxQty,

      maxExposure:
          maxExposure ??
              this.maxExposure,

      buyOrders:
          buyOrders ??
              List.from(this.buyOrders),

      sellOrders:
          sellOrders ??
              List.from(this.sellOrders),

      cycleResults:
          cycleResults ??
              List.from(this.cycleResults),
    );
  }
}