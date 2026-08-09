import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../../../core/api_service.dart';
import '../../../theme/app_theme.dart';

/// GPS davomat — ish hududi, tarix va belgilash serverdagi bazaga bog'langan.
class GpsAttendanceWidget extends StatefulWidget {
  const GpsAttendanceWidget({super.key});

  @override
  State<GpsAttendanceWidget> createState() => _GpsAttendanceWidgetState();
}

class _GpsAttendanceWidgetState extends State<GpsAttendanceWidget>
    with SingleTickerProviderStateMixin {
  // Ish hududi admin tomonidan bazada belgilanadi (/api/attendance/).
  Map<String, dynamic>? _zone;
  List<Map<String, dynamic>> _history = [];

  bool _isLoading = true;
  String? _loadError;
  bool _needsLogin = false;

  bool _isChecking = false;
  bool _hasChecked = false;
  bool _isPresent = false;
  double? _distanceMeters;
  String _statusMessage = '';

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _loadAttendance();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _loadAttendance() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
      _needsLogin = false;
    });
    try {
      final data = await ApiService.getMap('/api/attendance/');
      if (!mounted) return;
      final today = data['today'] as Map<String, dynamic>?;
      setState(() {
        _zone = data['zone'] as Map<String, dynamic>?;
        _history = ((data['history'] as List?) ?? const [])
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        if (today != null) {
          _hasChecked = true;
          _isPresent = today['status'] != 'absent';
          _distanceMeters = (today['distanceMeters'] as num?)?.toDouble();
          _statusMessage = 'Bugun ${today['checkIn']} da belgilangan';
        }
        _isLoading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _needsLogin = e.isUnauthorized;
        _loadError = e.isUnauthorized
            ? 'Davomatni ko\'rish uchun ONE ID orqali kiring.'
            : e.message;
        _isLoading = false;
      });
    }
  }

  double get _zoneRadius =>
      (_zone?['radiusMeters'] as num?)?.toDouble() ?? 200.0;

  /// Joylashuvni aniqlab, davomatni serverga yozadi.
  Future<void> _checkAttendance() async {
    setState(() {
      _isChecking = true;
      _statusMessage = '';
    });

    Position? position;
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _stopChecking('GPS xizmati o\'chirilgan. Iltimos yoqing.');
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _stopChecking('Joylashuv ruxsati rad etildi.');
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        _stopChecking(
          'Joylashuv ruxsati doimiy rad etilgan. Sozlamalarda yoqing.',
        );
        return;
      }

      position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
    } catch (_) {
      _stopChecking('Joylashuvni aniqlab bo\'lmadi. Qayta urinib ko\'ring.');
      return;
    }

    // Masofa serverda ham tekshiriladi — bu faqat darhol ko'rsatish uchun.
    if (_zone != null) {
      final distance = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        (_zone!['latitude'] as num).toDouble(),
        (_zone!['longitude'] as num).toDouble(),
      );
      if (mounted) setState(() => _distanceMeters = distance);
    }

    try {
      final result = await ApiService.post(
        '/api/attendance/gps/',
        body: {
          'latitude': position.latitude,
          'longitude': position.longitude,
        },
      );
      if (!mounted) return;
      setState(() {
        _isChecking = false;
        _hasChecked = true;
        _isPresent = true;
        _statusMessage = (result['message'] ?? 'Davomat belgilandi') as String;
      });
      await _loadAttendance();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _isChecking = false;
        _hasChecked = true;
        _isPresent = false;
        _statusMessage = e.message;
      });
    }
  }

  void _stopChecking(String message) {
    if (!mounted) return;
    setState(() {
      _isChecking = false;
      _statusMessage = message;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_loadError != null) {
      return _buildMessage(theme, _loadError!, _needsLogin);
    }

    return RefreshIndicator(
      onRefresh: _loadAttendance,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildZoneCard(theme),
            const SizedBox(height: 20),
            _buildCheckCard(),
            const SizedBox(height: 24),
            Text(
              'Davomat tarixi',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            if (_history.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text(
                    'Hali davomat yozuvlari yo\'q',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              )
            else
              ..._history.map((record) => _buildHistoryTile(theme, record)),
          ],
        ),
      ),
    );
  }

  Widget _buildMessage(ThemeData theme, String message, bool needsLogin) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              needsLogin ? Icons.lock_outline_rounded : Icons.wifi_off_rounded,
              size: 48,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadAttendance,
              child: const Text('Qayta urinish'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildZoneCard(ThemeData theme) {
    final hasZone = _zone != null;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppTheme.primaryContainer,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.location_city_rounded,
              color: AppTheme.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Belgilangan hudud',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  hasZone
                      ? _zone!['name'] as String
                      : 'Hudud belgilanmagan',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.colorScheme.onSurface,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  hasZone
                      ? 'Radius: ${_zoneRadius.toInt()} metr'
                      : 'Administrator ish hududini kiritishi kerak',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppTheme.primaryContainer,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              'Admin',
              style: theme.textTheme.labelSmall?.copyWith(
                color: AppTheme.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _hasChecked
              ? (_isPresent
                  ? [const Color(0xFF1B5E20), const Color(0xFF2E7D32)]
                  : [const Color(0xFFB71C1C), const Color(0xFFC62828)])
              : [const Color(0xFF1A1A2E), const Color(0xFF16213E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: (_hasChecked
                    ? (_isPresent ? AppTheme.success : AppTheme.errorColor)
                    : const Color(0xFF1A1A2E))
                .withAlpha(77),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _isChecking ? _pulseAnimation.value : 1.0,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(26),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withAlpha(51),
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    _hasChecked
                        ? (_isPresent
                            ? Icons.check_circle_rounded
                            : Icons.cancel_rounded)
                        : Icons.my_location_rounded,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          Text(
            _isChecking ? 'Joylashuv aniqlanmoqda...' : 'HOZIR',
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _isChecking
                ? 'GPS signal qabul qilinmoqda'
                : (_hasChecked
                    ? (_isPresent ? 'ISHDA' : 'BELGILANMADI')
                    : 'GPS orqali belgilash'),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
            textAlign: TextAlign.center,
          ),
          if (_statusMessage.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              _statusMessage,
              style: const TextStyle(color: Colors.white70, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ],
          if (_distanceMeters != null) ...[
            const SizedBox(height: 4),
            Text(
              'Masofa: ${_distanceMeters!.toInt()} metr',
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ],
          const SizedBox(height: 20),
          GestureDetector(
            onTap: _isChecking ? null : _checkAttendance,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(
                horizontal: 32,
                vertical: 14,
              ),
              decoration: BoxDecoration(
                color: _isChecking ? Colors.white.withAlpha(26) : Colors.white,
                borderRadius: BorderRadius.circular(999),
              ),
              child: _isChecking
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      _hasChecked ? 'Qayta belgilash' : 'Davomatni belgilash',
                      style: TextStyle(
                        color: _hasChecked
                            ? (_isPresent
                                ? AppTheme.success
                                : AppTheme.errorColor)
                            : AppTheme.primary,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryTile(ThemeData theme, Map<String, dynamic> record) {
    final isPresent = record['status'] != 'absent';
    final distance = (record['distanceMeters'] as num?)?.toInt();
    final checkIn = (record['checkIn'] ?? '') as String;
    final checkOut = (record['checkOut'] ?? '') as String;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(14),
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
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isPresent
                    ? AppTheme.successContainer
                    : AppTheme.errorContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isPresent ? Icons.check_rounded : Icons.close_rounded,
                color: isPresent ? AppTheme.success : AppTheme.errorColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${record['dateLabel']}'
                    '${checkIn.isNotEmpty ? ', $checkIn' : ''}'
                    '${checkOut.isNotEmpty ? ' — $checkOut' : ''}',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    distance != null
                        ? 'Masofa: $distance metr'
                        : (record['location'] as String? ?? ''),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: isPresent
                    ? AppTheme.successContainer
                    : AppTheme.errorContainer,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                (record['statusLabel'] ?? '') as String,
                style: TextStyle(
                  color: isPresent ? AppTheme.success : AppTheme.errorColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
