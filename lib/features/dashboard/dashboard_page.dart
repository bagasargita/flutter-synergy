import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_synergy/core/router/app_router.dart';
import 'package:flutter_synergy/core/widgets/async_value_widget.dart';
import 'package:flutter_synergy/core/widgets/global_confirm_dialog.dart';
import 'package:flutter_synergy/features/auth/auth_provider.dart';
import 'package:flutter_synergy/features/dashboard/dashboard_provider.dart';
import 'package:flutter_synergy/core/widgets/global_bottom_nav.dart';
import 'package:flutter_synergy/features/dashboard/widgets/announcements_section.dart';
import 'package:flutter_synergy/features/dashboard/widgets/dashboard_header.dart';
import 'package:flutter_synergy/features/dashboard/widgets/dashboard_theme.dart';
import 'package:flutter_synergy/features/dashboard/widgets/daily_check_in_card.dart';
import 'package:flutter_synergy/features/dashboard/widgets/this_month_section.dart';
import 'package:flutter_synergy/features/calendar/calendar_provider.dart';
import 'package:flutter_synergy/features/calendar/calendar_page.dart';
import 'package:package_info_plus/package_info_plus.dart';

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
        children: [
          const _HomeTab(),
          const CalendarTab(),
          _ProfileTab(onBackToHome: () => setState(() => _currentTab = 0)),
        ],
      ),
      bottomNavigationBar: GlobalBottomNav(
        items: [
          GlobalBottomNavItem(
            label: 'HOME',
            icon: Icons.home_rounded,
            onSelected: () =>
                ref.read(dashboardControllerProvider.notifier).refresh(),
          ),
          GlobalBottomNavItem(
            label: 'CALENDAR',
            icon: Icons.calendar_today_outlined,
            onSelected: () =>
                ref.read(calendarControllerProvider.notifier).refresh(),
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
              context.push('${RoutePaths.attendance}?mode=check_in');
            },
            onCheckOut: () {
              context.push('${RoutePaths.attendance}?mode=check_out');
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
            onViewAll: () => context.push(RoutePaths.announcements),
          ),
        ],
      ),
    );
  }
}

String _profileInitials(String name) {
  final parts = name
      .trim()
      .split(RegExp(r'\s+'))
      .where((e) => e.isNotEmpty)
      .toList();
  if (parts.isEmpty) return '?';
  if (parts.length == 1) {
    final s = parts[0];
    if (s.length >= 2) return s.substring(0, 2).toUpperCase();
    return s.toUpperCase();
  }
  final a = parts.first[0];
  final b = parts.last[0];
  return ('$a$b').toUpperCase();
}

class _ProfileTab extends ConsumerStatefulWidget {
  const _ProfileTab({required this.onBackToHome});

  final VoidCallback onBackToHome;

  @override
  ConsumerState<_ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends ConsumerState<_ProfileTab> {
  String? _appVersion;

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) setState(() => _appVersion = info.version);
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final user = authState.user;
    final profile = authState.profile;
    final fullName = profile?.fullName;
    final displayName = (fullName != null && fullName.isNotEmpty)
        ? fullName
        : (user?.name ?? 'User');

    final titleText = (profile?.titleName ?? '').trim();
    final deptText = (profile?.disciplineName ?? '').trim();
    final companyText = (profile?.companyName ?? '').trim();
    final subtitleDept = deptText.isNotEmpty
        ? deptText
        : (companyText.isNotEmpty ? companyText : '');

    final accent = DashboardTheme.accentBlue;
    const darkBlue = Color(0xFF1A3A6B);

    return Scaffold(
      backgroundColor: DashboardTheme.bgColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: MediaQuery.of(context).padding.top + 2),
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 4, 12, 8),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const Text(
                    'Profile',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: darkBlue,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    const SizedBox(height: 28),
                    Stack(
                      clipBehavior: Clip.none,
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 112,
                          height: 112,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: accent,
                            boxShadow: [
                              BoxShadow(
                                color: accent.withValues(alpha: 0.35),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            _profileInitials(displayName),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 36,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        Positioned(
                          right: -2,
                          bottom: -2,
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white,
                                width: 2.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.18),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Material(
                              color: accent,
                              shape: const CircleBorder(),
                              clipBehavior: Clip.antiAlias,
                              elevation: 0,
                              child: InkWell(
                                customBorder: const CircleBorder(),
                                onTap: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Edit profile is not available yet.',
                                      ),
                                    ),
                                  );
                                },
                                child: const Padding(
                                  padding: EdgeInsets.all(8),
                                  child: Icon(
                                    Icons.edit_rounded,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      displayName,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: darkBlue,
                      ),
                    ),
                    if (titleText.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        titleText,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15,
                          height: 1.35,
                          fontWeight: FontWeight.w500,
                          color: Colors.blueGrey.shade700,
                        ),
                      ),
                    ],
                    if (subtitleDept.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        subtitleDept,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.35,
                          color: Colors.blueGrey.shade400,
                        ),
                      ),
                    ],
                    const SizedBox(height: 40),
                    Material(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: () async {
                          final confirmed = await showGlobalConfirmDialog(
                            context: context,
                            title: 'Log out?',
                            message:
                                'You will need to sign in again to use the app.',
                            cancelText: 'Cancel',
                            confirmText: 'Log out',
                            confirmIsDestructive: true,
                          );
                          if (!confirmed || !context.mounted) return;
                          ref.read(authControllerProvider.notifier).logout();
                          context.go(RoutePaths.login);
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFE4E6),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  Icons.logout_rounded,
                                  color: Colors.red.shade600,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Text(
                                'Logout',
                                style: TextStyle(
                                  color: Colors.red.shade600,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_appVersion != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                child: Text(
                  'VERSION ${_appVersion!}'.toUpperCase(),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.blueGrey.shade400,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
