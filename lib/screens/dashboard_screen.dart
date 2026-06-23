import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/strategy_provider.dart';
import '../models/strategy_state.dart';
import '../widgets/info_card.dart';
import '../widgets/order_card.dart';
import 'result_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _prevCloseCtrl = TextEditingController();
  final _prevHighCtrl = TextEditingController();
  bool _isCalculating = false;
  bool _showLog = false;

  final _fmt = NumberFormat('#,##0.00');
  final _fmtInt = NumberFormat('#,##0');

  @override
  void dispose() {
    _prevCloseCtrl.dispose();
    _prevHighCtrl.dispose();
    super.dispose();
  }

  Future<void> _calculate() async {
    final close = double.tryParse(_prevCloseCtrl.text);
    final high = double.tryParse(_prevHighCtrl.text);
    if (close == null || close <= 0) {
      _showSnack('전일 종가를 올바르게 입력하세요');
      return;
    }
    if (high == null || high <= 0) {
      _showSnack('전일 고가를 올바르게 입력하세요');
      return;
    }
    if (high < close) {
      _showSnack('전일 고가는 종가 이상이어야 합니다');
      return;
    }

    setState(() => _isCalculating = true);
    await context.read<StrategyProvider>().calculate(close, high);
    if (!mounted) return;
    setState(() => _isCalculating = false);

    final provider = context.read<StrategyProvider>();
    if (provider.cycleJustCompleted) {
      provider.clearCycleFlag();
      _showCycleCompleteDialog();
    }
  }

  void _showCycleCompleteDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.celebration_rounded, color: Colors.amber),
            SizedBox(width: 8),
            Text('사이클 완료!'),
          ],
        ),
        content: const Text('한 사이클이 완료되었습니다.\n결과 화면에서 확인하거나 계속 진행하세요.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('계속'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ResultScreen()),
              );
            },
            child: const Text('결과 보기'),
          ),
        ],
      ),
    );
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final size = MediaQuery.of(context).size;
    final isWide = size.width > 600;

    return Consumer<StrategyProvider>(
      builder: (context, provider, _) {
        final state = provider.state;
        if (state == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final modeLabel =
            state.mode == StrategyMode.normal ? 'NORMAL' : 'REVERSE';
        final modeColor =
            state.mode == StrategyMode.normal ? Colors.blue : Colors.orange;

        return Scaffold(
          appBar: AppBar(
            title: const Text('무한매수법 4.0'),
            centerTitle: false,
            actions: [
              // 모드 배지
              Container(
                margin: const EdgeInsets.only(right: 4),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: modeColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  modeLabel,
                  style: TextStyle(
                    color: modeColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.bar_chart_rounded),
                tooltip: '결과',
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ResultScreen()),
                ),
              ),
              const SizedBox(width: 4),
            ],
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: isWide ? size.width * 0.1 : 16,
                vertical: 12,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 입력 섹션
                  _buildInputSection(context, colorScheme),
                  const SizedBox(height: 16),
                  // 상태 요약
                  _buildStatusGrid(context, state, colorScheme),
                  const SizedBox(height: 4),
                  // 계산값
                  _buildCalcGrid(context, state, colorScheme),
                  // 주문 목록
                  if (provider.lastBuyOrders.isNotEmpty ||
                      provider.lastSellOrders.isNotEmpty) ...[
                    _buildOrderSection(context, provider),
                  ],
                  // 로그
                  if (provider.lastLog.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _buildLogSection(context, provider, colorScheme),
                  ],
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildInputSection(BuildContext context, ColorScheme colorScheme) {
    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '오늘의 데이터 입력',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildPriceField(
                    context,
                    controller: _prevCloseCtrl,
                    label: '전일 종가 (PrevClose)',
                    icon: Icons.close_rounded,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildPriceField(
                    context,
                    controller: _prevHighCtrl,
                    label: '전일 고가 (PrevHigh)',
                    icon: Icons.keyboard_arrow_up_rounded,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _isCalculating ? null : _calculate,
              icon: _isCalculating
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: colorScheme.onPrimary,
                      ),
                    )
                  : const Icon(Icons.calculate_rounded),
              label: Text(_isCalculating ? '계산 중...' : '오늘 계산'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(46),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceField(
    BuildContext context, {
    required TextEditingController controller,
    required String label,
    required IconData icon,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType:
          const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
      ],
      decoration: InputDecoration(
        labelText: label,
        prefixText: '\$ ',
        prefixIcon: Icon(icon, size: 18),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        isDense: true,
      ),
    );
  }

  Widget _buildStatusGrid(
    BuildContext context,
    StrategyState state,
    ColorScheme colorScheme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: '현재 상태'),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 1.5,
          children: [
            InfoCard(
              title: 'Cash',
              value: '\$${_fmt.format(state.cash)}',
              icon: Icons.account_balance_wallet_rounded,
              compact: true,
              valueColor: Colors.green,
            ),
            InfoCard(
              title: 'Qty',
              value: '${_fmtInt.format(state.qty)}주',
              icon: Icons.layers_rounded,
              compact: true,
            ),
            InfoCard(
              title: 'Avg',
              value: '\$${_fmt.format(state.avg)}',
              icon: Icons.horizontal_rule_rounded,
              compact: true,
            ),
            InfoCard(
              title: 'T',
              value: state.t.toStringAsFixed(2),
              icon: Icons.repeat_rounded,
              compact: true,
              valueColor: state.t >= state.splitCount * 0.8
                  ? Colors.orange
                  : null,
            ),
            InfoCard(
              title: 'Mode',
              value: state.mode == StrategyMode.normal ? 'NORMAL' : 'REVERSE',
              icon: Icons.swap_horiz_rounded,
              compact: true,
              valueColor: state.mode == StrategyMode.normal
                  ? Colors.blue
                  : Colors.orange,
            ),
            InfoCard(
              title: 'SMA5',
              value: '\$${_fmt.format(state.sma5)}',
              icon: Icons.show_chart_rounded,
              compact: true,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCalcGrid(
    BuildContext context,
    StrategyState state,
    ColorScheme colorScheme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: '계산값'),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 2.2,
          children: [
            InfoCard(
              title: 'BuyAmount',
              value: '\$${_fmt.format(state.buyAmount)}',
              icon: Icons.shopping_cart_rounded,
              compact: true,
            ),
            InfoCard(
              title: 'StarPct',
              value: '${state.starPct.toStringAsFixed(2)}%',
              icon: Icons.star_rounded,
              compact: true,
              valueColor: Colors.amber,
            ),
            InfoCard(
              title: 'StarPrice',
              value: '\$${_fmt.format(state.starPrice)}',
              icon: Icons.star_border_rounded,
              compact: true,
            ),
            InfoCard(
              title: 'BuyStar',
              value: '\$${_fmt.format(state.buyStar)}',
              icon: Icons.arrow_downward_rounded,
              compact: true,
              valueColor: Colors.blue,
            ),
            InfoCard(
              title: 'SellStar',
              value: '\$${_fmt.format(state.sellStar)}',
              icon: Icons.arrow_upward_rounded,
              compact: true,
              valueColor: Colors.green,
            ),
            InfoCard(
              title: 'FinalSellPrice',
              value: '\$${_fmt.format(state.finalSellPrice)}',
              icon: Icons.sell_rounded,
              compact: true,
              valueColor: Colors.teal,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildOrderSection(
    BuildContext context,
    StrategyProvider provider,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (provider.lastSellOrders.isNotEmpty) ...[
          const SectionHeader(title: '매도 주문'),
          ...provider.lastSellOrders
              .map((o) => OrderCard(order: o, isBuy: false)),
        ],
        if (provider.lastBuyOrders.isNotEmpty) ...[
          const SectionHeader(title: '매수 주문'),
          ...provider.lastBuyOrders
              .map((o) => OrderCard(order: o, isBuy: true)),
        ],
      ],
    );
  }

  Widget _buildLogSection(
    BuildContext context,
    StrategyProvider provider,
    ColorScheme colorScheme,
  ) {
    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerHighest,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _showLog = !_showLog),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  Icon(Icons.receipt_long_rounded,
                      size: 16, color: colorScheme.onSurfaceVariant),
                  const SizedBox(width: 8),
                  Text(
                    '실행 로그',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const Spacer(),
                  Icon(
                    _showLog
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    size: 18,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
          if (_showLog)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  provider.lastLog,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 11,
                    height: 1.6,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
