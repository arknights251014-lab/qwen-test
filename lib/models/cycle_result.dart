// cycle_result.dart
import 'strategy_state.dart';

class CycleResult {
  final String symbol;
  final int splitCount;
  final double targetProfit;
  final double startCapital;
  final double endAsset;
  final double totalProfit;
  final double returnRate;
  final int investmentPeriod;
  final double maxT;
  final double maxQty;
  final double maxExposure;
  final CompletionReason completionReason;

  const CycleResult({
    required this.symbol,
    required this.splitCount,
    required this.targetProfit,
    required this.startCapital,
    required this.endAsset,
    required this.totalProfit,
    required this.returnRate,
    required this.investmentPeriod,
    required this.maxT,
    required this.maxQty,
    required this.maxExposure,
    required this.completionReason,
  });
}