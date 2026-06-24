enum OrderType {
  locBuy,
  locSell,
  limitSell,
  mocSell,
}

enum OrderStatus {
  pending,
  filled,
  cancelled,
}

class Order {
  final String id;

  final OrderType type;

  final double price;

  final int qty;

  OrderStatus status;

  double? filledPrice;

  int? filledQty;

  final DateTime createdAt;

  final String label;

  Order({
    required this.id,
    required this.type,
    required this.price,
    required this.qty,
    this.status = OrderStatus.pending,
    this.filledPrice,
    this.filledQty,
    required this.label,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  String get typeLabel {
    switch (type) {
      case OrderType.locBuy:
        return 'LOC 매수';

      case OrderType.locSell:
        return 'LOC 매도';

      case OrderType.limitSell:
        return 'Limit 매도';

      case OrderType.mocSell:
        return 'MOC 매도';
    }
  }

  bool get isFilled =>
      status == OrderStatus.filled;

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.index,
        'price': price,
        'qty': qty,
        'status': status.index,
        'filledPrice': filledPrice,
        'filledQty': filledQty,
        'createdAt': createdAt.toIso8601String(),
        'label': label,
      };

  factory Order.fromJson(
    Map<String, dynamic> json,
  ) =>
      Order(
        id: json['id'],

        type: OrderType.values[
            json['type'] ?? 0],

        price:
            (json['price'] as num)
                .toDouble(),

        qty: json['qty'] ?? 0,

        status: OrderStatus.values[
            json['status'] ?? 0],

        filledPrice:
            json['filledPrice'] != null
                ? (json['filledPrice']
                        as num)
                    .toDouble()
                : null,

        filledQty:
            json['filledQty'],

        createdAt:
            DateTime.parse(
                json['createdAt']),

        label: json['label'] ?? '',
      );
}