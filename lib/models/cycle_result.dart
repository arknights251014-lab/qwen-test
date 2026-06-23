class CycleResult {
  final int cycleNumber;
  final DateTime startDate;
  final DateTime endDate;
  final double startCapital;
  final double endCash;
  final double totalProfit;
  final double profitRate;
  final double maxT;
  final int maxQty;
  final double maxExposure;

  CycleResult({
    required this.cycleNumber,
    required this.startDate,
    required this.endDate,
    required this.startCapital,
    required this.endCash,
    required this.totalProfit,
    required this.profitRate,
    required this.maxT,
    required this.maxQty,
    required this.maxExposure,
  });

  int get investmentDays => endDate.difference(startDate).inDays;

  Map<String, dynamic> toJson() => {
        'cycleNumber': cycleNumber,
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
        'startCapital': startCapital,
        'endCash': endCash,
        'totalProfit': totalProfit,
        'profitRate': profitRate,
        'maxT': maxT,
        'maxQty': maxQty,
        'maxExposure': maxExposure,
      };

  factory CycleResult.fromJson(Map<String, dynamic> json) => CycleResult(
        cycleNumber: json['cycleNumber'],
        startDate: DateTime.parse(json['startDate']),
        endDate: DateTime.parse(json['endDate']),
        startCapital: (json['startCapital'] as num).toDouble(),
        endCash: (json['endCash'] as num).toDouble(),
        totalProfit: (json['totalProfit'] as num).toDouble(),
        profitRate: (json['profitRate'] as num).toDouble(),
        maxT: (json['maxT'] as num).toDouble(),
        maxQty: json['maxQty'],
        maxExposure: (json['maxExposure'] as num).toDouble(),
      );
}
