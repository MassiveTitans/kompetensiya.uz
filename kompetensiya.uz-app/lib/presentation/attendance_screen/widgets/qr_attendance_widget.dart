import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../core/api_service.dart';
import '../../../theme/app_theme.dart';

/// Tadbir QR davomati — qatnashgan tadbirlar bazadan olinadi,
/// skanerlangan kod serverda tekshiriladi.
class QrAttendanceWidget extends StatefulWidget {
  const QrAttendanceWidget({super.key});

  @override
  State<QrAttendanceWidget> createState() => _QrAttendanceWidgetState();
}

class _QrAttendanceWidgetState extends State<QrAttendanceWidget> {
  MobileScannerController? _scannerController;
  bool _isScanning = false;
  bool _isSubmitting = false;

  List<Map<String, dynamic>> _attendedEvents = [];
  bool _isLoading = true;
  String? _loadError;
  bool _needsLogin = false;

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

  @override
  void initState() {
    super.initState();
    _loadAttendedEvents();
  }

  @override
  void dispose() {
    _scannerController?.dispose();
    super.dispose();
  }

  Future<void> _loadAttendedEvents() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
      _needsLogin = false;
    });
    try {
      final data = await ApiService.getList('/api/attendance/events/');
      if (!mounted) return;
      setState(() {
        _attendedEvents = data;
        _isLoading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _needsLogin = e.isUnauthorized;
        _loadError = e.isUnauthorized
            ? 'Tadbir davomatini ko\'rish uchun ONE ID orqali kiring.'
            : e.message;
        _isLoading = false;
      });
    }
  }

  void _startScanning() {
    setState(() => _isScanning = true);
    if (!kIsWeb) {
      _scannerController = MobileScannerController(
        detectionSpeed: DetectionSpeed.noDuplicates,
        facing: CameraFacing.back,
      );
    }
  }

  void _stopScanning() {
    _scannerController?.dispose();
    _scannerController = null;
    setState(() => _isScanning = false);
  }

  void _onQrDetected(BarcodeCapture capture) {
    final barcode = capture.barcodes.firstOrNull;
    final rawValue = barcode?.rawValue;
    if (rawValue == null || _isSubmitting) return;
    _scannerController?.stop();
    _submitCode(rawValue.trim());
  }

  /// QR kod serverga yuboriladi — tadbir va davomat bazada tekshiriladi.
  Future<void> _submitCode(String code) async {
    setState(() {
      _isScanning = false;
      _isSubmitting = true;
    });
    try {
      final result = await ApiService.post(
        '/api/attendance/qr/',
        body: {'code': code},
      );
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      await _loadAttendedEvents();
      if (!mounted) return;
      _showResultDialog(
        (result['message'] ?? '') as String,
        alreadyAttended: result['created'] != true,
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      _showResultDialog(e.message, isError: true);
    }
  }

  void _showResultDialog(
    String message, {
    bool alreadyAttended = false,
    bool isError = false,
  }) {
    final Color color = isError
        ? AppTheme.errorColor
        : (alreadyAttended ? AppTheme.warning : AppTheme.success);
    final Color background = isError
        ? AppTheme.errorContainer
        : (alreadyAttended
            ? AppTheme.warningContainer
            : AppTheme.successContainer);
    final IconData icon = isError
        ? Icons.error_outline_rounded
        : (alreadyAttended
            ? Icons.info_outline_rounded
            : Icons.check_circle_rounded);
    final String title = isError
        ? 'Xatolik'
        : (alreadyAttended ? 'Allaqachon qatnashgansiz' : 'Muvaffaqiyatli!');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: background,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 36),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: const TextStyle(fontSize: 13, color: Colors.black54),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Yaxshi'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_loadError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
                _loadError!,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadAttendedEvents,
                child: const Text('Qayta urinish'),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Scanner card
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppTheme.surfaceLight,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(10),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: _isScanning ? _buildScannerView() : _buildScanPrompt(theme),
          ),

          const SizedBox(height: 24),

          // Attended events
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Qatnashgan tadbirlar',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onSurface,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.primaryContainer,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '${_attendedEvents.length} ta',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppTheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          if (_attendedEvents.isEmpty)
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: AppTheme.surfaceLight,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.event_busy_rounded,
                    size: 48,
                    color: theme.colorScheme.onSurfaceVariant.withAlpha(128),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Hali hech qanday tadbirda qatnashmadingiz',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          else
            ...List.generate(_attendedEvents.length, (i) {
              final event = _attendedEvents[i];
              final color =
                  _colors[event['color']] ?? AppTheme.cardBlue;
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
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: color.withAlpha(26),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          Icons.event_available_rounded,
                          color: color,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              (event['name'] ?? '') as String,
                              style: theme.textTheme.titleSmall?.copyWith(
                                color: theme.colorScheme.onSurface,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Icon(
                                  Icons.calendar_today_outlined,
                                  size: 11,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  (event['dateLabel'] ?? '') as String,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Icon(
                                  Icons.location_on_outlined,
                                  size: 11,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    (event['location'] ?? '') as String,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.successContainer,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.check_circle_rounded,
                              size: 11,
                              color: AppTheme.success,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Qatnashdi',
                              style: TextStyle(
                                color: AppTheme.success,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildScanPrompt(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: AppTheme.primaryContainer,
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(
              Icons.qr_code_scanner_rounded,
              color: AppTheme.primary,
              size: 52,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'QR Kodni Skanerlash',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tadbirda qatnashganingizni tasdiqlash uchun tadbir QR kodini skanerlang',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isSubmitting
                  ? null
                  : (kIsWeb ? _showManualCodeDialog : _startScanning),
              icon: Icon(
                kIsWeb
                    ? Icons.keyboard_alt_outlined
                    : Icons.qr_code_scanner_rounded,
                size: 20,
              ),
              label: Text(
                _isSubmitting
                    ? 'Yuborilmoqda…'
                    : (kIsWeb
                        ? 'QR kodni kiritish'
                        : 'Skanerlashni boshlash'),
              ),
            ),
          ),
          if (!kIsWeb) ...[
            const SizedBox(height: 8),
            TextButton(
              onPressed: _isSubmitting ? null : _showManualCodeDialog,
              child: const Text('Kodni qo\'lda kiritish'),
            ),
          ],
        ],
      ),
    );
  }

  /// Kamera ishlamaganda (masalan, brauzerda) QR kodni qo'lda kiritish.
  void _showManualCodeDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Tadbir QR kodi'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Kodni kiriting'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Bekor qilish'),
          ),
          ElevatedButton(
            onPressed: () {
              final code = controller.text.trim();
              Navigator.of(ctx).pop();
              if (code.isNotEmpty) _submitCode(code);
            },
            child: const Text('Yuborish'),
          ),
        ],
      ),
    );
  }

  Widget _buildScannerView() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: SizedBox(
        height: 320,
        child: Stack(
          children: [
            MobileScanner(
              controller: _scannerController!,
              onDetect: _onQrDetected,
            ),
            // Scan overlay
            Center(
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white, width: 2),
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
            // Corner decorations
            Center(
              child: SizedBox(
                width: 220,
                height: 220,
                child: CustomPaint(painter: _CornerPainter()),
              ),
            ),
            Positioned(
              bottom: 16,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withAlpha(153),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Text(
                    'QR kodni ramka ichiga joylashtiring',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 12,
              right: 12,
              child: GestureDetector(
                onTap: _stopScanning,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withAlpha(153),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CornerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.secondary
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const cornerLength = 24.0;
    const radius = 16.0;

    // Top-left
    canvas.drawLine(
      const Offset(0, cornerLength),
      const Offset(0, radius),
      paint,
    );
    canvas.drawArc(
      const Rect.fromLTWH(0, 0, radius * 2, radius * 2),
      3.14159,
      3.14159 / 2,
      false,
      paint,
    );
    canvas.drawLine(
      const Offset(radius, 0),
      const Offset(cornerLength, 0),
      paint,
    );

    // Top-right
    canvas.drawLine(
      Offset(size.width - cornerLength, 0),
      Offset(size.width - radius, 0),
      paint,
    );
    canvas.drawArc(
      Rect.fromLTWH(size.width - radius * 2, 0, radius * 2, radius * 2),
      -3.14159 / 2,
      3.14159 / 2,
      false,
      paint,
    );
    canvas.drawLine(
      Offset(size.width, radius),
      Offset(size.width, cornerLength),
      paint,
    );

    // Bottom-left
    canvas.drawLine(
      Offset(0, size.height - cornerLength),
      Offset(0, size.height - radius),
      paint,
    );
    canvas.drawArc(
      Rect.fromLTWH(0, size.height - radius * 2, radius * 2, radius * 2),
      3.14159 / 2,
      3.14159 / 2,
      false,
      paint,
    );
    canvas.drawLine(
      Offset(radius, size.height),
      Offset(cornerLength, size.height),
      paint,
    );

    // Bottom-right
    canvas.drawLine(
      Offset(size.width - cornerLength, size.height),
      Offset(size.width - radius, size.height),
      paint,
    );
    canvas.drawArc(
      Rect.fromLTWH(
        size.width - radius * 2,
        size.height - radius * 2,
        radius * 2,
        radius * 2,
      ),
      0,
      3.14159 / 2,
      false,
      paint,
    );
    canvas.drawLine(
      Offset(size.width, size.height - radius),
      Offset(size.width, size.height - cornerLength),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

