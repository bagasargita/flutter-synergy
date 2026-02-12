import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_synergy/core/constants/app_constants.dart';
import 'package:flutter_synergy/core/widgets/async_value_widget.dart';
import 'package:flutter_synergy/core/widgets/empty_state_widget.dart';
import 'package:flutter_synergy/features/approval/approval_controller.dart';
import 'package:flutter_synergy/features/approval/approval_provider.dart';
import 'package:flutter_synergy/features/approval/approval_service.dart';

class ApprovalPage extends ConsumerWidget {
  const ApprovalPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(approvalControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Approvals')),
      body: _buildBody(context, ref, state),
    );
  }

  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    ApprovalState state,
  ) {
    if (state.isLoading && state.items.isEmpty) {
      return const LoadingWidget();
    }

    if (state.errorMessage != null && state.items.isEmpty) {
      return ErrorDisplayWidget(
        message: state.errorMessage!,
        onRetry: () =>
            ref.read(approvalControllerProvider.notifier).refresh(),
      );
    }

    if (state.items.isEmpty) {
      return const EmptyStateWidget(
        icon: Icons.check_circle_outline_rounded,
        title: 'All caught up!',
        subtitle: 'No pending approvals',
      );
    }

    return RefreshIndicator(
      onRefresh: () =>
          ref.read(approvalControllerProvider.notifier).refresh(),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(
          vertical: AppConstants.defaultPadding / 2,
        ),
        itemCount: state.items.length,
        itemBuilder: (context, index) {
          final item = state.items[index];
          return _ApprovalItemCard(item: item);
        },
      ),
    );
  }
}

class _ApprovalItemCard extends StatelessWidget {
  const _ApprovalItemCard({required this.item});

  final ApprovalItem item;

  Color _statusColor(ThemeData theme) {
    switch (item.status) {
      case ApprovalStatus.pending:
        return Colors.orange;
      case ApprovalStatus.approved:
        return Colors.green;
      case ApprovalStatus.rejected:
        return theme.colorScheme.error;
    }
  }

  IconData _statusIcon() {
    switch (item.status) {
      case ApprovalStatus.pending:
        return Icons.hourglass_empty_rounded;
      case ApprovalStatus.approved:
        return Icons.check_circle_rounded;
      case ApprovalStatus.rejected:
        return Icons.cancel_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _statusColor(theme);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Row(
          children: [
            // Status icon
            CircleAvatar(
              backgroundColor: color.withValues(alpha: 0.15),
              child: Icon(_statusIcon(), color: color, size: 20),
            ),
            const SizedBox(width: 12),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Requested by ${item.requester}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),

            // Status chip
            Chip(
              label: Text(
                item.status.name.toUpperCase(),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
              side: BorderSide(color: color.withValues(alpha: 0.3)),
              backgroundColor: color.withValues(alpha: 0.08),
            ),
          ],
        ),
      ),
    );
  }
}
