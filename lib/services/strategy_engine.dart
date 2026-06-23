import 'dart:math';
import '../models/strategy_state.dart';
import '../models/order.dart';
import '../models/cycle_result.dart';
import 'sma_service.dart';

class DailyCalculation {
  final List<Order> buyOrders;
  final List<Order> sellOrders;
  final StrategyState updatedState;
  final String log;

  DailyCalculation({
    required this.buyOrders,
    required this.sellOrders,
    required this.updatedState,
    required this.log,
  });
}

class StrategyEngine {
  /// 하루 계산 실행 (PrevClose, PrevHigh 입력 후 호출)
  static DailyCalculation calculate(
    StrategyState state,
    double prevClose,
    double prevHigh,
  ) {
    final s = _cloneState(state);
    final logs = <String>[];
    final newBuyOrders = <Order>[];
    final newSellOrders = <Order>[];

    // 종가 이력 추가
    s.closeHistory = SmaService.addClose(s.closeHistory, prevClose);

    if (s.mode == StrategyMode.normal) {
      _processNormalMode(s, prevClose, prevHigh, newBuyOrders, newSellOrders, logs);
    } else {
      _processReverseMode(s, prevClose, prevHigh, newBuyOrders, newSellOrders, logs);
    }

    // 사이클 종료 체크
    if (s.qty <= 3 && s.qty > 0) {
      _completeCycle(s, prevClose, logs);
    }

    // 통계 갱신
    if (s.t > s.maxT) s.maxT = s.t;
    if (s.qty > s.maxQty) s.maxQty = s.qty;
    final exposure = s.qty * s.avg;
    if (exposure > s.maxExposure) s.maxExposure = exposure;

    // 리버스 전환 체크
    if (s.mode == StrategyMode.normal && s.t > s.splitCount - 1) {
      s.mode = StrategyMode.reverse;
      logs.add('⚠️ REVERSE 모드 전환 (T=${s.t.toStringAsFixed(2)})');
    }

    return DailyCalculation(
      buyOrders: newBuyOrders,
      sellOrders: newSellOrders,
      updatedState: s,
      log: logs.join('\n'),
    );
  }

