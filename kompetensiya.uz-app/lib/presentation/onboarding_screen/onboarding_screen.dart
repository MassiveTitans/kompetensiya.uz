import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sizer/sizer.dart';

import '../../routes/app_routes.dart';
import '../../theme/app_theme.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  late AnimationController _contentController;
  late Animation<double> _contentFade;
  late Animation<Offset> _contentSlide;

  final List<_OnboardingData> _pages = const [
    _OnboardingData(
      icon: Icons.work_outline_rounded,
      accentColor: Color(0xFFF57C00),
      bgColor: Color(0xFFFFF3E0),
      gradientStart: Color(0xFFFF8F00),
      gradientEnd: Color(0xFFF57C00),
      title: 'Vakansiyalar',
      subtitle: 'Orzuingizdagi ish topish',
      description:
          "O'zbekistondagi eng yaxshi kompaniyalarning ish o'rinlarini ko'ring. Maosh, joylashuv va soha bo'yicha filtrlang — bir marta bosib ariza topshiring.",
      illustrationEmoji: '💼',
      featureItems: ['Minglab ish o\'rinlari', 'Tezkor ariza', 'Maosh filtri'],
    ),
    _OnboardingData(
      icon: Icons.school_outlined,
      accentColor: Color(0xFF1565C0),
      bgColor: Color(0xFFD6E4FF),
      gradientStart: Color(0xFF1E88E5),
      gradientEnd: Color(0xFF1565C0),
      title: 'Kurslar',
      subtitle: 'Bilimingizni oshiring',
      description:
          'Kasbiy rivojlanish uchun maxsus tayyorlangan kurslar. Sertifikat oling, yangi ko\'nikmalar egallang va karyerangizni yangi bosqichga olib chiqing.',
      illustrationEmoji: '🎓',
      featureItems: [
        'Sertifikatli kurslar',
        'Online format',
        'Ekspert o\'qituvchilar',
      ],
    ),
    _OnboardingData(
      icon: Icons.people_outline_rounded,
      accentColor: Color(0xFF00695C),
      bgColor: Color(0xFFE0F2F1),
      gradientStart: Color(0xFF00897B),
      gradientEnd: Color(0xFF00695C),
      title: 'Hamjamiyat',
      subtitle: 'Birgalikda o\'sish',
      description:
          'Loyihalar, tadbirlar va professional hamjamiyat bilan bog\'laning. Tajriba almashing, yangi aloqalar o\'rnating va birgalikda muvaffaqiyatga erishing.',
      illustrationEmoji: '🤝',
      featureItems: ['Tadbirlar va meetuplar', 'Loyihalar', 'Mentorlik'],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _contentController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _contentFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _contentController, curve: Curves.easeOut),
    );
    _contentSlide = Tween<Offset>(begin: const Offset(0.1, 0), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _contentController,
            curve: Curves.easeOutCubic,
          ),
        );
    _contentController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _onPageChanged(int page) {
    setState(() => _currentPage = page);
    _contentController.reset();
    _contentController.forward();
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    } else {
      context.go(AppRoutes.loginScreen);
    }
  }

  void _skip() {
    context.go(AppRoutes.loginScreen);
  }

  @override
  Widget build(BuildContext context) {
    final currentData = _pages[_currentPage];
    final isLast = _currentPage == _pages.length - 1;

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: Stack(
        children: [
          // Animated background
          AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  currentData.bgColor.withAlpha(180),
                  AppTheme.backgroundLight,
                ],
                stops: const [0.0, 0.55],
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                // Top bar
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 5.w,
                    vertical: 1.5.h,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Page indicator dots
                      Row(
                        children: List.generate(_pages.length, (i) {
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                            margin: const EdgeInsets.only(right: 6),
                            width: i == _currentPage ? 24.0 : 8.0,
                            height: 8.0,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(4.0),
                              color: i == _currentPage
                                  ? currentData.accentColor
                                  : currentData.accentColor.withAlpha(60),
                            ),
                          );
                        }),
                      ),
                      // Skip button
                      TextButton(
                        onPressed: _skip,
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          'O\'tkazib yuborish',
                          style: TextStyle(
                            fontSize: 12.sp > 12 ? 12 : 12.sp,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.primary.withAlpha(160),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // PageView
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: _onPageChanged,
                    itemCount: _pages.length,
                    itemBuilder: (context, index) {
                      return _OnboardingPage(
                        data: _pages[index],
                        contentFade: _contentFade,
                        contentSlide: _contentSlide,
                        isActive: index == _currentPage,
                      );
                    },
                  ),
                ),

                // Bottom CTA
                Padding(
                  padding: EdgeInsets.fromLTRB(5.w, 0, 5.w, 4.h),
                  child: Column(
                    children: [
                      // Main CTA button
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _nextPage,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isLast
                                ? AppTheme.secondary
                                : currentData.accentColor,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16.0),
                            ),
                            padding: EdgeInsets.symmetric(vertical: 1.8.h),
                            textStyle: TextStyle(
                              fontSize: 14.sp > 14 ? 14 : 14.sp,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(isLast ? 'Boshlash' : 'Keyingisi'),
                              const SizedBox(width: 8),
                              Icon(
                                isLast
                                    ? Icons.rocket_launch_rounded
                                    : Icons.arrow_forward_rounded,
                                size: 18,
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (isLast) ...[
                        SizedBox(height: 1.2.h),
                        GestureDetector(
                          onTap: _skip,
                          child: Text(
                            'Allaqachon hisobim bor',
                            style: TextStyle(
                              fontSize: 12.sp > 12 ? 12 : 12.sp,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.primary,
                              decoration: TextDecoration.underline,
                              decorationColor: AppTheme.primary,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  final _OnboardingData data;
  final Animation<double> contentFade;
  final Animation<Offset> contentSlide;
  final bool isActive;

  const _OnboardingPage({
    required this.data,
    required this.contentFade,
    required this.contentSlide,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 5.w),
      child: Column(
        children: [
          SizedBox(height: 2.h),
          // Illustration card
          Expanded(
            flex: 5,
            child: FadeTransition(
              opacity: contentFade,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [data.gradientStart, data.gradientEnd],
                  ),
                  borderRadius: BorderRadius.circular(28.0),
                  boxShadow: [
                    BoxShadow(
                      color: data.accentColor.withAlpha(60),
                      blurRadius: 32,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    // Decorative circles
                    Positioned(
                      top: -20,
                      right: -20,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withAlpha(20),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: -30,
                      left: -30,
                      child: Container(
                        width: 160,
                        height: 160,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withAlpha(15),
                        ),
                      ),
                    ),
                    // Center content
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Emoji illustration
                          Container(
                            width: 22.w,
                            height: 22.w,
                            decoration: BoxDecoration(
                              color: Colors.white.withAlpha(30),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                data.illustrationEmoji,
                                style: TextStyle(
                                  fontSize: 18.w > 18 ? 18 : 18.w,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: 2.h),
                          // Feature pills
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            alignment: WrapAlignment.center,
                            children: data.featureItems.map((item) {
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 7,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withAlpha(30),
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(
                                    color: Colors.white.withAlpha(80),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.check_circle_rounded,
                                      size: 13,
                                      color: Colors.white.withAlpha(220),
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      item,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(height: 3.h),
          // Text content
          Expanded(
            flex: 3,
            child: SlideTransition(
              position: contentSlide,
              child: FadeTransition(
                opacity: contentFade,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Category label
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: data.accentColor.withAlpha(20),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(data.icon, size: 14, color: data.accentColor),
                          const SizedBox(width: 5),
                          Text(
                            data.title,
                            style: TextStyle(
                              fontSize: 11.sp > 11 ? 11 : 11.sp,
                              fontWeight: FontWeight.w700,
                              color: data.accentColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 1.2.h),
                    Text(
                      data.subtitle,
                      style: TextStyle(
                        fontSize: 20.sp > 20 ? 20 : 20.sp,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF1A1A2E),
                        letterSpacing: -0.5,
                        height: 1.2,
                      ),
                    ),
                    SizedBox(height: 1.h),
                    Text(
                      data.description,
                      style: TextStyle(
                        fontSize: 12.sp > 12 ? 12 : 12.sp,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF5A6478),
                        height: 1.55,
                      ),
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardingData {
  final IconData icon;
  final Color accentColor;
  final Color bgColor;
  final Color gradientStart;
  final Color gradientEnd;
  final String title;
  final String subtitle;
  final String description;
  final String illustrationEmoji;
  final List<String> featureItems;

  const _OnboardingData({
    required this.icon,
    required this.accentColor,
    required this.bgColor,
    required this.gradientStart,
    required this.gradientEnd,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.illustrationEmoji,
    required this.featureItems,
  });
}
