import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/api_service.dart';
import '../../theme/app_theme.dart';
import '../../routes/app_routes.dart';
import './widgets/assessment_card_widget.dart';

class AssessmentScreen extends StatefulWidget {
  const AssessmentScreen({super.key});

  @override
  State<AssessmentScreen> createState() => _AssessmentScreenState();
}

class _AssessmentScreenState extends State<AssessmentScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  List<Map<String, dynamic>> _skillAssessments = [];
  List<Map<String, dynamic>> _psychAssessments = [];
  bool _isLoading = true;
  String? _error;

  Future<void> _loadAssessments() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        ApiService.getList('/api/assessments/', query: {'kind': 'skill'}),
        ApiService.getList('/api/assessments/', query: {'kind': 'psych'}),
      ]);
      if (!mounted) return;
      setState(() {
        _skillAssessments = results[0];
        _psychAssessments = results[1];
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Testlarni yuklab bo\'lmadi';
        _isLoading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadAssessments();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  int get _completedSkill =>
      _skillAssessments.where((a) => a['isCompleted'] == true).length;
  int get _completedPsych =>
      _psychAssessments.where((a) => a['isCompleted'] == true).length;

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
                        'Baholash',
                        style: theme.textTheme.displaySmall?.copyWith(
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Ko\'nikmalar va psixologik testlar',
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
                      color: AppTheme.surfaceLight,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(13),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.bar_chart_rounded,
                      color: AppTheme.primary,
                      size: 22,
                    ),
                  ),
                ],
              ),
            ),

            // Summary banner
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1565C0), Color(0xFF1E88E5)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Mening natijalarim',
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${_completedSkill + _completedPsych} ta test yakunlandi',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _SummaryChip(
                      label: 'Ko\'nikma',
                      value: '$_completedSkill/${_skillAssessments.length}',
                    ),
                    const SizedBox(width: 8),
                    _SummaryChip(
                      label: 'Psixologik',
                      value: '$_completedPsych/${_psychAssessments.length}',
                    ),
                  ],
                ),
              ),
            ),

            // Tab bar
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Container(
                height: 44,
                decoration: BoxDecoration(
                  color: AppTheme.surfaceVariantLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    color: AppTheme.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  labelColor: Colors.white,
                  unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
                  labelStyle: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                  tabs: const [
                    Tab(text: 'Ko\'nikma baholash'),
                    Tab(text: 'Psixologik test'),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Tab content — backend (API) dan
            if (_isLoading)
              const Expanded(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.wifi_off_rounded,
                        size: 56,
                        color: theme.colorScheme.outline,
                      ),
                      const SizedBox(height: 12),
                      Text(_error!, style: theme.textTheme.titleMedium),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadAssessments,
                        child: const Text('Qayta urinish'),
                      ),
                    ],
                  ),
                ),
              )
            else
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Skill Assessment tab
                  _AssessmentList(
                    assessments: _skillAssessments,
                    emptyMessage: 'Ko\'nikma testlari mavjud emas',
                    sectionIcon: Icons.psychology_alt_outlined,
                    sectionColor: AppTheme.primary,
                    sectionTitle: 'Kasbiy ko\'nikmalar',
                    sectionSubtitle:
                        'Texnik va kasbiy bilimlaringizni sinab ko\'ring',
                    isPsychological: false,
                  ),
                  // Psychological Assessment tab
                  _AssessmentList(
                    assessments: _psychAssessments,
                    emptyMessage: 'Psixologik testlar mavjud emas',
                    sectionIcon: Icons.self_improvement_rounded,
                    sectionColor: AppTheme.cardPurple,
                    sectionTitle: 'Shaxsiy rivojlanish',
                    sectionSubtitle: 'O\'zingizni yaxshiroq tushunib oling',
                    isPsychological: true,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AssessmentList extends StatelessWidget {
  final List<Map<String, dynamic>> assessments;
  final String emptyMessage;
  final IconData sectionIcon;
  final Color sectionColor;
  final String sectionTitle;
  final String sectionSubtitle;
  final bool isPsychological;

  const _AssessmentList({
    required this.assessments,
    required this.emptyMessage,
    required this.sectionIcon,
    required this.sectionColor,
    required this.sectionTitle,
    required this.sectionSubtitle,
    this.isPsychological = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
      physics: const BouncingScrollPhysics(),
      children: [
        // Section info card
        Container(
          padding: const EdgeInsets.all(14),
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: sectionColor.withAlpha(15),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: sectionColor.withAlpha(40), width: 1),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: sectionColor.withAlpha(25),
                  shape: BoxShape.circle,
                ),
                child: Icon(sectionIcon, color: sectionColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sectionTitle,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: sectionColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      sectionSubtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        // Assessment cards
        ...assessments.map(
          (a) => AssessmentCardWidget(
            assessment: a,
            onTap: () => context.push(
              AppRoutes.testScreen,
              extra: {'assessment': a, 'isPsychological': isPsychological},
            ),
          ),
        ),
      ],
    );
  }
}

class _SummaryChip extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(40),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 9,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
