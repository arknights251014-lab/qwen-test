import 'dart:math';
import '../models/order.dart';
import '../models/cycle_result.dart';
import '../models/strategy_state.dart';

class DayResult {
  final StrategyState state;
  final CycleResult? cycleResult;
  final List<Order> todaysOrders;

  const DayResult({
    required this.state,
    this.cycleResult,
    required this.todaysOrders,
  });
}

class _InternalOrder {
  final OrderType type;
  final double price;
  final double qty;
  final String category;
  final double? tDelta;
  final double? tFactor;

  _InternalOrder({
    required this.type,
    required this.price,
    required this.qty,
    required this.category,
    this.tDelta,
    this.tFactor,
  });
}

class StrategyEngine {
  DayResult processDay(StrategyState state, double prevClose, double prevHigh) {
    // 1. Update History
    List<double> newHistory = List.from(state.closeHistory);
    newHistory.add(prevClose);
    if (newHistory.length > 5) {
      newHistory.removeAt(0);
    }

    // Calculate SMA5
    double sma5 = 0;
    if (newHistory.isNotEmpty) {
      // Spec: sum(CloseHistory) / 5
      sma5 = newHistory.reduce((a, b) => a + b) / 5;
    }

    // 2. Mode Transition
    Mode currentMode = state.mode;
    
    // Check Reverse Entry
    if (currentMode == Mode.normal && state.t > state.splitCount - 1) {
      currentMode = Mode.reverse;
    }
    
    // Check Reverse Exit
    if (currentMode == Mode.reverse && state.hasPosition) {
      double exitThreshold = state.avg * (1 - state.targetProfit / 100);
      if (prevClose >= exitThreshold) {
        currentMode = Mode.normal;
      }
    }

    // 3. Generate Orders
    List<_InternalOrder> internalOrders = [];
    
    void addOrder(OrderType type, double price, double qty, String category, {double? tDelta, double? tFactor}) {
      if (qty > 0) {
        internalOrders.add(_InternalOrder(
          type: type,
          price: price,
          qty: qty,
          category: category,
          tDelta: tDelta,
          tFactor: tFactor,
        ));
      }
    }

    double cash = state.cash;
    double qty = state.qty;
    double avg = state.avg;
    double t = state.t;
    int n = state.splitCount;
    double tp = state.targetProfit;

    // Initial Entry
    if (!state.hasPosition) {
      double entryPrice = prevClose * (1 + tp / 100);
      double buyAmount = cash / n;
      double entryQty = (buyAmount / entryPrice).floorToDouble();
      
      if (entryQty > 0) {
        addOrder(OrderType.locBuy, entryPrice, entryQty, 'entry', tDelta: 1.0);
        
        for (int i = 1; i <= 10; i++) {
          double extraPrice = buyAmount / (entryQty + i);
          addOrder(OrderType.locBuy, extraPrice, 1.0, 'extra');
        }
      }
    } 
    // Normal Mode
    else if (currentMode == Mode.normal) {
      double buyAmount = cash / (n - t);
      double starPct = tp - (tp / n * 2 * t);
      double starPrice = avg * (1 + starPct / 100);
      double buyStar = starPrice - 0.01;
      double sellStar = starPrice;
      double finalSellPrice = avg * (1 + tp / 100);
      
      double quarterQty = (qty * 0.25).floorToDouble();
      double finalQty = qty - quarterQty;

      if (finalQty > 0) {
        addOrder(OrderType.limitSell, finalSellPrice, finalQty, 'limitSell', tFactor: 0.25);
      }
      if (quarterQty > 0) {
        addOrder(OrderType.locSell, sellStar, quarterQty, 'quarterSell', tFactor: 0.75);
      }

      bool is1stHalf = t < (n / 2);
      
      if (is1stHalf) {
        double starBudget = buyAmount / 2;
        double avgBudget = buyAmount / 2;
        
        double starQty = (starBudget / buyStar).floorToDouble();
        double avgQty = (avgBudget / avg).roundToDouble();
        
        if (starQty > 0) addOrder(OrderType.locBuy, buyStar, starQty, 'starBuy', tDelta: 0.5);
        if (avgQty > 0) addOrder(OrderType.locBuy, avg, avgQty, 'avgBuy', tDelta: 0.5);
        
        double baseQty = starQty + avgQty;
        for (int i = 1; i <= 10; i++) {
          double extraPrice = buyAmount / (baseQty + i);
          addOrder(OrderType.locBuy, extraPrice, 1.0, 'extra');
        }
      } else {
        double starQty = (buyAmount / buyStar).floorToDouble();
        if (starQty > 0) addOrder(OrderType.locBuy, buyStar, starQty, 'starBuy', tDelta: 1.0);
        
        for (int i = 1; i <= 10; i++) {
          double extraPrice = buyAmount / (starQty + i);
          addOrder(OrderType.locBuy, extraPrice, 1.0, 'extra');
        }
      }
    } 
    // Reverse Mode
    else if (currentMode == Mode.reverse) {
      double starPrice = sma5;
      double sellQty = (qty / (n / 2)).floorToDouble();
      
      bool isDay1 =
    state.mode != Mode.reverse &&
    currentMode == Mode.reverse;

      if (isDay1) {
        if (sellQty > 0) addOrder(OrderType.mocSell, prevClose, sellQty, 'reverseSell', tFactor: (1 - 2/n));
      } else {
        if (sellQty > 0) addOrder(OrderType.locSell, starPrice, sellQty, 'reverseSell', tFactor: (1 - 2/n));
        
        double quarterBuyAmount = cash / 4;
        double starQty = (quarterBuyAmount / starPrice).floorToDouble();
        if (starQty > 0) {
           addOrder(OrderType.locBuy, starPrice, starQty, 'reverseBuy', tDelta: (n - t) * 0.25);
           
           for (int i = 1; i <= 10; i++) {
             double extraPrice = quarterBuyAmount / (starQty + i);
             addOrder(OrderType.locBuy, extraPrice, 1.0, 'extra');
           }
        }
      }
    }

    // 4. Execute Orders
    internalOrders.sort((a, b) {
      int pA = _getPriority(a.category, currentMode);
      int pB = _getPriority(b.category, currentMode);
      return pA.compareTo(pB);
    });

    double newCash = cash;
    double newQty = qty;
    double newAvg = avg;
    double newT = t;
    List<Order> executedOrders = [];

    for (var order in internalOrders) {
      bool filled = false;
      double fillPrice = 0;

      if (order.type == OrderType.locBuy) {
        if (prevClose <= order.price) {
          filled = true;
          fillPrice = prevClose;
        }
      } else if (order.type == OrderType.locSell) {
        if (prevClose >= order.price) {
          filled = true;
          fillPrice = prevClose;
        }
      } else if (order.type == OrderType.mocSell) {
        filled = true;
        fillPrice = prevClose;
      } else if (order.type == OrderType.limitSell) {
        if (prevHigh >= order.price) {
          filled = true;
          fillPrice = order.price;
        }
      }

      if (filled) {
        bool isBuy = (order.type == OrderType.locBuy);
        bool isSell = (order.type == OrderType.locSell || order.type == OrderType.mocSell || order.type == OrderType.limitSell);

        if (isBuy) {
          double cost = order.qty * fillPrice;
          if (newCash >= cost) {
            newCash -= cost;
            double totalQty = newQty + order.qty;
            if (totalQty > 0) {
              newAvg = ((newAvg * newQty) + (fillPrice * order.qty)) / totalQty;
            }
            newQty = totalQty;
            if (order.tDelta != null) newT += order.tDelta!;
            
            executedOrders.add(Order(type: order.type, orderPrice: order.price, qty: order.qty));
          }
        } else if (isSell) {
          if (newQty >= order.qty) {
            newCash += order.qty * fillPrice;
            newQty -= order.qty;
            if (order.tFactor != null) newT *= order.tFactor!;
            
            executedOrders.add(Order(type: order.type, orderPrice: order.price, qty: order.qty));
          }
        }
      } else {
        // Record unfilled orders for dashboard display? 
        // Spec says "Today's Orders" in Dashboard. Usually means generated orders.
        // I will include all generated orders in the result, but mark them?
        // The Step 1 Order class doesn't have 'filled' status.
        // I'll just return the list of ALL generated orders as 'todaysOrders'.
      }
    }
    
    // Map all internal orders to public Order objects for the UI
    List<Order> todaysOrders = internalOrders.map((o) => Order(
      type: o.type,
      orderPrice: o.price,
      qty: o.qty,
    )).toList();

    // 5. Stats
    double maxT = max(state.maxT, newT);
    double maxQty = max(state.maxQty, newQty);
    double exposure = newQty * prevClose;
    double maxExposure = max(state.maxExposure, exposure);

    // 6. Cycle Check
    bool hasPosition = newQty > 0;
    CycleStatus status = state.cycleStatus;
    CompletionReason? reason = state.completionReason;
    CycleResult? result;

    if (state.hasPosition && !hasPosition) {
      status = CycleStatus.completed;
      reason = CompletionReason.normalExit;
      
      double endAsset = newCash;
      double totalProfit = endAsset - state.startCapital;
      double returnRate = (totalProfit / state.startCapital) * 100;
      int days = DateTime.now().difference(state.startDate).inDays;

      result = CycleResult(
        symbol: state.symbol,
        splitCount: state.splitCount,
        targetProfit: state.targetProfit,
        startCapital: state.startCapital,
        endAsset: endAsset,
        totalProfit: totalProfit,
        returnRate: returnRate,
        investmentPeriod: days,
        maxT: maxT,
        maxQty: maxQty,
        maxExposure: maxExposure,
        completionReason: reason,
      );
    }

    // 7. Return
    StrategyState newState = state.copyWith(
      cash: newCash,
      qty: newQty,
      avg: newAvg,
      t: newT,
      mode: currentMode,
      closeHistory: newHistory,
      hasPosition: hasPosition,
      maxT: maxT,
      maxQty: maxQty,
      maxExposure: maxExposure,
      cycleStatus: status,
      completionReason: reason,
    );

    return DayResult(
      state: newState,
      cycleResult: result,
      todaysOrders: todaysOrders,
    );
  }