  // ───────────────────────────────────────────
  // 일반 모드
  // ───────────────────────────────────────────
  static void _processNormalMode(
    StrategyState s,
    double prevClose,
    double prevHigh,
    List<Order> buyOrders,
    List<Order> sellOrders,
    List<String> logs,
  ) {
    // === 최초 진입 (Qty == 0) ===
    if (s.qty == 0) {
      final entryPrice = prevClose * (1 + s.targetProfit / 100);
      final entryQty = (s.buyAmount / entryPrice).floor();

      if (entryQty > 0) {
        final order = Order(
          id: _genId(),
          type: OrderType.locBuy,
          price: entryPrice,
          qty: entryQty,
          label: '최초진입 LOC매수',
        );
        // LOC Buy 체결 체크: PrevClose <= OrderPrice
        if (prevClose <= entryPrice) {
          _fillBuy(s, prevClose, entryQty);
          s.t += 1;
          order.status = OrderStatus.filled;
          order.filledPrice = prevClose;
          logs.add('✅ 최초진입 체결: ${entryQty}주 @ \$${prevClose.toStringAsFixed(2)}, T=${s.t}');
        } else {
          logs.add('⏳ 최초진입 미체결 (EntryPrice=\$${entryPrice.toStringAsFixed(2)})');
        }
        buyOrders.add(order);

        // 추가 LOC 10개 (1주씩)
        for (int i = 1; i <= 10; i++) {
          final extraPrice = s.buyAmount / (entryQty + i);
          final extraOrder = Order(
            id: _genId(),
            type: OrderType.locBuy,
            price: extraPrice,
            qty: 1,
            label: '추가LOC$i',
          );
          if (prevClose <= extraPrice) {
            _fillBuy(s, prevClose, 1);
            // T 변화 없음
            extraOrder.status = OrderStatus.filled;
            extraOrder.filledPrice = prevClose;
            logs.add('  ✅ 추가LOC$i 체결: 1주 @ \$${prevClose.toStringAsFixed(2)}');
          }
          buyOrders.add(extraOrder);
        }
      }
      return;
    }

    // === 전반전 / 후반전 ===
    final isFirstHalf = s.t > 0 && s.t < s.splitCount / 2;
    final isSecondHalf = s.t >= s.splitCount / 2 && s.t <= s.splitCount - 1;

    // 순서: 1 Limit매도 → 2 쿼터LOC매도 → 3 StarBuy → 4 AvgBuy → 5 LOC10
    // --- 1. 지정가 최종익절매도 ---
    final quarterQty = (s.qty * 0.25).floor();
    final finalQty = s.qty - quarterQty;
    final finalSellPrice = s.avg * (1 + s.targetProfit / 100);

    if (finalQty > 0) {
      final limitOrder = Order(
        id: _genId(),
        type: OrderType.limitSell,
        price: finalSellPrice,
        qty: finalQty,
        label: '최종익절 Limit매도',
      );
      // Limit Sell 체결: PrevHigh >= OrderPrice
      if (prevHigh >= finalSellPrice) {
        _fillSell(s, finalSellPrice, finalQty);
        s.t = s.t * 0.25;
        limitOrder.status = OrderStatus.filled;
        limitOrder.filledPrice = finalSellPrice;
        logs.add('✅ 최종익절 체결: ${finalQty}주 @ \$${finalSellPrice.toStringAsFixed(2)}, T=${s.t.toStringAsFixed(2)}');
      }
      sellOrders.add(limitOrder);
    }

    // --- 2. 쿼터 LOC 매도 ---
    if (quarterQty > 0) {
      final sellStarPrice = s.sellStar;
      final quarterOrder = Order(
        id: _genId(),
        type: OrderType.locSell,
        price: sellStarPrice,
        qty: quarterQty,
        label: '쿼터LOC매도',
      );
      // LOC Sell 체결: PrevClose >= OrderPrice
      if (prevClose >= sellStarPrice) {
        _fillSell(s, prevClose, quarterQty);
        s.t = s.t * 0.75;
        quarterOrder.status = OrderStatus.filled;
        quarterOrder.filledPrice = prevClose;
        logs.add('✅ 쿼터매도 체결: ${quarterQty}주 @ \$${prevClose.toStringAsFixed(2)}, T=${s.t.toStringAsFixed(2)}');
      }
      sellOrders.add(quarterOrder);
    }

    // --- 3. StarBuy ---
    if (isFirstHalf || isSecondHalf) {
      final starBuyPrice = s.buyStar;
      final starBuyQty = (s.buyAmount / starBuyPrice).floor();
      if (starBuyQty > 0 && starBuyPrice > 0) {
        final starOrder = Order(
          id: _genId(),
          type: OrderType.locBuy,
          price: starBuyPrice,
          qty: starBuyQty,
          label: 'StarBuy LOC매수',
        );
        if (prevClose <= starBuyPrice) {
          _fillBuy(s, prevClose, starBuyQty);
          s.t += isFirstHalf ? 0.5 : 1.0;
          starOrder.status = OrderStatus.filled;
          starOrder.filledPrice = prevClose;
          logs.add('✅ StarBuy 체결: ${starBuyQty}주 @ \$${prevClose.toStringAsFixed(2)}, T=${s.t.toStringAsFixed(2)}');
        }
        buyOrders.add(starOrder);
      }
    }

    // --- 4. AvgBuy (전반전만) ---
    if (isFirstHalf) {
      final avgBuyQty = (s.buyAmount / s.avg).floor();
      if (avgBuyQty > 0) {
        final avgOrder = Order(
          id: _genId(),
          type: OrderType.locBuy,
          price: s.avg,
          qty: avgBuyQty,
          label: 'AvgBuy LOC매수',
        );
        if (prevClose <= s.avg) {
          _fillBuy(s, prevClose, avgBuyQty);
          s.t += 0.5;
          avgOrder.status = OrderStatus.filled;
          avgOrder.filledPrice = prevClose;
          logs.add('✅ AvgBuy 체결: ${avgBuyQty}주 @ \$${prevClose.toStringAsFixed(2)}, T=${s.t.toStringAsFixed(2)}');
        }
        buyOrders.add(avgOrder);
      }
    }

    // --- 5. 추가 LOC 10개 (1주씩) ---
    if (s.qty > 0) {
      for (int i = 1; i <= 10; i++) {
        final extraPrice = s.buyAmount / (s.qty + i);
        final extraOrder = Order(
          id: _genId(),
          type: OrderType.locBuy,
          price: extraPrice,
          qty: 1,
          label: '추가LOC$i',
        );
        if (prevClose <= extraPrice) {
          _fillBuy(s, prevClose, 1);
          extraOrder.status = OrderStatus.filled;
          extraOrder.filledPrice = prevClose;
          logs.add('  ✅ 추가LOC$i 체결: 1주 @ \$${prevClose.toStringAsFixed(2)}');
        }
        buyOrders.add(extraOrder);
      }
    }
  }

