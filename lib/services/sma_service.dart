class SmaService {
  static double calculateSma(List<double> history, {int period = 5}) {
    if (history.isEmpty) return 0;
    final count = history.length < period ? history.length : period;
    final recent = history.sublist(history.length - count);
    return recent.reduce((a, b) => a + b) / recent.length;
  }

  static List<double> addClose(List<double> history, double close) {
    final updated = List<double>.from(history)..add(close);
    // 최대 100개 유지
    if (updated.length > 100) {
      return updated.sublist(updated.length - 100);
    }
    return updated;
  }
}
