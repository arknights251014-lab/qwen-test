// persistence_service.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/strategy_state.dart';

class PersistenceService {
  static const String _keyStrategyState = 'strategy_state';

  /// 자동 저장 기능
  Future<void> saveState(StrategyState state) async {
    final prefs = await SharedPreferences.getInstance();
    
    final Map<String, dynamic> json = {
      'capital': state.capital,
      'symbol': state.symbol,
      'splitCount': state.splitCount,
      'targetProfit': state.targetProfit,
      'cash': state.cash,
      'qty': state.qty,
      'avg': state.avg,
      't': state.t,
      'mode': state.mode.name,
      'closeHistory': state.closeHistory,
      'startCapital': state.startCapital,
      'startDate': state.startDate.toIso8601String(),
      'currentCycle': state.currentCycle,
      'cycleStatus': state.cycleStatus.name,
      'completionReason': state.completionReason?.name,
      'hasPosition': state.hasPosition,
      'maxT': state.maxT,
      'maxQty': state.maxQty,
      'maxExposure': state.maxExposure,
    };
    
    await prefs.setString(_keyStrategyState, jsonEncode(json));
  }

  /// 자동 복구 및 앱 재실행 복구 기능
  /// 명세서 29번 조건: CycleStatus = RUNNING 상태가 존재하면 자동 복구
  Future<StrategyState?> loadState() async {
    final prefs = await SharedPreferences.getInstance();
    final String? jsonString = prefs.getString(_keyStrategyState);
    
    if (jsonString == null) return null;
    
    try {
      final Map<String, dynamic> json = jsonDecode(jsonString);
      
      if (json['cycleStatus'] != CycleStatus.running.name) {
        return null;
      }

      return StrategyState(
        capital: (json['capital'] as num).toDouble(),
        symbol: json['symbol'] as String,
        splitCount: json['splitCount'] as int,
        targetProfit: (json['targetProfit'] as num).toDouble(),
        cash: (json['cash'] as num).toDouble(),
        qty: (json['qty'] as num).toDouble(),
        avg: (json['avg'] as num).toDouble(),
        t: (json['t'] as num).toDouble(),
        mode: Mode.values.firstWhere((e) => e.name == json['mode']),
        closeHistory: List<double>.from(
          (json['closeHistory'] as List).map((e) => (e as num).toDouble())
        ),
        startCapital: (json['startCapital'] as num).toDouble(),
        startDate: DateTime.parse(json['startDate'] as String),
        currentCycle: json['currentCycle'] as int,
        cycleStatus: CycleStatus.values.firstWhere((e) => e.name == json['cycleStatus']),
        completionReason: json['completionReason'] != null 
            ? CompletionReason.values.firstWhere((e) => e.name == json['completionReason'])
            : null,
        hasPosition: json['hasPosition'] as bool,
        maxT: (json['maxT'] as num).toDouble(),
        maxQty: (json['maxQty'] as num).toDouble(),
        maxExposure: (json['maxExposure'] as num).toDouble(),
      );
    } catch (e) {
      // 데이터 손상 시 무시
      return null;
    }
  }

  /// 상태 초기화 (사이클 종료 시 호출)
  Future<void> clearState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyStrategyState);
  }
}