  DayResult forceClose(StrategyState state, double forceExitPrice) {
    double sellValue = state.qty * forceExitPrice;
    double newCash = state.cash + sellValue;
    
    double endAsset = newCash;
    double totalProfit = endAsset - state.startCapital;
    double returnRate = (totalProfit / state.startCapital) * 100;
    int days = DateTime.now().difference(state.startDate).inDays;

    CycleResult result = CycleResult(
      symbol: state.symbol,
      splitCount: state.splitCount,
      targetProfit: state.targetProfit,
      startCapital: state.startCapital,
      endAsset: endAsset,
      totalProfit: totalProfit,
      returnRate: returnRate,
      investmentPeriod: days,
      maxT: state.maxT,
      maxQty: state.maxQty,
      maxExposure: state.maxExposure,
      completionReason: CompletionReason.forcedExit,
    );

    StrategyState newState = state.copyWith(
      cash: newCash,
      qty: 0,
      avg: 0,
      t: 0,
      mode: Mode.normal,
      hasPosition: false,
      cycleStatus: CycleStatus.completed,
      completionReason: CompletionReason.forcedExit,
    );

    Order forceOrder = Order(
      type: OrderType.limitSell,
      orderPrice: forceExitPrice,
      qty: state.qty,
    );

    return DayResult(
      state: newState,
      cycleResult: result,
      todaysOrders: [forceOrder],
    );
  }

  int _getPriority(String category, Mode mode) {
    if (mode == Mode.normal) {
      switch (category) {
        case 'limitSell': return 1;
        case 'quarterSell': return 2;
        case 'starBuy': return 3;
        case 'avgBuy': return 4;
        case 'entry': return 3;
        case 'extra': return 5;
        default: return 99;
      }
    } else {
      switch (category) {
        case 'reverseSell': return 1;
        case 'reverseBuy': return 2;
        case 'extra': return 3;
        default: return 99;
      }
    }
  }
}