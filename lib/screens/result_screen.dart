import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/strategy_provider.dart';
import '../models/cycle_result.dart';
import '../widgets/info_card.dart';
import 'start_screen.dart';

class ResultScreen extends StatelessWidget {
  const ResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final fmt = NumberFormat('#,##0.00');
    final fmtInt = NumberFormat('#,##0');
    final size = MediaQuery.of(context).size;
    final isWide = size.width > 600;

    return Consumer<StrategyProvider>(
      builder: (context, provider, _) {
        final state = provider.state;
        if (state == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('결과')),
            body: const Center(child: Text('진행 중인 전략이 없습니다.')),
          );
        }

        final now = DateTime.now();
        final days = now.difference(state.startDate).inDays;
        final totalProfit = state.cash - state.startCapital;
        final profitRate = (state.cash / state.startCapital - 1) * 100;
        final isProfitable = totalProfit >= 0;

        return Scaffold(
          appBar: AppBar(
            title: const Text('전략 결과'),
            actions: [
              TextButton.icon(
                onPressed: () => _confirmReset(context, provider),
                icon: const Icon(Icons.restart_alt_rounded, size: 18),
                label: const Text('새로 시작'),
                style: TextButton.styleFrom(
                  foregroundColor: colorScheme.error,
                ),
              ),
            ],
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: isWide ? size.width * 0.1 : 16,
                vertical: 16,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 현재 진행 결과
                  Card(
                    elevation: 0,
                    color: isProfitable
                        ? Colors.green.withOpacity(0.08)
                        : Colors.red.withOpacity(0.08),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: isProfitable
                            ? Colors.green.withOpacity(0.3)
                            : Colors.red.withOpacity(0.3),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                isProfitable
                                    ? Icons.trending_up_rounded
                                    : Icons.trending_down_rounded,
                                color:
                                    isProfitable ? Colors.green : Colors.red,
                                size: 24,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '현재 사이클 (Cycle ${state.currentCycle})',
                                style:
                                    theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          // 수익금
                          Text(
                            '${isProfitable ? '+' : ''}\$${fmt.format(totalProfit)}',
                            style:
                                theme.textTheme.displaySmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color:
                                  isProfitable ? Colors.green : Colors.red,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 4),
                            decoration: BoxDecoration(
                              color: (isProfitable
                                      ? Colors.green
                                      : Colors.red)
                                  .withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${isProfitable ? '+' : ''}${profitRate.toStringAsFixed(2)}%',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: isProfitable
                                    ? Colors.green
                                    : Colors.red,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // 상세 통계
                  const SectionHeader(title: '상세 통계'),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: 2.2,
                    children: [
                      InfoCard(
                        title: '초기 자본',
                        value: '\$${fmt.format(state.startCapital)}',
                        icon: Icons.savings_rounded,
                        compact: true,
                      ),
                      InfoCard(
                        title: '현재 잔고',
                        value: '\$${fmt.format(state.cash)}',
                        icon: Icons.account_balance_wallet_rounded,
                        compact: true,
                        valueColor: Colors.green,
                      ),
                      InfoCard(
                        title: '투자 기간',
                        value: '$days일',
                        subtitle:
                            DateFormat('yyyy.MM.dd').format(state.startDate),
                        icon: Icons.calendar_today_rounded,
                        compact: true,
                      ),
                      InfoCard(
                        title: '최대 T',
                        value: state.maxT.toStringAsFixed(2),
                        icon: Icons.repeat_rounded,
                        compact: true,
                      ),
                      InfoCard(
                        title: '최대 보유수량',
                        value: '${fmtInt.format(state.maxQty)}주',
                        icon: Icons.layers_rounded,
                        compact: true,
                      ),
                      InfoCard(
                        title: '최대 투자금',
                        value: '\$${fmt.format(state.maxExposure)}',
                        icon: Icons.arrow_upward_rounded,
                        compact: true,
                      ),
                    ],
                  ),
                  // 과거 사이클 결과
                  if (state.cycleResults.isNotEmpty) ...[
                    const SectionHeader(title: '완료된 사이클'),
                    ...state.cycleResults
                        .reversed
                        .map((r) => _buildCycleCard(context, r, fmt)),
                  ],
                  const SizedBox(height: 24),
                  // 새로 시작 버튼
                  OutlinedButton.icon(
                    onPressed: () => _confirmReset(context, provider),
                    icon: const Icon(Icons.add_circle_outline_rounded),
                    label: const Text('신규 전략 시작'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                      foregroundColor: colorScheme.error,
                      side: BorderSide(color: colorScheme.error),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCycleCard(
    BuildContext context,
    CycleResult r,
    NumberFormat fmt,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isProfit = r.totalProfit >= 0;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      color: colorScheme.surfaceContainerHighest,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Cycle ${r.cycleNumber}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${r.investmentDays}일',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const Spacer(),
                Text(
                  '${isProfit ? '+' : ''}\$${fmt.format(r.totalProfit)}',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: isProfit ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${isProfit ? '+' : ''}${r.profitRate.toStringAsFixed(1)}%',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isProfit ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _statChip(context, '최대T', r.maxT.toStringAsFixed(1)),
                const SizedBox(width: 6),
                _statChip(context, '최대수량', '${r.maxQty}주'),
                const SizedBox(width: 6),
                _statChip(
                    context, '최대투자', '\$${fmt.format(r.maxExposure)}'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _statChip(BuildContext context, String label, String value) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(6),
      ),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: '$label: ',
              style: TextStyle(
                fontSize: 10,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            TextSpan(
              text: value,
              style: TextStyle(
                fontSize: 10,
                color: colorScheme.onSurface,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmReset(BuildContext context, StrategyProvider provider) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('전략 초기화'),
        content: const Text(
          '현재 전략을 종료하고 새로 시작하시겠습니까?\n모든 진행 상황이 삭제됩니다.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              await provider.resetStrategy();
              if (!context.mounted) return;
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const StartScreen()),
                (route) => false,
              );
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('초기화'),
          ),
        ],
      ),
    );
  }
}