  // ───────────────────────────────────────────
  // 리버스 모드
  // ───────────────────────────────────────────
  static void _processReverseMode(
    StrategyState s,
    double prevClose,
    double prevHigh,
    List<Order> buyOrders,
    List<Order> sellOrders,
    List<String> logs,
  ) {
    final starPrice = s.sma5; // 리버스 별지점 = SMA5

    // 리버스 종료 체크
    final reverseEndThreshold = s.avg * (1 - s.targetProfit / 100);
    if (prevClose >= reverseEndThreshold && s.avg > 0) {
      s.mode = StrategyMode.normal;
      logs.add('🔄 REVERSE 종료 → NORMAL 전환');
      return;
    }

    // 리버스 첫날 여부: closeHistory 마지막 추가가 첫 번째 리버스날
    // 판단: 이전 closeHistory 길이로 추적 (간단히 isFirstReverseDay 플래그 사용)
    // 여기서는 매도 먼저 실행 (MOC or LOC)
    final sellQty = (s.qty / (s.splitCount / 2)).floor();

    // 매도 (MOC or LOC @ StarPrice)
    if (sellQty > 0) {
      final isMoc = _isFirstReverseDay(s);
      if (isMoc) {
        // MOC Sell - 항상 체결 @ PrevClose
        final mocOrder = Order(
          id: _genId(),
          type: OrderType.mocSell,
          price: prevClose,
          qty: sellQty,
          label: '리버스 MOC매도 (첫날)',
        );
        _fillSell(s, prevClose, sellQty);
        s.t = s.t * (1 - 2 / s.splitCount);
        mocOrder.status = OrderStatus.filled;
        mocOrder.filledPrice = prevClose;
        sellOrders.add(mocOrder);
        logs.add('✅ 리버스MOC매도(첫날): ${sellQty}주 @ \$${prevClose.toStringAsFixed(2)}, T=${s.t.toStringAsFixed(2)}');
      } else {
        // LOC Sell @ StarPrice
        final locSellOrder = Order(
          id: _genId(),
          type: OrderType.locSell,
          price: starPrice,
          qty: sellQty,
          label: '리버스 LOC매도',
        );
        if (prevClose >= starPrice) {
          _fillSell(s, prevClose, sellQty);
          s.t = s.t * (1 - 2 / s.splitCount);
          locSellOrder.status = OrderStatus.filled;
          locSellOrder.filledPrice = prevClose;
          logs.add('✅ 리버스LOC매도: ${sellQty}주 @ \$${prevClose.toStringAsFixed(2)}, T=${s.t.toStringAsFixed(2)}');
        }
        sellOrders.add(locSellOrder);
      }
    }

    // 매수 (리버스 둘째날 이후)
    if (!_isFirstReverseDay(s)) {
      final quarterBuyAmount = s.cash / 4;
      final starQty = starPrice > 0 ? (quarterBuyAmount / starPrice).floor() : 0;

      if (starQty > 0) {
        final locBuyOrder = Order(
          id: _genId(),
          type: OrderType.locBuy,
          price: starPrice,
          qty: starQty,
          label: '리버스 LOC매수',
        );
        if (prevClose <= starPrice) {
          _fillBuy(s, prevClose, starQty);
          s.t = s.t + (s.splitCount - s.t) * 0.25;
          locBuyOrder.status = OrderStatus.filled;
          locBuyOrder.filledPrice = prevClose;
          logs.add('✅ 리버스LOC매수: ${starQty}주 @ \$${prevClose.toStringAsFixed(2)}, T=${s.t.toStringAsFixed(2)}');
        }
        buyOrders.add(locBuyOrder);
      }

      // 추가 LOC 10개 (1주씩)
      for (int i = 1; i <= 10; i++) {
        final extraPrice = starPrice * (1 - i * 0.005);
        final extraOrder = Order(
          id: _genId(),
          type: OrderType.locBuy,
          price: extraPrice,
          qty: 1,
          label: '리버스추가LOC$i',
        );
        if (prevClose <= extraPrice && extraPrice > 0) {
          _fillBuy(s, prevClose, 1);
          extraOrder.status = OrderStatus.filled;
          extraOrder.filledPrice = prevClose;
          logs.add('  ✅ 리버스추가LOC$i 체결: 1주');
        }
        buyOrders.add(extraOrder);
      }
    }
  }

