import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../core/auth_service.dart';
import '../../../theme/app_theme.dart';

/// ONE ID avtorizatsiya sahifasi.
///
/// Foydalanuvchi sso.egov.uz da kirgach, server `redirectUri` ga `code`
/// bilan qaytadi. Shu paytda sahifa ochilmaydi — `code` ushlab olinib,
/// backendga yuboriladi va API kaliti olinadi.
class OneIdWebView extends StatefulWidget {
  final OneIdConfig config;

  const OneIdWebView({super.key, required this.config});

  @override
  State<OneIdWebView> createState() => _OneIdWebViewState();
}

class _OneIdWebViewState extends State<OneIdWebView> {
  late final WebViewController _controller;
  bool _handled = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (mounted) setState(() => _isLoading = true);
          },
          onPageFinished: (_) {
            if (mounted) setState(() => _isLoading = false);
          },
          onNavigationRequest: (request) {
            final uri = Uri.tryParse(request.url);
            if (uri == null) return NavigationDecision.navigate;
            if (!request.url.startsWith(widget.config.redirectUri)) {
              return NavigationDecision.navigate;
            }
            final code = uri.queryParameters['code'];
            if (code != null && code.isNotEmpty) {
              _exchange(code);
            } else {
              _fail(uri.queryParameters['error'] ??
                  'ONE ID kirishni bekor qildi.');
            }
            return NavigationDecision.prevent;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.config.authorizeUrl));
  }

  Future<void> _exchange(String code) async {
    if (_handled) return;
    _handled = true;
    if (mounted) setState(() => _isLoading = true);
    try {
      await AuthService.completeOneIdLogin(code, widget.config.redirectUri);
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      _fail(e.toString());
    }
  }

  void _fail(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppTheme.errorColor),
    );
    Navigator.of(context).pop(false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: const Text('ONE ID'),
        backgroundColor: AppTheme.surfaceLight,
        foregroundColor: AppTheme.primary,
        elevation: 0,
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading) const LinearProgressIndicator(minHeight: 3),
        ],
      ),
    );
  }
}
