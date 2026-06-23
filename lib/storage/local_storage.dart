import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/strategy_state.dart';

class LocalStorage {
  static const _keyState = 'strategy_state';
  static const _keyHasState = 'has_state';

  static Future<void> saveState(StrategyState state) async {
    final prefs = await SharedPreferences.getInstance();
    final json = jsonEncode(state.toJson());
    await prefs.setString(_keyState, json);
    await prefs.setBool(_keyHasState, true);
  }

  static Future<StrategyState?> loadState() async {
    final prefs = await SharedPreferences.getInstance();
    final hasState = prefs.getBool(_keyHasState) ?? false;
    if (!hasState) return null;
    final json = prefs.getString(_keyState);
    if (json == null) return null;
    try {
      final map = jsonDecode(json) as Map<String, dynamic>;
      return StrategyState.fromJson(map);
    } catch (_) {
      return null;
    }
  }

  static Future<void> clearState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyState);
    await prefs.setBool(_keyHasState, false);
  }

  static Future<bool> hasActiveState() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyHasState) ?? false;
  }
}
