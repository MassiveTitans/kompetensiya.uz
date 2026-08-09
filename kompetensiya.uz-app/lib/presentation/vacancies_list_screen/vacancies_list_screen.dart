import 'package:flutter/material.dart';

import '../../core/api_service.dart';
import '../../theme/app_theme.dart';
import './widgets/vacancies_page_title_widget.dart';
import './widgets/vacancy_card_widget.dart';
import './widgets/vacancy_filter_chips_widget.dart';
import './widgets/vacancy_search_bar_widget.dart';

class VacanciesListScreen extends StatefulWidget {
  const VacanciesListScreen({super.key});

  @override
  State<VacanciesListScreen> createState() => _VacanciesListScreenState();
}

class _VacanciesListScreenState extends State<VacanciesListScreen> {
  String _searchQuery = '';
  String _selectedFilter = 'Barchasi';
  bool _isLoading = true;
  String? _error;

  List<Map<String, dynamic>> _vacancyMaps = [];

  @override
  void initState() {
    super.initState();
    _loadVacancies();
  }

  Future<void> _loadVacancies() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        ApiService.getList('/api/vacancies/'),
        ApiService.getMap('/api/vacancies/fields/'),
      ]);
      if (!mounted) return;
      final vacancies = results[0] as List<Map<String, dynamic>>;
      final filters = results[1] as Map<String, dynamic>;
      setState(() {
        _vacancyMaps = vacancies;
        // Filtrlar ham serverdagi soha ro'yxatidan olinadi.
        _filterOptions = List<String>.from(
          (filters['filters'] as List?) ?? const ['Barchasi'],
        );
        if (!_filterOptions.contains(_selectedFilter)) {
          _selectedFilter = 'Barchasi';
        }
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

  List<String> _filterOptions = ['Barchasi'];

  List<Map<String, dynamic>> get _filteredVacancies {
    return _vacancyMaps.where((v) {
      final matchesSearch =
          _searchQuery.isEmpty ||
          (v['position'] as String).toLowerCase().contains(
            _searchQuery.toLowerCase(),
          ) ||
          (v['company'] as String).toLowerCase().contains(
            _searchQuery.toLowerCase(),
          );
      final matchesFilter =
          _selectedFilter == 'Barchasi' ||
          v['field'] == _selectedFilter ||
          (_selectedFilter == 'Masofaviy' && v['workType'] == 'Masofaviy');
      return matchesSearch && matchesFilter;
    }).toList();
  }

  Future<void> _onRefresh() => _loadVacancies();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isTablet = MediaQuery.of(context).size.width >= 600;
    final filtered = _filteredVacancies;

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _onRefresh,
          color: AppTheme.primary,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            slivers: [
              // Page title
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: VacanciesPageTitleWidget(
                    onFilter: () => _showFilterSheet(context),
                  ),
                ),
              ),
              // Search bar
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: VacancySearchBarWidget(
                    onChanged: (q) => setState(() => _searchQuery = q),
                  ),
                ),
              ),
              // Filter chips
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(0, 16, 0, 0),
                  child: VacancyFilterChipsWidget(
                    filters: _filterOptions,
                    selected: _selectedFilter,
                    onSelected: (f) => setState(() => _selectedFilter = f),
                  ),
                ),
              ),
              // Count
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Row(
                    children: [
                      Text(
                        '${filtered.length} ta vakansiya',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () {},
                        child: Row(
                          children: [
                            Icon(
                              Icons.sort_rounded,
                              size: 16,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Saralash',
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Vacancy list or grid — backend (API) dan
              _isLoading
                  ? const SliverFillRemaining(
                      child: Center(child: CircularProgressIndicator()),
                    )
                  : _error != null
                  ? SliverFillRemaining(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.wifi_off_rounded,
                              size: 64,
                              color: theme.colorScheme.outline,
                            ),
                            const SizedBox(height: 16),
                            Text(_error!, style: theme.textTheme.titleMedium),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _loadVacancies,
                              child: const Text('Qayta urinish'),
                            ),
                          ],
                        ),
                      ),
                    )
                  : filtered.isEmpty
                  ? SliverFillRemaining(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.work_off_outlined,
                              size: 64,
                              color: theme.colorScheme.outline,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Vakansiyalar topilmadi',
                              style: theme.textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Qidiruv so\'rovini o\'zgartiring\nyoki boshqa filtr tanlang',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    )
                  : isTablet
                  ? SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                      sliver: SliverGrid(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                              childAspectRatio: 1.5,
                            ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => VacancyCardWidget(
                            vacancyMap: filtered[index],
                            onApply: () =>
                                _showApplySheet(context, filtered[index]),
                          ),
                          childCount: filtered.length,
                        ),
                      ),
                    )
                  : SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate((context, index) {
                          return TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0.0, end: 1.0),
                            duration: Duration(
                              milliseconds: 250 + (index * 50).clamp(0, 350),
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
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: VacancyCardWidget(
                                vacancyMap: filtered[index],
                                onApply: () =>
                                    _showApplySheet(context, filtered[index]),
                              ),
                            ),
                          );
                        }, childCount: filtered.length),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFilterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => _FilterBottomSheet(
        filters: _filterOptions,
        selected: _selectedFilter,
        onSelected: (f) {
          setState(() => _selectedFilter = f);
          Navigator.pop(context);
        },
      ),
    );
  }

  void _showApplySheet(BuildContext context, Map<String, dynamic> vacancy) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => _ApplyBottomSheet(vacancy: vacancy),
    );
  }
}

class _FilterBottomSheet extends StatelessWidget {
  final List<String> filters;
  final String selected;
  final ValueChanged<String> onSelected;

  const _FilterBottomSheet({
    required this.filters,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.outline,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text('Soha bo\'yicha filtrlash', style: theme.textTheme.titleLarge),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: filters
                .map(
                  (f) => GestureDetector(
                    onTap: () => onSelected(f),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: f == selected
                            ? AppTheme.primary
                            : AppTheme.surfaceVariantLight,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        f,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: f == selected
                              ? Colors.white
                              : theme.colorScheme.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _ApplyBottomSheet extends StatefulWidget {
  final Map<String, dynamic> vacancy;
  const _ApplyBottomSheet({required this.vacancy});

  @override
  State<_ApplyBottomSheet> createState() => _ApplyBottomSheetState();
}

class _ApplyBottomSheetState extends State<_ApplyBottomSheet> {
  bool _isSubmitting = false;
  bool _submitted = false;

  Future<void> _submit() async {
    setState(() => _isSubmitting = true);
    await Future.delayed(const Duration(milliseconds: 1200));
    if (mounted) {
      setState(() {
        _isSubmitting = false;
        _submitted = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final v = widget.vacancy;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.outline,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          const SizedBox(height: 20),
          if (_submitted) ...[
            const Icon(
              Icons.check_circle_rounded,
              size: 64,
              color: AppTheme.success,
            ),
            const SizedBox(height: 16),
            Text(
              'Ariza yuborildi!',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${v['company']} kompaniyasiga ariza muvaffaqiyatli yuborildi. Ular siz bilan bog\'lanishadi.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Yopish'),
              ),
            ),
          ] else ...[
            Text(
              'Ariza topshirish',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${v['position']} — ${v['company']}',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primaryContainer.withAlpha(128),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    size: 18,
                    color: AppTheme.primary,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'ONE ID ma\'lumotlaringiz avtomatik ravishda ariza bilan birga yuboriladi.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.secondary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Ariza topshirish',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
