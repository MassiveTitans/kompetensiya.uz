import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/api_service.dart';
import '../../theme/app_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Data models
// ─────────────────────────────────────────────────────────────────────────────

/// Savol — barcha savollar backend (ma'lumotlar bazasi) dan olinadi.
class TestQuestion {
  final int id;
  final String question;
  final List<String> options;
  final List<int> optionIds;
  final int correctIndex; // -1 for psychological (no wrong answer)

  const TestQuestion({
    required this.id,
    required this.question,
    required this.options,
    required this.optionIds,
    this.correctIndex = -1,
  });

  factory TestQuestion.fromMap(Map<String, dynamic> map) => TestQuestion(
        id: (map['id'] as num?)?.toInt() ?? 0,
        question: (map['question'] ?? '') as String,
        options: List<String>.from((map['options'] as List?) ?? const []),
        optionIds: ((map['optionIds'] as List?) ?? const [])
            .map((e) => (e as num).toInt())
            .toList(),
        correctIndex: (map['correctIndex'] as num?)?.toInt() ?? -1,
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Main screen
// ─────────────────────────────────────────────────────────────────────────────

class TestScreen extends StatefulWidget {
  final Map<String, dynamic> assessment;
  final bool isPsychological;

  const TestScreen({
    super.key,
    required this.assessment,
    required this.isPsychological,
  });

  @override
  State<TestScreen> createState() => _TestScreenState();
}

class _TestScreenState extends State<TestScreen>
    with SingleTickerProviderStateMixin {
  List<TestQuestion> _questions = [];
  int _currentIndex = 0;
  int? _selectedOption;
  final List<int?> _answers = [];
  bool _isFinished = false;
  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _error;
  double? _serverScore;
  int _secondsLeft = 0;
  Timer? _timer;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  int get _assessmentId => (widget.assessment['id'] as num?)?.toInt() ?? 0;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(begin: const Offset(0.06, 0), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
        );

    _loadQuestions();
  }

  /// Savollar ma'lumotlar bazasidan olinadi.
  Future<void> _loadQuestions() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final data = await ApiService.getList(
        '/api/assessments/$_assessmentId/questions/',
      );
      if (!mounted) return;
      final questions = data.map(TestQuestion.fromMap).toList();
      setState(() {
        _questions = questions;
        _answers
          ..clear()
          ..addAll(List.filled(questions.length, null));
        _secondsLeft = _parseDuration(
          widget.assessment['duration'] ?? '10 daqiqa',
        );
        _isLoading = false;
      });
      if (questions.isNotEmpty) {
        _animController.forward();
        _startTimer();
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _isLoading = false;
      });
    }
  }

  int _parseDuration(String s) {
    final match = RegExp(r'(\d+)').firstMatch(s);
    return (int.tryParse(match?.group(1) ?? '10') ?? 10) * 60;
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      if (_secondsLeft > 0) {
        setState(() => _secondsLeft--);
      } else {
        _finishTest();
      }
    });
  }

  void _selectOption(int idx) {
    if (_selectedOption != null) return;
    setState(() {
      _selectedOption = idx;
      _answers[_currentIndex] = idx;
    });
  }

  void _nextQuestion() {
    if (_currentIndex < _questions.length - 1) {
      setState(() {
        _currentIndex++;
        _selectedOption = _answers[_currentIndex];
      });
      _animController.reset();
      _animController.forward();
    } else {
      _finishTest();
    }
  }

  void _prevQuestion() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
        _selectedOption = _answers[_currentIndex];
      });
      _animController.reset();
      _animController.forward();
    }
  }

  /// Testni yakunlaydi va javoblarni serverga yuboradi — natija bazaga yoziladi.
  Future<void> _finishTest() async {
    if (_isFinished) return;
    _timer?.cancel();
    setState(() {
      _isFinished = true;
      _isSubmitting = true;
    });

    final payload = <String, dynamic>{};
    for (int i = 0; i < _questions.length; i++) {
      final picked = _answers[i];
      final q = _questions[i];
      if (picked != null && picked < q.optionIds.length) {
        payload['${q.id}'] = q.optionIds[picked];
      }
    }

    try {
      final result = await ApiService.post(
        '/api/assessments/$_assessmentId/submit/',
        body: {'answers': payload},
      );
      if (!mounted) return;
      setState(() {
        _serverScore = (result['score'] as num?)?.toDouble();
        _isSubmitting = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _error = e.isUnauthorized
            ? 'Natijani saqlash uchun ONE ID orqali kiring.'
            : e.message;
      });
    }
  }

  /// Natija serverda hisoblanadi; javob kelmaguncha lokal hisob ko'rsatiladi.
  double get _score {
    if (_serverScore != null) return _serverScore!;
    if (_questions.isEmpty) return 0;
    if (widget.isPsychological) {
      final answered = _answers.where((a) => a != null).length;
      return (answered / _questions.length) * 100;
    }
    int correct = 0;
    for (int i = 0; i < _questions.length; i++) {
      if (_answers[i] == _questions[i].correctIndex) correct++;
    }
    return (correct / _questions.length) * 100;
  }

  int get _answeredCount => _answers.where((a) => a != null).length;

  String _formatTime(int s) {
    final m = s ~/ 60;
    final sec = s % 60;
    return '${m.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
  }

  Color get _timerColor {
    if (_secondsLeft > 120) return AppTheme.success;
    if (_secondsLeft > 60) return AppTheme.warning;
    return AppTheme.errorColor;
  }

  @override
  void dispose() {
    _timer?.cancel();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: SafeArea(child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (!_isFinished && _error != null) {
      return _buildMessage(
        icon: Icons.wifi_off_rounded,
        title: 'Savollarni yuklab bo\'lmadi',
        message: _error!,
        onRetry: _loadQuestions,
      );
    }
    if (_questions.isEmpty) {
      return _buildMessage(
        icon: Icons.quiz_outlined,
        title: 'Savollar kiritilmagan',
        message: 'Bu test uchun ma\'lumotlar bazasida hali savollar yo\'q.',
      );
    }
    return _isFinished ? _buildResults() : _buildTest();
  }

  Widget _buildMessage({
    required IconData icon,
    required String title,
    required String message,
    VoidCallback? onRetry,
  }) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 52, color: theme.colorScheme.outline),
            const SizedBox(height: 16),
            Text(title, style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            if (onRetry != null)
              ElevatedButton(
                onPressed: onRetry,
                child: const Text('Qayta urinish'),
              ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Orqaga'),
            ),
          ],
        ),
      ),
    );
  }

  // ── Test view ──────────────────────────────────────────────────────────────

  Widget _buildTest() {
    final theme = Theme.of(context);
    final q = _questions[_currentIndex];
    final progress = (_currentIndex + 1) / _questions.length;
    final accent = widget.isPsychological
        ? AppTheme.cardPurple
        : AppTheme.primary;

    return Column(
      children: [
        // ── Header ──
        Container(
          color: AppTheme.surfaceLight,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Column(
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: () => _showExitDialog(),
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: AppTheme.backgroundLight,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.close_rounded,
                        size: 20,
                        color: Color(0xFF5A6478),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.assessment['title'] ?? '',
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: theme.colorScheme.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${_currentIndex + 1} / ${_questions.length} savol',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Timer
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _timerColor.withAlpha(20),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _timerColor.withAlpha(60)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.timer_outlined,
                          size: 14,
                          color: _timerColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatTime(_secondsLeft),
                          style: TextStyle(
                            color: _timerColor,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Progress bar
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 6,
                  backgroundColor: AppTheme.outlineLight,
                  valueColor: AlwaysStoppedAnimation<Color>(accent),
                ),
              ),
            ],
          ),
        ),

        // ── Question + options ──
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            physics: const BouncingScrollPhysics(),
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Question number badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: accent.withAlpha(20),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        widget.isPsychological
                            ? 'Savol ${_currentIndex + 1}'
                            : 'Savol ${_currentIndex + 1}',
                        style: TextStyle(
                          color: accent,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    // Question text
                    Text(
                      q.question,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: theme.colorScheme.onSurface,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Options
                    ...List.generate(q.options.length, (i) {
                      return _OptionTile(
                        label: _optionLabel(i),
                        text: q.options[i],
                        state: _optionState(i, q),
                        accent: accent,
                        isPsychological: widget.isPsychological,
                        onTap: () => _selectOption(i),
                      );
                    }),
                    const SizedBox(height: 16),
                    // Hint for psychological
                    if (widget.isPsychological)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.cardPurple.withAlpha(10),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppTheme.cardPurple.withAlpha(30),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline_rounded,
                              size: 16,
                              color: AppTheme.cardPurple,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Bu testda to\'g\'ri yoki noto\'g\'ri javob yo\'q. O\'zingizga eng mos javobni tanlang.',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: AppTheme.cardPurple,
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
        ),

        // ── Navigation buttons ──
        Container(
          color: AppTheme.surfaceLight,
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Row(
            children: [
              if (_currentIndex > 0)
                Expanded(
                  flex: 1,
                  child: OutlinedButton(
                    onPressed: _prevQuestion,
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: AppTheme.outlineLight),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Icon(Icons.arrow_back_rounded, size: 20),
                  ),
                ),
              if (_currentIndex > 0) const SizedBox(width: 12),
              Expanded(
                flex: 3,
                child: ElevatedButton(
                  onPressed: _selectedOption != null ? _nextQuestion : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accent,
                    disabledBackgroundColor: AppTheme.outlineLight,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 0,
                  ),
                  child: Text(
                    _currentIndex == _questions.length - 1
                        ? 'Yakunlash'
                        : 'Keyingisi',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  _OptionState _optionState(int i, TestQuestion q) {
    if (_selectedOption == null) return _OptionState.idle;
    if (i == _selectedOption) {
      if (widget.isPsychological) return _OptionState.selected;
      return i == q.correctIndex ? _OptionState.correct : _OptionState.wrong;
    }
    if (!widget.isPsychological &&
        i == q.correctIndex &&
        _selectedOption != null) {
      return _OptionState.correct;
    }
    return _OptionState.idle;
  }

  String _optionLabel(int i) {
    const labels = ['A', 'B', 'C', 'D'];
    return labels[i % labels.length];
  }

  void _showExitDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Testni tark etish?'),
        content: Text(
          'Natijalaringiz saqlanmaydi. Davom etishni xohlaysizmi?',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Davom etish'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: Text(
              'Chiqish',
              style: TextStyle(color: AppTheme.errorColor),
            ),
          ),
        ],
      ),
    );
  }

  // ── Results view ───────────────────────────────────────────────────────────

  Widget _buildResults() {
    final theme = Theme.of(context);
    final score = _score;
    final accent = widget.isPsychological
        ? AppTheme.cardPurple
        : AppTheme.primary;
    final answered = _answeredCount;
    final total = _questions.length;

    String resultTitle;
    String resultDesc;
    Color resultColor;
    IconData resultIcon;

    if (widget.isPsychological) {
      resultTitle = 'Tahlil tayyor!';
      resultDesc = 'Javoblaringiz asosida shaxsiy profilingiz tayyorlandi.';
      resultColor = AppTheme.cardPurple;
      resultIcon = Icons.psychology_outlined;
    } else if (score >= 80) {
      resultTitle = 'Ajoyib natija!';
      resultDesc = 'Siz bu sohada yuqori bilimga egasiz.';
      resultColor = AppTheme.success;
      resultIcon = Icons.emoji_events_rounded;
    } else if (score >= 60) {
      resultTitle = 'Yaxshi natija!';
      resultDesc = 'Bilimlaringiz yaxshi, lekin yaxshilash imkoniyati bor.';
      resultColor = AppTheme.warning;
      resultIcon = Icons.thumb_up_alt_outlined;
    } else {
      resultTitle = 'Harakat qiling!';
      resultDesc = 'Bilimlaringizni mustahkamlash uchun ko\'proq mashq qiling.';
      resultColor = AppTheme.errorColor;
      resultIcon = Icons.refresh_rounded;
    }

    return Column(
      children: [
        // Top bar
        Container(
          color: AppTheme.surfaceLight,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppTheme.backgroundLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.arrow_back_rounded,
                    size: 20,
                    color: Color(0xFF5A6478),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Test natijalari',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),

        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                // Natijani bazaga saqlash holati
                if (_isSubmitting)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 10),
                        Text('Natija saqlanmoqda…'),
                      ],
                    ),
                  )
                else if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.errorColor,
                      ),
                    ),
                  ),
                // Score card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [accent, accent.withAlpha(200)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(30),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(resultIcon, color: Colors.white, size: 36),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        resultTitle,
                        style: theme.textTheme.headlineMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        resultDesc,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withAlpha(210),
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Score circle
                      Container(
                        width: 110,
                        height: 110,
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(25),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withAlpha(80),
                            width: 3,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '${score.toInt()}%',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              'Ball',
                              style: TextStyle(
                                color: Colors.white.withAlpha(180),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Stats row
                Row(
                  children: [
                    _StatCard(
                      icon: Icons.check_circle_outline_rounded,
                      label: 'Javob berildi',
                      value: '$answered/$total',
                      color: AppTheme.success,
                    ),
                    const SizedBox(width: 12),
                    _StatCard(
                      icon: Icons.timer_outlined,
                      label: 'Sarflangan vaqt',
                      value: _formatTime(
                        _parseDuration(
                              widget.assessment['duration'] ?? '10 daqiqa',
                            ) -
                            _secondsLeft,
                      ),
                      color: AppTheme.primary,
                    ),
                    if (!widget.isPsychological) ...[
                      const SizedBox(width: 12),
                      _StatCard(
                        icon: Icons.close_rounded,
                        label: 'Noto\'g\'ri',
                        value: '${answered - _correctCount}',
                        color: AppTheme.errorColor,
                      ),
                    ],
                  ],
                ),

                const SizedBox(height: 20),

                // Answer review
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceLight,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(8),
                        blurRadius: 12,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Javoblar sharhi',
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 14),
                      // Mini progress dots
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: List.generate(_questions.length, (i) {
                          final ans = _answers[i];
                          Color dotColor;
                          if (ans == null) {
                            dotColor = AppTheme.outlineLight;
                          } else if (widget.isPsychological) {
                            dotColor = accent;
                          } else if (ans == _questions[i].correctIndex) {
                            dotColor = AppTheme.success;
                          } else {
                            dotColor = AppTheme.errorColor;
                          }
                          return Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: dotColor.withAlpha(20),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: dotColor.withAlpha(80)),
                            ),
                            child: Center(
                              child: Text(
                                '${i + 1}',
                                style: TextStyle(
                                  color: dotColor,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _LegendDot(
                            color: widget.isPsychological
                                ? accent
                                : AppTheme.success,
                            label: widget.isPsychological
                                ? 'Javob berildi'
                                : 'To\'g\'ri',
                          ),
                          if (!widget.isPsychological) ...[
                            const SizedBox(width: 16),
                            _LegendDot(
                              color: AppTheme.errorColor,
                              label: 'Noto\'g\'ri',
                            ),
                          ],
                          const SizedBox(width: 16),
                          _LegendDot(
                            color: AppTheme.outlineLight,
                            label: 'Javob berilmadi',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Action buttons
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Baholash sahifasiga qaytish',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _currentIndex = 0;
                        _selectedOption = null;
                        _answers.fillRange(0, _answers.length, null);
                        _isFinished = false;
                        _secondsLeft = _parseDuration(
                          widget.assessment['duration'] ?? '10 daqiqa',
                        );
                      });
                      _startTimer();
                    },
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: accent.withAlpha(80)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(
                      'Qayta topshirish',
                      style: TextStyle(
                        color: accent,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }

  int get _correctCount {
    int c = 0;
    for (int i = 0; i < _questions.length; i++) {
      if (_answers[i] == _questions[i].correctIndex) c++;
    }
    return c;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Helper widgets
// ─────────────────────────────────────────────────────────────────────────────

enum _OptionState { idle, selected, correct, wrong }

class _OptionTile extends StatelessWidget {
  final String label;
  final String text;
  final _OptionState state;
  final Color accent;
  final bool isPsychological;
  final VoidCallback onTap;

  const _OptionTile({
    required this.label,
    required this.text,
    required this.state,
    required this.accent,
    required this.isPsychological,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Color bg, border, labelBg, labelFg, textColor;
    Widget? trailingIcon;

    switch (state) {
      case _OptionState.correct:
        bg = AppTheme.successContainer;
        border = AppTheme.success;
        labelBg = AppTheme.success;
        labelFg = Colors.white;
        textColor = AppTheme.success;
        trailingIcon = const Icon(
          Icons.check_circle_rounded,
          color: AppTheme.success,
          size: 20,
        );
        break;
      case _OptionState.wrong:
        bg = AppTheme.errorContainer;
        border = AppTheme.errorColor;
        labelBg = AppTheme.errorColor;
        labelFg = Colors.white;
        textColor = AppTheme.errorColor;
        trailingIcon = const Icon(
          Icons.cancel_rounded,
          color: AppTheme.errorColor,
          size: 20,
        );
        break;
      case _OptionState.selected:
        bg = accent.withAlpha(15);
        border = accent;
        labelBg = accent;
        labelFg = Colors.white;
        textColor = accent;
        trailingIcon = Icon(
          Icons.radio_button_checked_rounded,
          color: accent,
          size: 20,
        );
        break;
      case _OptionState.idle:
      default:
        bg = AppTheme.surfaceLight;
        border = AppTheme.outlineLight;
        labelBg = AppTheme.surfaceVariantLight;
        labelFg = theme.colorScheme.onSurfaceVariant;
        textColor = theme.colorScheme.onSurface;
        trailingIcon = null;
    }

    return GestureDetector(
      onTap: state == _OptionState.idle ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: border,
            width: state == _OptionState.idle ? 1 : 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: labelBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  label,
                  style: TextStyle(
                    color: labelFg,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: textColor,
                  fontWeight: state != _OptionState.idle
                      ? FontWeight.w600
                      : FontWeight.w400,
                ),
              ),
            ),
            if (trailingIcon != null) ...[
              const SizedBox(width: 8),
              trailingIcon,
            ],
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.surfaceLight,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(8),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withAlpha(20),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              textAlign: TextAlign.center,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
