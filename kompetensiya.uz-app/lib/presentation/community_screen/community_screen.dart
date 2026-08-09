import 'package:flutter/material.dart';

import '../../core/api_service.dart';
import '../../theme/app_theme.dart';
import './widgets/community_post_card_widget.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  List<Map<String, dynamic>> _posts = [];
  List<Map<String, dynamic>> _events = [];
  bool _isLoading = true;
  String? _error;

  Future<void> _loadCommunity() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        ApiService.getList('/api/community/posts/'),
        ApiService.getList('/api/community/events/'),
      ]);
      if (!mounted) return;
      setState(() {
        _posts = results[0];
        _events = results[1];
        _isLoading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _isLoading = false;
      });
    }
  }

  Widget _buildError(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.wifi_off_rounded,
              size: 48,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(height: 12),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadCommunity,
              child: const Text('Qayta urinish'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty(ThemeData theme, IconData icon, String message) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: theme.colorScheme.outline),
          const SizedBox(height: 12),
          Text(
            message,
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadCommunity();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Color _eventColor(String key) {
    switch (key) {
      case 'orange':
        return AppTheme.cardOrange;
      case 'green':
        return AppTheme.cardGreen;
      case 'purple':
        return AppTheme.cardPurple;
      default:
        return AppTheme.cardBlue;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hamjamiyat',
                        style: theme.textTheme.displaySmall?.copyWith(
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Yangiliklar va tadbirlar',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppTheme.primary,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primary.withAlpha(77),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.add_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ],
              ),
            ),

            // Tab bar — 3 tabs now
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Container(
                height: 44,
                decoration: BoxDecoration(
                  color: AppTheme.surfaceVariantLight,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    color: AppTheme.primary,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  labelColor: Colors.white,
                  unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
                  labelStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  tabs: const [
                    Tab(text: 'Postlar'),
                    Tab(text: 'Tadbirlar'),
                    Tab(text: 'Reyting'),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Tab content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Posts tab — backend (API) dan
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _error != null
                      ? _buildError(theme)
                      : _posts.isEmpty
                      ? _buildEmpty(theme, Icons.forum_outlined,
                          'Hozircha postlar yo\'q')
                      : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                    physics: const BouncingScrollPhysics(),
                    itemCount: _posts.length,
                    itemBuilder: (context, index) {
                      return TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.0, end: 1.0),
                        duration: Duration(
                          milliseconds: 300 + (index * 60).clamp(0, 400),
                        ),
                        curve: Curves.easeOutCubic,
                        builder: (context, value, child) {
                          return Opacity(
                            opacity: value,
                            child: Transform.translate(
                              offset: Offset(0, 20 * (1 - value)),
                              child: child,
                            ),
                          );
                        },
                        child: CommunityPostCardWidget(postMap: _posts[index]),
                      );
                    },
                  ),

                  // Events tab — backend (API) dan
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _error != null
                      ? _buildError(theme)
                      : _events.isEmpty
                      ? _buildEmpty(theme, Icons.event_busy_outlined,
                          'Hozircha tadbirlar yo\'q')
                      : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                    physics: const BouncingScrollPhysics(),
                    itemCount: _events.length,
                    itemBuilder: (context, index) {
                      final event = _events[index];
                      final color = _eventColor(event['color'] as String);
                      return TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.0, end: 1.0),
                        duration: Duration(
                          milliseconds: 300 + (index * 80).clamp(0, 400),
                        ),
                        curve: Curves.easeOutCubic,
                        builder: (context, value, child) {
                          return Opacity(
                            opacity: value,
                            child: Transform.translate(
                              offset: Offset(0, 20 * (1 - value)),
                              child: child,
                            ),
                          );
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceLight,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withAlpha(10),
                                blurRadius: 12,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: color.withAlpha(26),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      event['day'] as String,
                                      style: TextStyle(
                                        color: color,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w800,
                                        height: 1,
                                      ),
                                    ),
                                    Text(
                                      event['month'] as String,
                                      style: TextStyle(
                                        color: color.withAlpha(179),
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      event['title'] as String,
                                      style: theme.textTheme.titleSmall
                                          ?.copyWith(
                                            color: theme.colorScheme.onSurface,
                                          ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.location_on_outlined,
                                          size: 13,
                                          color: theme
                                              .colorScheme
                                              .onSurfaceVariant,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          event['location'] as String,
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                                color: theme
                                                    .colorScheme
                                                    .onSurfaceVariant,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: color.withAlpha(26),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  'Qatnashish',
                                  style: TextStyle(
                                    color: color,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),

                  // Reyting tab
                  const _ReytingTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Reyting Tab
// ─────────────────────────────────────────────────────────────────────────────

class _ReytingTab extends StatefulWidget {
  const _ReytingTab();

  @override
  State<_ReytingTab> createState() => _ReytingTabState();
}

class _ReytingTabState extends State<_ReytingTab> {
  int _selectedFilter = 0; // 0=Yosh, 1=Hudud, 2=Respublika

  static const List<String> _filters = [
    'Yosh bo\'yicha',
    'Hudud bo\'yicha',
    'Umumiy respublika',
  ];

  List<Map<String, dynamic>> _byAge = [];
  List<Map<String, dynamic>> _byRegion = [];
  List<Map<String, dynamic>> _overall = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRating();
  }

  Future<void> _loadRating() async {
    try {
      final results = await Future.wait([
        ApiService.getList('/api/rating/', query: {'by': 'age'}),
        ApiService.getList('/api/rating/', query: {'by': 'region'}),
        ApiService.getList('/api/rating/', query: {'by': 'overall'}),
      ]);
      if (!mounted) return;
      setState(() {
        _byAge = results[0];
        _byRegion = results[1];
        _overall = results[2];
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> get _currentData {
    switch (_selectedFilter) {
      case 1:
        return _byRegion;
      case 2:
        return _overall;
      default:
        return _byAge;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final data = _currentData;

    return Column(
      children: [
        // Filter chips
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          child: Row(
            children: List.generate(_filters.length, (i) {
              final isSelected = i == _selectedFilter;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedFilter = i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: EdgeInsets.only(
                      right: i < _filters.length - 1 ? 8 : 0,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppTheme.primary
                          : AppTheme.surfaceVariantLight,
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: Text(
                      _filters[i],
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : theme.colorScheme.onSurfaceVariant,
                        fontSize: 11,
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),

        if (_isLoading)
          const Expanded(child: Center(child: CircularProgressIndicator()))
        else if (data.isEmpty)
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.leaderboard_outlined,
                    size: 48,
                    color: theme.colorScheme.outline,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Reyting ma\'lumotlari hali yo\'q',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          )
        else ...[
        // Top 3 podium (only for overall republic)
        if (_selectedFilter == 2) _buildPodium(data),

        // List
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.fromLTRB(
              20,
              _selectedFilter == 2 ? 8 : 0,
              20,
              120,
            ),
            physics: const BouncingScrollPhysics(),
            itemCount: _selectedFilter == 2
                ? (data.length > 3 ? data.length - 3 : 0)
                : data.length,
            itemBuilder: (context, index) {
              final item = _selectedFilter == 2 ? data[index + 3] : data[index];
              return TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: Duration(
                  milliseconds: 250 + (index * 50).clamp(0, 300),
                ),
                curve: Curves.easeOutCubic,
                builder: (context, value, child) => Opacity(
                  opacity: value,
                  child: Transform.translate(
                    offset: Offset(0, 16 * (1 - value)),
                    child: child,
                  ),
                ),
                child: _buildRankCard(context, item, theme),
              );
            },
          ),
        ),
        ],
      ],
    );
  }

  Widget _buildPodium(List<Map<String, dynamic>> data) {
    if (data.length < 3) return const SizedBox.shrink();
    final top3 = data.take(3).toList();
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20.0),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // 2nd place
            _PodiumItem(
              item: top3[1],
              height: 70,
              color: const Color(0xFFC0C0C0),
            ),
            // 1st place
            _PodiumItem(
              item: top3[0],
              height: 90,
              color: const Color(0xFFFFD700),
            ),
            // 3rd place
            _PodiumItem(
              item: top3[2],
              height: 55,
              color: const Color(0xFFCD7F32),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRankCard(
    BuildContext context,
    Map<String, dynamic> item,
    ThemeData theme,
  ) {
    final rank = item['rank'] as int;
    final isMe = (item['isMe'] as bool?) ?? false;
    final score = item['score'];
    final scoreStr = score is int ? score.toString() : score.toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isMe ? AppTheme.primary.withAlpha(20) : AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(16.0),
        border: isMe
            ? Border.all(color: AppTheme.primary.withAlpha(100), width: 1.5)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Rank number
          SizedBox(
            width: 32,
            child: Text(
              '#$rank',
              style: TextStyle(
                color: rank <= 3
                    ? AppTheme.secondary
                    : theme.colorScheme.onSurfaceVariant,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Avatar
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isMe
                    ? [AppTheme.primary, AppTheme.primaryLight]
                    : [
                        AppTheme.surfaceVariantLight,
                        AppTheme.surfaceVariantLight,
                      ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                (item['name'] as String).substring(0, 1),
                style: TextStyle(
                  color: isMe
                      ? Colors.white
                      : theme.colorScheme.onSurfaceVariant,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Name & subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        item['name'] as String,
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: theme.colorScheme.onSurface,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isMe) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primary,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Text(
                          'Siz',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  _selectedFilter == 1
                      ? '${item['members']} a\'zo'
                      : _selectedFilter == 2
                      ? '${item['specialty']} • ${item['region']}'
                      : '${item['age']} yosh • ${item['region']}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          // Score
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                scoreStr,
                style: TextStyle(
                  color: AppTheme.primary,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                'ball',
                style: TextStyle(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PodiumItem extends StatelessWidget {
  final Map<String, dynamic> item;
  final double height;
  final Color color;

  const _PodiumItem({
    required this.item,
    required this.height,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final rank = item['rank'] as int;
    final name = item['name'] as String;
    final score = item['score'];
    final badge = item['badge'] as String;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(badge, style: const TextStyle(fontSize: 20)),
        const SizedBox(height: 4),
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: color.withAlpha(51),
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 2),
          ),
          child: Center(
            child: Text(
              name.substring(0, 1),
              style: TextStyle(
                color: color,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        SizedBox(
          width: 80,
          child: Text(
            name.split(' ').first,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: 80,
          height: height,
          decoration: BoxDecoration(
            color: color.withAlpha(38),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(8.0),
              topRight: Radius.circular(8.0),
            ),
            border: Border(top: BorderSide(color: color, width: 2)),
          ),
          child: Center(
            child: Text(
              '#$rank',
              style: TextStyle(
                color: color,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
