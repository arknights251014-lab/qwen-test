abstract class BrokerInterface {
  Future<double> getCash();
  Future<int> getQty();
  Future<void> buy({
    required double price,
    required int qty,
    required String orderType,
  });
  Future<void> sell({
    required double price,
    required int qty,
    required String orderType,
  });
  Future<double> getCurrentPrice(String symbol);
  String get brokerName;
}
