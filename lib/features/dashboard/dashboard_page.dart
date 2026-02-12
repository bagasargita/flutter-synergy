import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_synergy/core/constants/app_constants.dart';
import 'package:flutter_synergy/core/router/app_router.dart';
import 'package:flutter_synergy/core/widgets/async_value_widget.dart';
import 'package:flutter_synergy/core/widgets/empty_state_widget.dart';
import 'package:flutter_synergy/features/auth/auth_provider.dart';
import 'package:flutter_synergy/features/dashboard/dashboard_controller.dart';
import 'package:flutter_synergy/features/dashboard/dashboard_provider.dart';
import 'package:flutter_synergy/features/dashboard/dashboard_service.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardState = ref.watch(dashboardControllerProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConstants.appName),
        actions: [
          IconButton(
            icon: const Icon(Icons.approval_rounded),
            tooltip: 'Approvals',
            onPressed: () => context.push(RoutePaths.approval),
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Logout',
            onPressed: () {
              ref.read(authControllerProvider.notifier).logout();
              context.go(RoutePaths.login);
            },
          ),
        ],
      ),
      body: _buildBody(context, ref, dashboardState, theme),
    );
  }

  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    DashboardState state,
    ThemeData theme,
  ) {
    if (state.isLoading && state.items.isEmpty) {
      return const LoadingWidget();
    }

    if (state.errorMessage != null && state.items.isEmpty) {
      return ErrorDisplayWidget(
        message: state.errorMessage!,
        onRetry: () =>
            ref.read(dashboardControllerProvider.notifier).refresh(),
      );
    }

    if (state.items.isEmpty) {
      return const EmptyStateWidget(
        title: 'No items yet',
        subtitle: 'Pull down to refresh',
      );
    }

    return RefreshIndicator(
      onRefresh: () =>
          ref.read(dashboardControllerProvider.notifier).refresh(),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(
          vertical: AppConstants.defaultPadding / 2,
        ),
        itemCount: state.items.length,
        itemBuilder: (context, index) {
          final item = state.items[index];
          return _DashboardItemCard(item: item);
        },
      ),
    );
  }
}

class _DashboardItemCard extends StatelessWidget {
  const _DashboardItemCard({required this.item});

  final DashboardItem item;

  Color _statusColor(ThemeData theme) {
    switch (item.status) {
      case 'active':
        return theme.colorScheme.primary;
      case 'pending':
        return Colors.orange;
      case 'completed':
        return Colors.green;
      default:
        return theme.colorScheme.outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _statusColor(theme).withValues(alpha: 0.15),
          child: Icon(
            Icons.dashboard_rounded,
            color: _statusColor(theme),
          ),
        ),
        title: Text(item.title),
        subtitle: Text(item.subtitle),
        trailing: Chip(
          label: Text(
            item.status.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: _statusColor(theme),
            ),
          ),
          side: BorderSide(color: _statusColor(theme).withValues(alpha: 0.3)),
          backgroundColor: _statusColor(theme).withValues(alpha: 0.08),
        ),
      ),
    );
  }
}
