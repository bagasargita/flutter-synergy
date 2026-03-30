import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_synergy/core/router/app_router.dart';
import 'package:flutter_synergy/core/widgets/async_value_widget.dart';
import 'package:flutter_synergy/features/auth/auth_provider.dart';
import 'package:flutter_synergy/features/dashboard/dashboard_provider.dart';
import 'package:flutter_synergy/core/widgets/global_bottom_nav.dart';
import 'package:flutter_synergy/features/dashboard/widgets/announcements_section.dart';
import 'package:flutter_synergy/features/dashboard/widgets/dashboard_header.dart';
import 'package:flutter_synergy/features/dashboard/widgets/dashboard_theme.dart';
import 'package:flutter_synergy/features/dashboard/widgets/daily_check_in_card.dart';
import 'package:flutter_synergy/features/dashboard/widgets/this_month_section.dart';
import 'package:flutter_synergy/features/calendar/calendar_page.dart';

// ---------------------------------------------------------------------------
// Main page with bottom navigation
// ---------------------------------------------------------------------------

class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
  int _currentTab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DashboardTheme.bgColor,
      body: IndexedStack(
        index: _currentTab,
        children: const [_HomeTab(), CalendarTab(), _ProfilePlaceholder()],
      ),
      bottomNavigationBar: GlobalBottomNav(
        items: const [
          GlobalBottomNavItem(label: 'HOME', icon: Icons.home_rounded),
          GlobalBottomNavItem(
            label: 'CALENDAR',
            icon: Icons.calendar_today_outlined,
          ),
          GlobalBottomNavItem(
            label: 'PROFILE',
            icon: Icons.person_outline_rounded,
          ),
        ],
        currentIndex: _currentTab,
        onTap: (i) => setState(() => _currentTab = i),
        selectedColor: DashboardTheme.accentBlue,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// HOME tab – main scrollable content
// ---------------------------------------------------------------------------

class _HomeTab extends ConsumerWidget {
  const _HomeTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashState = ref.watch(dashboardControllerProvider);
    final authState = ref.watch(authControllerProvider);

    if (dashState.isLoading && dashState.data == null) {
      return const LoadingWidget();
    }

    if (dashState.errorMessage != null && dashState.data == null) {
      return ErrorDisplayWidget(
        message: dashState.errorMessage!,
        onRetry: () => ref.read(dashboardControllerProvider.notifier).refresh(),
      );
    }

    final data = dashState.data;
    if (data == null) return const SizedBox.shrink();

    final fullName = authState.profile?.fullName;
    final userName = (fullName != null && fullName.isNotEmpty)
        ? fullName
        : (authState.user?.name ?? 'User');

    return RefreshIndicator(
      color: DashboardTheme.accentBlue,
      onRefresh: () => ref.read(dashboardControllerProvider.notifier).refresh(),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        children: [
          SizedBox(height: MediaQuery.of(context).padding.top + 16),
          DashboardHeader(userName: userName),
          const SizedBox(height: 20),
          DailyCheckInCard(
            attendance: data.dailyAttendance,
            onCheckIn: () {
              context.push(
                '${RoutePaths.attendance}?mode=check_in',
              );
            },
            onCheckOut: () {
              context.push(
                '${RoutePaths.attendance}?mode=check_out',
              );
            },
          ),
          const SizedBox(height: 20),
          ThisMonthSection(
            monthStats: data.monthStats,
            totalTimesheet: data.totalTimesheet,
          ),
          const SizedBox(height: 20),
          AnnouncementsSection(
            announcements: data.announcements,
            onViewAll: () {
              // TODO: Navigate to full announcements list
            },
          ),
        ],
      ),
    );
  }
}

class _ProfilePlaceholder extends ConsumerWidget {
  const _ProfilePlaceholder();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final user = authState.user;
    final fullName = authState.profile?.fullName;
    final displayName = (fullName != null && fullName.isNotEmpty)
        ? fullName
        : (user?.name ?? 'User');

    return Scaffold(
      backgroundColor: DashboardTheme.bgColor,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: DashboardTheme.accentBlue.withValues(
                  alpha: 0.12,
                ),
                child: const Icon(
                  Icons.person_rounded,
                  size: 48,
                  color: DashboardTheme.accentBlue,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                displayName,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: DashboardTheme.darkText,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                user?.username ?? '',
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 32),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: OutlinedButton.icon(
                  onPressed: () {
                    ref.read(authControllerProvider.notifier).logout();
                    context.go(RoutePaths.login);
                  },
                  icon: const Icon(Icons.logout_rounded),
                  label: const Text('Logout'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
