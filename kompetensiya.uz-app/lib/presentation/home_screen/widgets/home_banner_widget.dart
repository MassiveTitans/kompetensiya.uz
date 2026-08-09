import 'package:flutter/material.dart';

import '../../../core/app_export.dart';

class HomeBannerWidget extends StatefulWidget {
  const HomeBannerWidget({super.key});

  @override
  State<HomeBannerWidget> createState() => _HomeBannerWidgetState();
}

class _HomeBannerWidgetState extends State<HomeBannerWidget> {
  int _currentPage = 0;
  final PageController _pageController = PageController(viewportFraction: 0.92);

  // Bannerlar backend (ma'lumotlar bazasi) dan olinadi.
  List<Map<String, dynamic>> _banners = [];
  bool _isLoading = true;

  static const Map<String, Color> _colorMap = {
    'blue': AppTheme.primary,
    'orange': AppTheme.secondary,
    'green': Color(0xFF2E7D32),
    'purple': AppTheme.cardPurple,
    'teal': AppTheme.cardTeal,
    'indigo': AppTheme.cardIndigo,
    'red': AppTheme.errorColor,
    'dark': Color(0xFF1A1A2E),
  };

  @override
  void initState() {
    super.initState();
    _loadBanners();
  }

  Future<void> _loadBanners() async {
    try {
      final data = await ApiService.getList('/api/banners/');
      if (!mounted) return;
      setState(() {
        _banners = data;
        _isLoading = false;
      });
    } on ApiException {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return const SizedBox(
        height: 180,
        child: Center(child: CircularProgressIndicator()),
      );
    }
    // Bazada faol banner bo'lmasa, bo'sh joy egallanmaydi.
    if (_banners.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        SizedBox(
          height: 180,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (i) => setState(() => _currentPage = i),
            itemCount: _banners.length,
            itemBuilder: (context, index) {
              final banner = _banners[index];
              final color =
                  _colorMap[banner['accentColor']] ?? AppTheme.primary;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    color: color,
                    boxShadow: [
                      BoxShadow(
                        color: color.withAlpha(77),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Background image with overlay
                      Opacity(
                        opacity: 0.3,
                        child: CustomImageWidget(
                          imageUrl: banner['imageUrl'] as String,
                          width: double.infinity,
                          height: 180,
                          fit: BoxFit.cover,
                          semanticLabel: banner['semanticLabel'] as String,
                        ),
                      ),
                      // Gradient overlay
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              color.withAlpha(204),
                              color.withAlpha(102),
                            ],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                        ),
                      ),
                      // Content
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  banner['title'] as String,
                                  style: theme.textTheme.headlineMedium
                                      ?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w800,
                                        height: 1.15,
                                      ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  banner['subtitle'] as String,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: Colors.white.withAlpha(217),
                                  ),
                                ),
                              ],
                            ),
                            GestureDetector(
                              onTap: () {},
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  banner['ctaLabel'] as String,
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    color: color,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        // Page indicator dots
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            _banners.length,
            (i) => AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: i == _currentPage ? 20 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: i == _currentPage
                    ? AppTheme.primary
                    : AppTheme.primary.withAlpha(77),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
