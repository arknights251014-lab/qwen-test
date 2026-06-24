// order.dart
enum OrderType {
  locBuy,
  locSell,
  mocSell,
  limitSell,
}

class Order {
  final OrderType type;
  final double orderPrice;
  final double qty;

  const Order({
    required this.type,
    required this.orderPrice,
    required this.qty,
  });
}