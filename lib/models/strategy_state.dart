// strategy_state.dart
enum Mode {
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
  // 공통 입력값 (Inputs)
  final double capital;
  final String symbol;
  final int splitCount;
  final double targetProfit;

  // 상태 변수 (State Variables)
  final double cash;
  final double qty;
  final double avg;
  final double t;
  final Mode mode;
  final List<double> closeHistory;
  final double startCapital;
  final DateTime startDate;
  final int currentCycle;
  final CycleStatus cycleStatus;
  final CompletionReason? completionReason;
  final bool hasPosition;
  final double maxT;
  final double maxQty;
  final double maxExposure;

  const StrategyState({
    required this.capital,
    required this.symbol,
    required this.splitCount,
    required this.targetProfit,
    required this.cash,
    required this.qty,
    required this.avg,
    required this.t,
    required this.mode,
    required this.closeHistory,
    required this.startCapital,
    required this.startDate,
    required this.currentCycle,
    required this.cycleStatus,
    this.completionReason,
    required this.hasPosition,
    required this.maxT,
    required this.maxQty,
    required this.maxExposure,
  });

  factory StrategyState.initial({
    required double capital,
    required String symbol,
    required int splitCount,
    required double targetProfit,
    required List<double> initialCloseHistory,
  }) {
    return StrategyState(
      capital: capital,
      symbol: symbol,
      splitCount: splitCount,
      targetProfit: targetProfit,
      cash: capital,
      qty: 0,
      avg: 0,
      t: 0,
      mode: Mode.normal,
      closeHistory: initialCloseHistory,
      startCapital: capital,
      startDate: DateTime.now(),
      currentCycle: 1,
      cycleStatus: CycleStatus.running,
      completionReason: null,
      hasPosition: false,
      maxT: 0,
      maxQty: 0,
      maxExposure: 0,
    );
  }

  StrategyState copyWith({
    double? capital,
    String? symbol,
    int? splitCount,
    double? targetProfit,
    double? cash,
    double? qty,
    double? avg,
    double? t,
    Mode? mode,
    List<double>? closeHistory,
    double? startCapital,
    DateTime? startDate,
    int? currentCycle,
    CycleStatus? cycleStatus,
    CompletionReason? completionReason,
    bool? clearCompletionReason,
    bool? hasPosition,
    double? maxT,
    double? maxQty,
    double? maxExposure,
  }) {
    return StrategyState(
      capital: capital ?? this.capital,
      symbol: symbol ?? this.symbol,
      splitCount: splitCount ?? this.splitCount,
      targetProfit: targetProfit ?? this.targetProfit,
      cash: cash ?? this.cash,
      qty: qty ?? this.qty,
      avg: avg ?? this.avg,
      t: t ?? this.t,
      mode: mode ?? this.mode,
      closeHistory: closeHistory ?? this.closeHistory,
      startCapital: startCapital ?? this.startCapital,
      startDate: startDate ?? this.startDate,
      currentCycle: currentCycle ?? this.currentCycle,
      cycleStatus: cycleStatus ?? this.cycleStatus,
      completionReason: (clearCompletionReason == true) ? null : (completionReason ?? this.completionReason),
      hasPosition: hasPosition ?? this.hasPosition,
      maxT: maxT ?? this.maxT,
      maxQty: maxQty ?? this.maxQty,
      maxExposure: maxExposure ?? this.maxExposure,
    );
  }
}