import 'broker_interface.dart';

/// 수동 브로커: 사용자가 직접 주문을 입력하는 방식
/// 추후 TossBroker 등으로 교체 가능
class ManualBroker implements BrokerInterface {
  double _cash;
  int _qty;

  ManualBroker({double cash = 0, int qty = 0})
      : _cash = cash,
        _qty = qty;

  @override
  String get brokerName => 'Manual';

  @override
  Future<double> getCash() async => _cash;

  @override
  Future<int> getQty() async => _qty;

  @override
  Future<void> buy({
    required double price,
    required int qty,
    required String orderType,
  }) async {
    // 수동모드: 상태는 StrategyEngine에서 관리
  }

  @override
  Future<void> sell({
    required double price,
    required int qty,
    required String orderType,
  }) async {
    // 수동모드: 상태는 StrategyEngine에서 관리
  }

  @override
  Future<double> getCurrentPrice(String symbol) async {
    // 수동모드: 사용자가 직접 입력
    return 0.0;
  }

  void updateState(double cash, int qty) {
    _cash = cash;
    _qty = qty;
  }
}
