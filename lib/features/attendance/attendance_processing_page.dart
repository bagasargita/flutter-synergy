import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_synergy/core/api/api_exception.dart';
import 'package:flutter_synergy/core/router/app_router.dart';
import 'package:flutter_synergy/core/widgets/global_snackbar.dart';
import 'package:flutter_synergy/core/theme/app_theme.dart';
import 'package:flutter_synergy/features/attendance/attendance_models.dart';
import 'package:flutter_synergy/features/attendance/attendance_provider.dart';
import 'package:flutter_synergy/features/dashboard/dashboard_provider.dart';

/// Full-screen progress after selfie capture; POST check-in/out then returns to dashboard.
class AttendanceProcessingPage extends ConsumerStatefulWidget {
  const AttendanceProcessingPage({
    super.key,
    required this.kind,
    this.photoPath,
    required this.lat,
    required this.lon,
  });

  final AttendanceSubmitKind kind;
  /// `null` when profile has `selfie_required: false` (no camera step).
  final String? photoPath;
  final double lat;
  final double lon;

  @override
  ConsumerState<AttendanceProcessingPage> createState() =>
      _AttendanceProcessingPageState();
}

class _AttendanceProcessingPageState
    extends ConsumerState<AttendanceProcessingPage> {
  bool _busy = true;
  String? _error;
  double _uploadProgress = 0;
  bool _uploadComplete = false;
  bool _verifiedOk = false;

  @override
  void initState() {
    super.initState();
    _runSubmit();
  }

  Future<void> _runSubmit() async {
    setState(() {
      _busy = true;
      _error = null;
      _uploadProgress = 0.15;
      _uploadComplete = false;
      _verifiedOk = false;
    });

    try {
      await Future<void>.delayed(const Duration(milliseconds: 200));
      if (!mounted) return;
      setState(() => _uploadProgress = 0.45);

      final at = DateTime.now();
      await ref.read(attendanceServiceProvider).submitAttendance(
            kind: widget.kind,
            attachmentPath: widget.photoPath,
            lat: widget.lat,
            lon: widget.lon,
            at: at,
          );

      if (!mounted) return;
      setState(() {
        _uploadProgress = 1;
        _uploadComplete = true;
        _verifiedOk = true;
        _busy = false;
      });

      await ref.read(dashboardControllerProvider.notifier).refresh();

      if (!mounted) return;
      final isCheckIn = widget.kind == AttendanceSubmitKind.checkIn;

      await Future<void>.delayed(const Duration(milliseconds: 400));
      if (!mounted) return;
      final successAt = at;
      context.go(RoutePaths.dashboard);
      final subtitle = globalTopBannerTodayTimeLabel(successAt);
      final title = isCheckIn ? 'Check In Successful' : 'Check Out Successful';
      WidgetsBinding.instance.addPostFrameCallback((_) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          GlobalSnackbar.showTopBanner(
            title: title,
            subtitle: subtitle,
            leading: GlobalTopBannerCard.successLeading(),
          );
        });
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _busy = false;
        _uploadProgress = 0;
        _uploadComplete = false;
        _verifiedOk = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _busy = false;
      });
    }
  }

  bool get _hasPhoto =>
      widget.photoPath != null && widget.photoPath!.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = widget.kind == AttendanceSubmitKind.checkIn
        ? 'Check-in Progress'
        : 'Check-out Progress';

    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(title),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: _busy ? null : () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 24),
              SizedBox(
                width: 120,
                height: 120,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox.expand(
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        value: _busy ? null : 1,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    Icon(
                      Icons.cloud_outlined,
                      size: 48,
                      color: theme.colorScheme.primary,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              Text(
                'Processing Attendance',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                'Please wait while we verify your '
                '${widget.kind == AttendanceSubmitKind.checkIn ? 'check-in' : 'check-out'} '
                'and sync your data with the server.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              if (_hasPhoto)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    height: 160,
                    width: 120,
                    child: Image.file(
                      File(widget.photoPath!),
                      fit: BoxFit.cover,
                    ),
                  ),
                )
              else
                Icon(
                  Icons.place_rounded,
                  size: 64,
                  color: theme.colorScheme.primary.withValues(alpha: 0.5),
                ),
              const Spacer(),
              if (_error != null) ...[
                Text(
                  _error!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _runSubmit,
                  child: const Text('Try again'),
                ),
                const SizedBox(height: 16),
              ],
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: theme.colorScheme.primary.withValues(
                            alpha: 0.12,
                          ),
                          child: Icon(
                            _hasPhoto ? Icons.face_rounded : Icons.sync_rounded,
                            size: 18,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _hasPhoto ? 'Uploading Selfie' : 'Submitting',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Text(
                          _uploadComplete
                              ? '100%'
                              : '${(_uploadProgress * 100).clamp(0, 99).round()}%',
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        minHeight: 8,
                        value: _uploadComplete ? 1 : _uploadProgress,
                        backgroundColor: Colors.grey.shade200,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(
                          _verifiedOk
                              ? Icons.check_circle_rounded
                              : Icons.info_outline_rounded,
                          size: 20,
                          color: _verifiedOk
                              ? const Color(0xFF22C55E)
                              : Colors.grey.shade600,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _verifiedOk
                                ? 'Successfully verified'
                                : (_busy ? 'Uploading…' : 'Waiting…'),
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w500,
                              color: _verifiedOk
                                  ? const Color(0xFF16A34A)
                                  : Colors.grey.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
