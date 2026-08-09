import 'package:flutter/foundation.dart';

import 'api_service.dart';

/// ONE ID sozlamalari (serverdan olinadi).
class OneIdConfig {
  final bool configured;
  final String authorizeUrl;
  final String redirectUri;

  const OneIdConfig({
    required this.configured,
    required this.authorizeUrl,
    required this.redirectUri,
  });

  factory OneIdConfig.fromMap(Map<String, dynamic> map) => OneIdConfig(
        configured: map['configured'] == true,
        authorizeUrl: (map['authorizeUrl'] ?? '') as String,
        redirectUri: (map['redirectUri'] ?? '') as String,
      );
}

/// Foydalanuvchi sessiyasi — profil ma'lumotlari to'liq bazadan olinadi.
class AuthService {
  AuthService._();

  /// Joriy foydalanuvchi profili (`/api/me/`), kirilmagan bo'lsa `null`.
  static final ValueNotifier<Map<String, dynamic>?> profile =
      ValueNotifier<Map<String, dynamic>?>(null);

  static bool get isAuthenticated => ApiService.isAuthenticated;

  /// Ilova ishga tushganda: saqlangan kalitni tiklab, profilni yuklaydi.
  static Future<void> restore() async {
    await ApiService.restoreToken();
    if (ApiService.isAuthenticated) {
      await refreshProfile();
    }
  }

  static Future<Map<String, dynamic>?> refreshProfile() async {
    if (!ApiService.isAuthenticated) {
      profile.value = null;
      return null;
    }
    try {
      final data = await ApiService.getMap('/api/me/');
      profile.value = data;
      return data;
    } on ApiException catch (e) {
      if (e.isUnauthorized) {
        await ApiService.setToken(null);
        profile.value = null;
        return null;
      }
      rethrow;
    }
  }

  static Future<OneIdConfig> oneIdConfig() async {
    final data = await ApiService.getMap('/api/auth/one-id/');
    return OneIdConfig.fromMap(data);
  }

  /// ONE ID qaytargan `code`ni serverga yuborib, kalitni saqlaydi.
  static Future<void> completeOneIdLogin(String code, String redirectUri) async {
    final data = await ApiService.post(
      '/api/auth/one-id/exchange/',
      body: {'code': code, 'redirectUri': redirectUri},
    );
    final token = data['token'] as String?;
    if (token == null || token.isEmpty) {
      throw const ApiException('Serverdan kirish kaliti olinmadi');
    }
    await ApiService.setToken(token);
    final user = data['user'];
    profile.value = user is Map ? Map<String, dynamic>.from(user) : null;
    if (profile.value == null) await refreshProfile();
  }

  static Future<void> logout() async {
    try {
      await ApiService.post('/api/auth/logout/');
    } on ApiException {
      // Server javob bermasa ham lokal sessiya tozalanadi.
    }
    await ApiService.setToken(null);
    profile.value = null;
  }
}
