class CycleResult {
  final int cycleNumber;

  final String symbol;

  final int splitCount;
  final double targetProfit;

  final DateTime startDate;
  final DateTime endDate;

  final double startCapital;
  final double endCash;

  final double totalProfit;
  final double profitRate;

  final double maxT;
  final int maxQty;
  final double maxExposure;

  final String completionReason;

  CycleResult({
    required this.cycleNumber,

    required this.symbol,

    required this.splitCount,
    required this.targetProfit,

    required this.startDate,
    required this.endDate,

    required this.startCapital,
    required this.endCash,

    required this.totalProfit,
    required this.profitRate,

    required this.maxT,
    required this.maxQty,
    required this.maxExposure,

    required this.completionReason,
  });

  int get investmentDays =>
      endDate.difference(startDate).inDays;

  Map<String, dynamic> toJson() => {
        'cycleNumber': cycleNumber,

        'symbol': symbol,

        'splitCount': splitCount,
        'targetProfit': targetProfit,

        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),

        'startCapital': startCapital,
        'endCash': endCash,

        'totalProfit': totalProfit,
        'profitRate': profitRate,

        'maxT': maxT,
        'maxQty': maxQty,
        'maxExposure': maxExposure,

        'completionReason': completionReason,
      };

  factory CycleResult.fromJson(
    Map<String, dynamic> json,
  ) =>
      CycleResult(
        cycleNumber: json['cycleNumber'],

        symbol: json['symbol'] ?? 'SOXL',

        splitCount: json['splitCount'] ?? 20,

        targetProfit:
            (json['targetProfit'] ?? 20)
                .toDouble(),

        startDate:
            DateTime.parse(json['startDate']),

        endDate:
            DateTime.parse(json['endDate']),

        startCapital:
            (json['startCapital'] as num)
                .toDouble(),

        endCash:
            (json['endCash'] as num)
                .toDouble(),

        totalProfit:
            (json['totalProfit'] as num)
                .toDouble(),

        profitRate:
            (json['profitRate'] as num)
                .toDouble(),

        maxT:
            (json['maxT'] as num)
                .toDouble(),

        maxQty: json['maxQty'],

        maxExposure:
            (json['maxExposure'] as num)
                .toDouble(),

        completionReason:
            json['completionReason'] ??
                'normalExit',
      );
}