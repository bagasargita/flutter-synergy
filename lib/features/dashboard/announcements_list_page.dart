import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_synergy/core/api/api_exception.dart';
import 'package:flutter_synergy/core/widgets/image_zoom_dialog.dart';
import 'package:flutter_synergy/features/dashboard/dashboard_provider.dart';
import 'package:flutter_synergy/features/dashboard/dashboard_service.dart';
import 'package:flutter_synergy/features/dashboard/widgets/dashboard_theme.dart';

/// Full announcements list with infinite scroll (`/articles?page=`).
class AnnouncementsListPage extends ConsumerStatefulWidget {
  const AnnouncementsListPage({super.key});

  @override
  ConsumerState<AnnouncementsListPage> createState() =>
      _AnnouncementsListPageState();
}

class _AnnouncementsListPageState extends ConsumerState<AnnouncementsListPage> {
  final ScrollController _scroll = ScrollController();

  final List<Announcement> _items = [];
  int _lastLoadedPage = 0;
  bool _hasMore = true;
  bool _loadingInitial = true;
  bool _loadingMore = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    _loadFirstPage();
  }

  @override
  void dispose() {
    _scroll.removeListener(_onScroll);
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_loadingInitial || _loadingMore || !_hasMore) return;
    if (!_scroll.hasClients) return;
    final pos = _scroll.position;
    if (pos.pixels >= pos.maxScrollExtent - 360) {
      _loadNextPage();
    }
  }

  Future<void> _loadFirstPage() async {
    setState(() {
      _loadingInitial = true;
      _error = null;
      _items.clear();
      _lastLoadedPage = 0;
      _hasMore = true;
    });
    try {
      final service = ref.read(dashboardServiceProvider);
      final result = await service.fetchArticlesPage(1);
      if (!mounted) return;
      setState(() {
        _loadingInitial = false;
        _items.addAll(result.items);
        _hasMore = result.hasMore;
        _lastLoadedPage = 1;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingInitial = false;
        _error = e is ApiException ? e.message : e.toString();
      });
    }
  }

  Future<void> _loadNextPage() async {
    if (_loadingMore || !_hasMore || _loadingInitial) return;
    setState(() => _loadingMore = true);
    final page = _lastLoadedPage + 1;
    try {
      final service = ref.read(dashboardServiceProvider);
      final result = await service.fetchArticlesPage(page);
      if (!mounted) return;
      setState(() {
        _loadingMore = false;
        _items.addAll(result.items);
        _hasMore = result.hasMore;
        _lastLoadedPage = page;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingMore = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e is ApiException ? e.message : e.toString())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: DashboardTheme.bgColor,
      appBar: AppBar(
        backgroundColor: DashboardTheme.bgColor,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: cs.onSurface),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Announcements',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: DashboardTheme.darkText,
          ),
        ),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        color: DashboardTheme.accentBlue,
        onRefresh: _loadFirstPage,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_loadingInitial) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null && _items.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: MediaQuery.sizeOf(context).height * 0.25),
          Icon(Icons.wifi_off_rounded, size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              _error!,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade700),
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: FilledButton(
              onPressed: _loadFirstPage,
              child: const Text('Retry'),
            ),
          ),
        ],
      );
    }
    if (_items.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: MediaQuery.sizeOf(context).height * 0.3),
          Center(
            child: Text(
              'No announcements yet.',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 15),
            ),
          ),
        ],
      );
    }

    return ListView.separated(
      controller: _scroll,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      itemCount:
          _items.length +
          (_loadingMore || (!_hasMore && _items.isNotEmpty) ? 1 : 0),
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        if (index >= _items.length) {
          if (_loadingMore) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            );
          }
          return Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 8),
            child: Text(
              'You have reached the end',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            ),
          );
        }
        final a = _items[index];
        return _AnnouncementListCard(announcement: a);
      },
    );
  }
}

class _AnnouncementListCard extends StatelessWidget {
  const _AnnouncementListCard({required this.announcement});

  final Announcement announcement;

  bool get _canZoom {
    final u = announcement.fileUrl?.trim() ?? '';
    return u.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    final url = announcement.fileUrl;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      shadowColor: Colors.transparent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.campaign_rounded,
                    color: Colors.orange.shade400,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    announcement.title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: DashboardTheme.darkText,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (url != null && url.isNotEmpty)
            InkWell(
              onTap: _canZoom
                  ? () => showImageZoomDialog(context: context, networkUrl: url)
                  : null,
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Image.network(
                  url,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return ColoredBox(
                      color: Colors.grey.shade100,
                      child: Center(
                        child: SizedBox(
                          width: 28,
                          height: 28,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: DashboardTheme.accentBlue,
                          ),
                        ),
                      ),
                    );
                  },
                  errorBuilder: (_, _, _) => ColoredBox(
                    color: Colors.grey.shade200,
                    child: Icon(
                      Icons.image_not_supported_outlined,
                      size: 40,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ),
              ),
            )
          else
            Container(
              width: double.infinity,
              height: 120,
              color: Colors.grey.shade100,
              alignment: Alignment.center,
              child: Icon(
                Icons.article_outlined,
                size: 40,
                color: Colors.grey.shade400,
              ),
            ),
          if (announcement.date.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
              child: Text(
                announcement.date,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            )
          else
            const SizedBox(height: 10),
        ],
      ),
    );
  }
}
