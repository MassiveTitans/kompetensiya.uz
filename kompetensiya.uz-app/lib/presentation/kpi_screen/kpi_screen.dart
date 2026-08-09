import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/api_service.dart';
import '../../theme/app_theme.dart';

class KpiScreen extends StatefulWidget {
  const KpiScreen({super.key});

  @override
  State<KpiScreen> createState() => _KpiScreenState();
}

class _KpiScreenState extends State<KpiScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  List<Animation<double>> _progressAnimations = [];

  // KPI ko'rsatkichlari foydalanuvchiga tegishli — bazadan olinadi.
  List<_KpiCategory> _categories = [];
  bool _isLoading = true;
  String? _error;
  bool _needsLogin = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _loadKpi();
  }

  Future<void> _loadKpi() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _needsLogin = false;
    });
    try {
      final data = await ApiService.getList('/api/kpi/');
      if (!mounted) return;
      final categories = data.map(_KpiCategory.fromMap).toList();
      final itemCount = categories.fold<int>(0, (n, c) => n + c.kpis.length);
      setState(() {
        _categories = categories;
        _progressAnimations = List.generate(
          itemCount,
          (i) => Tween<double>(begin: 0, end: 1).animate(
            CurvedAnimation(
              parent: _animController,
              curve: Interval(
                (i * 0.06).clamp(0.0, 0.9),
                (0.6 + i * 0.04).clamp(0.1, 1.0),
                curve: Curves.easeOutCubic,
              ),
            ),
          ),
        );
        _isLoading = false;
      });
      _animController
        ..reset()
        ..forward();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _needsLogin = e.isUnauthorized;
        _error = e.isUnauthorized
            ? 'KPI ko\'rsatkichlarini ko\'rish uchun ONE ID orqali kiring.'
            : e.message;
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  double get _overallScore {
    double total = 0;
    int count = 0;
    for (final cat in _categories) {
      for (final kpi in cat.kpis) {
        total += (kpi.value / kpi.target).clamp(0.0, 1.0) * 100;
        count++;
      }
    }
    return count > 0 ? total / count : 0;
  }

  /// Turkumlar oldidagi animatsiya indeksini hisoblaydi.
  int _animOffset(int catIndex) {
    int offset = 0;
    for (int i = 0; i < catIndex; i++) {
      offset += _categories[i].kpis.length;
    }
    return offset;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final score = _overallScore;

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => context.pop(),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceLight,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(13),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          size: 18,
                          color: AppTheme.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'KPI ko\'rsatkichlari',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          Text(
                            '${_monthName(DateTime.now().month)} '
                            '${DateTime.now().year} — Joriy oy',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
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
                        color: AppTheme.primaryContainer,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.calendar_month_rounded,
                            size: 14,
                            color: AppTheme.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${DateTime.now().year}',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: AppTheme.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            if (_isLoading)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 80),
                  child: Center(child: CircularProgressIndicator()),
                ),
              )
            else if (_error != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(28, 60, 28, 0),
                  child: Column(
                    children: [
                      Icon(
                        _needsLogin
                            ? Icons.lock_outline_rounded
                            : Icons.wifi_off_rounded,
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
                        onPressed: _loadKpi,
                        child: const Text('Qayta urinish'),
                      ),
                    ],
                  ),
                ),
              )
            else if (_categories.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(28, 60, 28, 0),
                  child: Column(
                    children: [
                      Icon(
                        Icons.bar_chart_rounded,
                        size: 48,
                        color: theme.colorScheme.outline,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Sizga hali KPI ko\'rsatkichlari belgilanmagan',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else ...[
            // Overall score card
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1A1A2E), Color(0xFF0D47A1)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF1A1A2E).withAlpha(77),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Circular progress
                      SizedBox(
                        width: 90,
                        height: 90,
                        child: AnimatedBuilder(
                          animation: _animController,
                          builder: (context, _) {
                            return Stack(
                              alignment: Alignment.center,
                              children: [
                                SizedBox(
                                  width: 90,
                                  height: 90,
                                  child: CircularProgressIndicator(
                                    value:
                                        (score / 100) * _animController.value,
                                    strokeWidth: 8,
                                    backgroundColor: Colors.white.withAlpha(26),
                                    valueColor:
                                        const AlwaysStoppedAnimation<Color>(
                                          Color(0xFF64B5F6),
                                        ),
                                    strokeCap: StrokeCap.round,
                                  ),
                                ),
                                Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      '${(score * _animController.value).toInt()}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 22,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    const Text(
                                      '%',
                                      style: TextStyle(
                                        color: Colors.white60,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Umumiy KPI ball',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              score >= 80
                                  ? 'A\'lo natija! 🎉'
                                  : score >= 60
                                  ? 'Yaxshi natija 👍'
                                  : 'Rivojlanish kerak',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: List.generate(
                                _categories.length,
                                (i) => _ScorePill(
                                  label: _categories[i].shortTitle,
                                  value: _categoryScore(i),
                                  color: _categories[i].color,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // KPI categories — backend (API) dan
            ...List.generate(_categories.length, (catIndex) {
              final cat = _categories[catIndex];
              return SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Category header
                      Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: cat.color.withAlpha(26),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(cat.icon, color: cat.color, size: 20),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            cat.title,
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '${_categoryScore(catIndex).toInt()}%',
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: cat.color,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // KPI items
                      Container(
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceLight,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(8),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: List.generate(cat.kpis.length, (kpiIndex) {
                            final kpi = cat.kpis[kpiIndex];
                            final animIndex = _animOffset(catIndex) + kpiIndex;
                            final safeIndex = animIndex.clamp(
                              0,
                              _progressAnimations.length - 1,
                            );
                            return _KpiItemTile(
                              kpi: kpi,
                              color: cat.color,
                              animation: _progressAnimations[safeIndex],
                              isLast: kpiIndex == cat.kpis.length - 1,
                            );
                          }),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),

            ],

            // Bottom padding
            const SliverToBoxAdapter(child: SizedBox(height: 40)),
          ],
        ),
      ),
    );
  }

  double _categoryScore(int catIndex) {
    final cat = _categories[catIndex];
    if (cat.kpis.isEmpty) return 0;
    double total = 0;
    for (final kpi in cat.kpis) {
      total += (kpi.value / kpi.target).clamp(0.0, 1.0) * 100;
    }
    return total / cat.kpis.length;
  }

  static String _monthName(int month) => const [
        'Yanvar', 'Fevral', 'Mart', 'Aprel', 'May', 'Iyun',
        'Iyul', 'Avgust', 'Sentabr', 'Oktabr', 'Noyabr', 'Dekabr',
      ][month - 1];
}

// ── Sub-widgets ────────────────────────────────────────────────────────────────

class _ScorePill extends StatelessWidget {
  final String label;
  final double value;
  final Color color;

  const _ScorePill({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(26),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withAlpha(100)),
      ),
      child: Text(
        '$label ${value.toInt()}%',
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _KpiItemTile extends StatelessWidget {
  final _KpiItem kpi;
  final Color color;
  final Animation<double> animation;
  final bool isLast;

  const _KpiItemTile({
    required this.kpi,
    required this.color,
    required this.animation,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ratio = (kpi.value / kpi.target).clamp(0.0, 1.0);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      kpi.label,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${kpi.value} ${kpi.unit}',
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: color,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '/ ${kpi.target} ${kpi.unit}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              AnimatedBuilder(
                animation: animation,
                builder: (context, _) {
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: ratio * animation.value,
                      minHeight: 7,
                      backgroundColor: color.withAlpha(26),
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    ),
                  );
                },
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${(ratio * 100).toInt()}% bajarildi',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (kpi.trend != 0)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          kpi.isPositive
                              ? Icons.arrow_upward_rounded
                              : Icons.arrow_downward_rounded,
                          size: 11,
                          color: kpi.isPositive
                              ? AppTheme.success
                              : AppTheme.errorColor,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          '${kpi.trend > 0 ? '+' : ''}${kpi.trend}',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: kpi.isPositive
                                ? AppTheme.success
                                : AppTheme.errorColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ],
          ),
        ),
        if (!isLast)
          Divider(
            height: 1,
            thickness: 1,
            color: AppTheme.outlineLight,
            indent: 16,
            endIndent: 16,
          ),
      ],
    );
  }
}

// ── Data models ────────────────────────────────────────────────────────────────

class _KpiCategory {
  final String title;
  final IconData icon;
  final Color color;
  final List<_KpiItem> kpis;

  const _KpiCategory({
    required this.title,
    required this.icon,
    required this.color,
    required this.kpis,
  });

  /// Serverdagi `icon` va `color` kalitlarini ilova belgilariga bog'laydi.
  static const Map<String, IconData> _icons = {
    'trending': Icons.trending_up_rounded,
    'work': Icons.work_rounded,
    'groups': Icons.groups_rounded,
    'school': Icons.school_rounded,
    'star': Icons.star_rounded,
    'chart': Icons.bar_chart_rounded,
  };

  static const Map<String, Color> _colors = {
    'blue': AppTheme.cardBlue,
    'orange': AppTheme.cardOrange,
    'dark': AppTheme.cardDark,
    'green': AppTheme.cardGreen,
    'purple': AppTheme.cardPurple,
    'teal': AppTheme.cardTeal,
    'red': AppTheme.cardRed,
    'indigo': AppTheme.cardIndigo,
  };

  factory _KpiCategory.fromMap(Map<String, dynamic> map) => _KpiCategory(
        title: (map['title'] ?? '') as String,
        icon: _icons[map['icon']] ?? Icons.insights_rounded,
        color: _colors[map['color']] ?? AppTheme.primary,
        kpis: ((map['kpis'] as List?) ?? const [])
            .map((e) => _KpiItem.fromMap(Map<String, dynamic>.from(e as Map)))
            .toList(),
      );

  /// Umumiy kartadagi qisqa yorliq (birinchi so'z).
  String get shortTitle => title.split(' ').first;
}

class _KpiItem {
  final String label;
  final double value;
  final double target;
  final String unit;
  final num trend;
  final bool isPositive;

  const _KpiItem({
    required this.label,
    required this.value,
    required this.target,
    required this.unit,
    required this.trend,
    required this.isPositive,
  });

  factory _KpiItem.fromMap(Map<String, dynamic> map) => _KpiItem(
        label: (map['label'] ?? '') as String,
        value: (map['value'] as num?)?.toDouble() ?? 0,
        target: (map['target'] as num?)?.toDouble() ?? 100,
        unit: (map['unit'] ?? '%') as String,
        trend: (map['trend'] as num?) ?? 0,
        isPositive: map['isPositive'] == true,
      );
}
