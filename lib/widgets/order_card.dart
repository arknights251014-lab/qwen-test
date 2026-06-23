import 'package:flutter/material.dart';
import '../models/order.dart';

class OrderCard extends StatelessWidget {
  final Order order;
  final bool isBuy;

  const OrderCard({super.key, required this.order, required this.isBuy});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final isFilled = order.status == OrderStatus.filled;
    final statusColor = isFilled
        ? (isBuy ? Colors.blue : Colors.green)
        : colorScheme.onSurfaceVariant;

    final bgColor = isFilled
        ? (isBuy
            ? Colors.blue.withOpacity(0.08)
            : Colors.green.withOpacity(0.08))
        : colorScheme.surfaceContainerHighest;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 3),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isFilled
              ? statusColor.withOpacity(0.3)
              : colorScheme.outlineVariant.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // 타입 배지
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              order.typeLabel,
              style: theme.textTheme.labelSmall?.copyWith(
                color: statusColor,
                fontWeight: FontWeight.bold,
                fontSize: 10,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // 레이블
          Expanded(
            child: Text(
              order.label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurface,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          // 수량
          Text(
            '${order.qty}주',
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(width: 8),
          // 가격
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '\$${order.price.toStringAsFixed(2)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 11,
                ),
              ),
              if (isFilled && order.filledPrice != null)
                Text(
                  '체결 \$${order.filledPrice!.toStringAsFixed(2)}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: statusColor,
                    fontSize: 10,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 6),
          // 상태 아이콘
          Icon(
            isFilled ? Icons.check_circle_rounded : Icons.schedule_rounded,
            size: 16,
            color: statusColor,
          ),
        ],
      ),
    );
  }
}
