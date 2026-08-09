import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/api_service.dart';
import '../../routes/app_routes.dart';
import '../../theme/app_theme.dart';
import './widgets/home_banner_widget.dart';
import './widgets/home_header_widget.dart';
import './widgets/home_page_title_widget.dart';
import './widgets/news_feed_widget.dart';
import './widgets/quick_access_widget.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Map<String, dynamic>> _newsMaps = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadNews();
  }

  Future<void> _loadNews() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final data = await ApiService.getList('/api/news/');
      if (!mounted) return;
      setState(() {
        _newsMaps = data;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Ma\'lumotlarni yuklab bo\'lmadi.\nInternet aloqasini tekshiring.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isTablet = MediaQuery.of(context).size.width >= 600;

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Fixed header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: const HomeHeaderWidget(),
              ),
            ),
            // Page title + filters
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: HomePageTitleWidget(
                  title: 'Yangiliklar\nva E\'lonlar',
                  onFilter: () {},
                ),
              ),
            ),
            // Quick access shortcuts
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: QuickAccessWidget(
                  onKurslar: () {},
                  onVakansiyalar: () =>
                      context.go(AppRoutes.vacanciesListScreen),
                ),
              ),
            ),
            // Banner carousel
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 20, 0, 0),
                child: const HomeBannerWidget(),
              ),
            ),
            // Section header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'So\'nggi yangiliklar',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    TextButton(
                      onPressed: () {},
                      child: Text(
                        'Barchasini ko\'rish',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: AppTheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // News feed — backend (API) dan
            if (_isLoading)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 60),
                  child: Center(child: CircularProgressIndicator()),
                ),
              )
            else if (_error != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 48),
                  child: Center(
                    child: Column(
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
                          onPressed: _loadNews,
                          child: const Text('Qayta urinish'),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else if (_newsMaps.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 48),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.newspaper_rounded,
                          size: 48,
                          color: theme.colorScheme.outline,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Hozircha yangiliklar yo\'q',
                          style: theme.textTheme.titleMedium,
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else if (isTablet)
              SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                    sliver: SliverGrid(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: 1.6,
                          ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) =>
                            NewsFeedCardWidget(newsMap: _newsMaps[index]),
                        childCount: _newsMaps.length,
                      ),
                    ),
                  )
            else
              SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
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
                                offset: Offset(0, 24 * (1 - value)),
                                child: child,
                              ),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: NewsFeedCardWidget(
                              newsMap: _newsMaps[index],
                            ),
                          ),
                        );
                      }, childCount: _newsMaps.length),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
