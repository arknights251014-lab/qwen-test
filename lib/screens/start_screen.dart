import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/strategy_provider.dart';
import 'dashboard_screen.dart';

class StartScreen extends StatefulWidget {
  const StartScreen({super.key});

  @override
  State<StartScreen> createState() => _StartScreenState();
}

class _StartScreenState extends State<StartScreen> {
  final _formKey = GlobalKey<FormState>();
  final _capitalCtrl = TextEditingController(text: '10000');
  final _splitCtrl = TextEditingController(text: '10');
  final _profitCtrl = TextEditingController(text: '20');
  bool _isStarting = false;

  @override
  void dispose() {
    _capitalCtrl.dispose();
    _splitCtrl.dispose();
    _profitCtrl.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isStarting = true);

    final capital = double.parse(_capitalCtrl.text.replaceAll(',', ''));
    final split = int.parse(_splitCtrl.text);
    final profit = double.parse(_profitCtrl.text);

    await context.read<StrategyProvider>().startStrategy(
          capital: capital,
          splitCount: split,
          targetProfit: profit,
        );

    if (!mounted) return;
    setState(() => _isStarting = false);
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const DashboardScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: size.width > 600 ? size.width * 0.2 : 24,
            vertical: 24,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 32),
              // 로고 영역
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Icon(
                        Icons.trending_up_rounded,
                        size: 44,
                        color: colorScheme.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '무한매수법 4.0',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: colorScheme.secondaryContainer,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'SOXL 전용',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: colorScheme.onSecondaryContainer,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              // 입력 폼
              Card(
                elevation: 0,
                color: colorScheme.surfaceContainerLow,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          '전략 설정',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 20),
                        _buildField(
                          context,
                          controller: _capitalCtrl,
                          label: '초기 자본 (Capital)',
                          hint: '예: 10000',
                          prefix: '\$',
                          icon: Icons.account_balance_wallet_rounded,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          validator: (v) {
                            if (v == null || v.isEmpty) return '자본을 입력하세요';
                            final n = double.tryParse(v.replaceAll(',', ''));
                            if (n == null || n <= 0) return '유효한 금액을 입력하세요';
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        _buildField(
                          context,
                          controller: _splitCtrl,
                          label: '분할 횟수 (SplitCount)',
                          hint: '예: 10',
                          icon: Icons.splitscreen_rounded,
                          suffix: '회',
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly
                          ],
                          validator: (v) {
                            if (v == null || v.isEmpty) return '분할 횟수를 입력하세요';
                            final n = int.tryParse(v);
                            if (n == null || n < 2) return '2 이상 입력하세요';
                            if (n > 100) return '100 이하로 입력하세요';
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        _buildField(
                          context,
                          controller: _profitCtrl,
                          label: '목표 수익률 (TargetProfit)',
                          hint: '예: 20',
                          icon: Icons.percent_rounded,
                          suffix: '%',
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          validator: (v) {
                            if (v == null || v.isEmpty) return '목표 수익률을 입력하세요';
                            final n = double.tryParse(v);
                            if (n == null || n <= 0) return '0보다 큰 값을 입력하세요';
                            if (n > 200) return '200% 이하로 입력하세요';
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // 설명 카드
              Card(
                elevation: 0,
                color: colorScheme.tertiaryContainer.withOpacity(0.4),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline_rounded,
                          size: 18, color: colorScheme.tertiary),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '전략 시작 후 매일 전일 종가와 고가를 입력하여 주문을 생성합니다.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onTertiaryContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 28),
              // 시작 버튼
              FilledButton.icon(
                onPressed: _isStarting ? null : _start,
                icon: _isStarting
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: colorScheme.onPrimary,
                        ),
                      )
                    : const Icon(Icons.play_arrow_rounded),
                label:
                    Text(_isStarting ? '시작 중...' : '전략 시작'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  textStyle: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(
    BuildContext context, {
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    String? prefix,
    String? suffix,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, size: 20),
        prefixText: prefix != null ? '$prefix ' : null,
        suffixText: suffix,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: colorScheme.surface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}