  static bool _isFirstReverseDay(StrategyState s) {
    // 리버스 모드 진입 후 closeHistory 추가 전 판별
    // 간단히 t 값이 splitCount-1 초과인 상태에서 처음 호출되는 날
    // 실제로는 별도 플래그 필요하지만 여기서는 t > splitCount * 0.9 로 근사
    return s.t > s.splitCount * 0.95;
  }

  // ───────────────────────────────────────────
  // 사이클 완료
  // ───────────────────────────────────────────
  static void _completeCycle(StrategyState s, double prevClose, List<String> logs) {
    // 전량 청산
    if (s.qty > 0) {
      s.cash += s.qty * prevClose;
      logs.add('🏁 사이클 완료: ${s.qty}주 청산 @ \$${prevClose.toStringAsFixed(2)}');
    }

    final endCash = s.cash;
    final profit = endCash - s.startCapital;
    final profitRate = (endCash / s.startCapital - 1) * 100;

    final result = CycleResult(
      cycleNumber: s.currentCycle,
      startDate: s.startDate,
      endDate: DateTime.now(),
      startCapital: s.startCapital,
      endCash: endCash,
      totalProfit: profit,
      profitRate: profitRate,
      maxT: s.maxT,
      maxQty: s.maxQty,
      maxExposure: s.maxExposure,
    );
    s.cycleResults.add(result);

    // 리셋
    s.qty = 0;
    s.avg = 0;
    s.t = 0;
    s.mode = StrategyMode.normal;
    s.maxT = 0;
    s.maxQty = 0;
    s.maxExposure = 0;
    s.startDate = DateTime.now();
    s.startCapital = s.cash;
    s.currentCycle++;

    logs.add('💰 사이클${result.cycleNumber} 완료: 수익 \$${profit.toStringAsFixed(2)} (${profitRate.toStringAsFixed(2)}%)');
  }

  // ───────────────────────────────────────────
  // 내부 헬퍼
  // ───────────────────────────────────────────
  static void _fillBuy(StrategyState s, double price, int qty) {
    final cost = price * qty;
    if (cost > s.cash) return; // 잔금 부족 시 스킵
    final prevTotal = s.avg * s.qty;
    s.cash -= cost;
    s.qty += qty;
    s.avg = s.qty > 0 ? (prevTotal + cost) / s.qty : 0;
  }

  static void _fillSell(StrategyState s, double price, int qty) {
    final actualQty = qty > s.qty ? s.qty : qty;
    s.cash += price * actualQty;
    s.qty -= actualQty;
    if (s.qty == 0) s.avg = 0;
  }

  static StrategyState _cloneState(StrategyState s) {
    return StrategyState.fromJson(s.toJson());
  }

  static String _genId() =>
      DateTime.now().microsecondsSinceEpoch.toString() +
      (1000 + (DateTime.now().millisecond % 1000)).toString();
}
