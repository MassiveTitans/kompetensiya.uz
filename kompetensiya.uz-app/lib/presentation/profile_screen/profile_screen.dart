import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/api_service.dart';
import '../../core/auth_service.dart';
import '../../routes/app_routes.dart';
import '../../theme/app_theme.dart';
import './widgets/profile_menu_item_widget.dart';

/// Profil ekrani — barcha ma'lumot `/api/me/` orqali bazadan olinadi.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _profile;
  bool _isLoading = true;
  String? _error;
  bool _needsLogin = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _needsLogin = false;
    });
    try {
      final data = await AuthService.refreshProfile();
      if (!mounted) return;
      setState(() {
        _profile = data;
        _isLoading = false;
        if (data == null) {
          _needsLogin = true;
          _error = 'Profilni ko\'rish uchun ONE ID orqali kiring.';
        }
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _needsLogin = e.isUnauthorized;
        _error = e.message;
      });
    }
  }

  String _text(String key, {String fallback = '—'}) {
    final value = _profile?[key];
    if (value is String && value.isNotEmpty) return value;
    return fallback;
  }

  int _count(String key) => (_profile?[key] as num?)?.toInt() ?? 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Profil',
                      style: theme.textTheme.displaySmall?.copyWith(
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    GestureDetector(
                      onTap: _loadProfile,
                      child: Container(
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
                          Icons.refresh_rounded,
                          color: AppTheme.primary,
                          size: 22,
                        ),
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
            else if (_profile == null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(28, 60, 28, 0),
                  child: Column(
                    children: [
                      Icon(
                        _needsLogin
                            ? Icons.lock_outline_rounded
                            : Icons.wifi_off_rounded,
                        size: 52,
                        color: theme.colorScheme.outline,
                      ),
                      const SizedBox(height: 14),
                      Text(
                        _error ?? 'Profil ma\'lumotlari yuklanmadi',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 18),
                      ElevatedButton(
                        onPressed: _needsLogin
                            ? () => context.go(AppRoutes.loginScreen)
                            : _loadProfile,
                        child: Text(
                          _needsLogin ? 'ONE ID orqali kirish' : 'Qayta urinish',
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else ...[
              _buildProfileCard(theme),
              _buildAttendanceSection(theme),
              _buildAccountMenu(theme),
              _buildSettingsMenu(theme),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 120),
                  child: ProfileMenuItemWidget(
                    icon: Icons.logout_rounded,
                    label: 'Tizimdan chiqish',
                    subtitle: 'ONE ID sessiyasini tugatish',
                    isDestructive: true,
                    onTap: () => _showLogoutDialog(context),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ── Profil kartasi ────────────────────────────────────────────────────────

  Widget _buildProfileCard(ThemeData theme) {
    final oneIdVerified = _profile?['oneIdVerified'] == true;

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
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
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 68,
                    height: 68,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppTheme.primary, AppTheme.primaryLight],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withAlpha(51),
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        _text('initials', fallback: '??'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _text('fullName'),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _text('email', fallback: _text('phone')),
                          style: const TextStyle(
                            color: Colors.white60,
                            fontSize: 13,
                          ),
                        ),
                        if (oneIdVerified) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withAlpha(26),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: Colors.white.withAlpha(51),
                              ),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.verified_rounded,
                                  size: 12,
                                  color: Color(0xFF64B5F6),
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'ONE ID orqali kirilgan',
                                  style: TextStyle(
                                    color: Color(0xFF64B5F6),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  _StatItem(
                    label: 'Kurslar',
                    value: '${_count('coursesCount')}',
                    color: AppTheme.primaryLight,
                  ),
                  _Divider(),
                  _StatItem(
                    label: 'Arizalar',
                    value: '${_count('applicationsCount')}',
                    color: AppTheme.secondary,
                  ),
                  _Divider(),
                  _StatItem(
                    label: 'Sertifikatlar',
                    value: '${_count('certificatesCount')}',
                    color: AppTheme.success,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Davomat holati ────────────────────────────────────────────────────────

  Widget _buildAttendanceSection(ThemeData theme) {
    final gps = _profile?['gpsToday'] as Map<String, dynamic>?;
    final checkedIn = gps?['checkedIn'] == true;
    final eventCount = _count('eventAttendanceCount');

    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
            child: Text(
              'Davomat holati',
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                letterSpacing: 0.8,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
            child: Row(
              children: [
                Expanded(
                  child: _AttendanceCard(
                    icon: Icons.location_on_rounded,
                    gradient: checkedIn
                        ? const [Color(0xFF1B5E20), Color(0xFF2E7D32)]
                        : const [Color(0xFF455A64), Color(0xFF607D8B)],
                    shadowColor: checkedIn
                        ? AppTheme.success
                        : const Color(0xFF607D8B),
                    title: checkedIn
                        ? (gps?['statusLabel'] as String? ?? 'ISHDA')
                            .toUpperCase()
                        : 'BELGILANMAGAN',
                    subtitle: 'GPS davomat',
                    badge: checkedIn
                        ? 'Bugun, ${gps?['checkIn'] ?? ''}'
                        : 'Bugun yo\'q',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _AttendanceCard(
                    icon: Icons.qr_code_rounded,
                    gradient: const [Color(0xFF0D47A1), Color(0xFF1565C0)],
                    shadowColor: AppTheme.primary,
                    title: '$eventCount ta',
                    subtitle: 'Tadbir davomati',
                    badge: eventCount > 0 ? 'Qatnashgan' : 'Hali yo\'q',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Menyular ──────────────────────────────────────────────────────────────

  Widget _buildAccountMenu(ThemeData theme) {
    final activeCourses = _count('activeCoursesCount');
    final applications = _count('applicationsCount');

    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
            child: Text(
              'Hisob',
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                letterSpacing: 0.8,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
            child: Column(
              children: [
                ProfileMenuItemWidget(
                  icon: Icons.person_outline_rounded,
                  label: 'Shaxsiy ma\'lumotlar',
                  subtitle: '${_text('region')} · ${_text('specialty')}',
                  iconColor: AppTheme.primary,
                ),
                const SizedBox(height: 8),
                ProfileMenuItemWidget(
                  icon: Icons.stars_rounded,
                  label: 'Reyting bali',
                  subtitle: '${_count('score')} ball',
                  iconColor: AppTheme.cardTeal,
                ),
                const SizedBox(height: 8),
                ProfileMenuItemWidget(
                  icon: Icons.school_outlined,
                  label: 'Mening kurslarim',
                  subtitle: '$activeCourses ta faol kurs',
                  iconColor: AppTheme.cardPurple,
                ),
                const SizedBox(height: 8),
                ProfileMenuItemWidget(
                  icon: Icons.work_outline_rounded,
                  label: 'Mening arizalarim',
                  subtitle: '$applications ta ariza yuborilgan',
                  iconColor: AppTheme.cardOrange,
                ),
                const SizedBox(height: 8),
                ProfileMenuItemWidget(
                  icon: Icons.fact_check_outlined,
                  label: 'Davomat',
                  subtitle: 'GPS va QR davomat holati',
                  iconColor: AppTheme.success,
                  onTap: () => context.push(AppRoutes.attendanceScreen),
                ),
                const SizedBox(height: 8),
                ProfileMenuItemWidget(
                  icon: Icons.bar_chart_rounded,
                  label: 'KPI ko\'rsatkichlari',
                  subtitle: 'Samaradorlik va natijalar',
                  iconColor: AppTheme.cardIndigo,
                  onTap: () => context.push(AppRoutes.kpiScreen),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsMenu(ThemeData theme) {
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
            child: Text(
              'Sozlamalar',
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                letterSpacing: 0.8,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
            child: Column(
              children: [
                ProfileMenuItemWidget(
                  icon: Icons.notifications_outlined,
                  label: 'Bildirishnomalar',
                  subtitle: 'Push va email sozlamalari',
                  iconColor: AppTheme.cardBlue,
                ),
                const SizedBox(height: 8),
                ProfileMenuItemWidget(
                  icon: Icons.language_rounded,
                  label: 'Til va interfeys',
                  subtitle: 'O\'zbek (Lotin)',
                  iconColor: AppTheme.cardGreen,
                ),
                const SizedBox(height: 8),
                ProfileMenuItemWidget(
                  icon: Icons.help_outline_rounded,
                  label: 'Yordam va FAQ',
                  subtitle: 'Ko\'p so\'raladigan savollar',
                  iconColor: AppTheme.cardIndigo,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Tizimdan chiqish',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        content: const Text(
          'Haqiqatan ham tizimdan chiqmoqchimisiz?',
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Bekor qilish'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            onPressed: () async {
              Navigator.of(ctx).pop();
              await AuthService.logout();
              if (!mounted) return;
              this.context.go(AppRoutes.loginScreen);
            },
            child: const Text('Chiqish'),
          ),
        ],
      ),
    );
  }
}

class _AttendanceCard extends StatelessWidget {
  final IconData icon;
  final List<Color> gradient;
  final Color shadowColor;
  final String title;
  final String subtitle;
  final String badge;

  const _AttendanceCard({
    required this.icon,
    required this.gradient,
    required this.shadowColor,
    required this.title,
    required this.subtitle,
    required this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: shadowColor.withAlpha(51),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(38),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(color: Colors.white70, fontSize: 11),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(38),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              badge,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatItem({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 36, color: Colors.white.withAlpha(26));
  }
}
