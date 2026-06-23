enum OrderType { locBuy, locSell, limitSell, mocSell }
enum OrderStatus { pending, filled, cancelled }

class Order {
  final String id;
  final OrderType type;
  final double price;
  final int qty;
  OrderStatus status;
  double? filledPrice;
  final DateTime createdAt;
  final String label;

  Order({
    required this.id,
    required this.type,
    required this.price,
    required this.qty,
    this.status = OrderStatus.pending,
    this.filledPrice,
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

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.index,
        'price': price,
        'qty': qty,
        'status': status.index,
        'filledPrice': filledPrice,
        'createdAt': createdAt.toIso8601String(),
        'label': label,
      };

  factory Order.fromJson(Map<String, dynamic> json) => Order(
        id: json['id'],
        type: OrderType.values[json['type']],
        price: (json['price'] as num).toDouble(),
        qty: json['qty'],
        status: OrderStatus.values[json['status']],
        filledPrice: json['filledPrice'] != null
            ? (json['filledPrice'] as num).toDouble()
            : null,
        createdAt: DateTime.parse(json['createdAt']),
        label: json['label'] ?? '',
      );
}
