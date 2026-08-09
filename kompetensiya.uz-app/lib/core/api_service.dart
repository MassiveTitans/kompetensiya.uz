import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Serverdan qaytgan xatolik.
class ApiException implements Exception {
  final String message;
  final int? statusCode;

  const ApiException(this.message, {this.statusCode});

  bool get isUnauthorized => statusCode == 401;

  @override
  String toString() => message;
}

/// kompetensiya.uz backend API mijozi.
///
/// Bazaviy manzil `--dart-define=API_BASE_URL=...` orqali beriladi.
/// Berilmasa: Android emulator uchun 10.0.2.2, qolganlar uchun localhost.
///
/// Ilovadagi barcha ma'lumot shu API orqali ma'lumotlar bazasidan olinadi.
class ApiService {
  ApiService._();

  static const String _envBaseUrl = String.fromEnvironment('API_BASE_URL');
  static const String _tokenKey = 'api_token';

  static String? _token;

  static String get baseUrl {
    if (_envBaseUrl.isNotEmpty) return _envBaseUrl;
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8000';
    }
    return 'http://localhost:8000';
  }

  static String? get token => _token;
  static bool get isAuthenticated => _token != null && _token!.isNotEmpty;

  /// Saqlangan kalitni xotiradan o'qiydi (ilova ishga tushganda chaqiriladi).
  static Future<void> restoreToken() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_tokenKey);
    _token = (saved != null && saved.isNotEmpty) ? saved : null;
  }

  static Future<void> setToken(String? value) async {
    _token = (value != null && value.isNotEmpty) ? value : null;
    final prefs = await SharedPreferences.getInstance();
    if (_token == null) {
      await prefs.remove(_tokenKey);
    } else {
      await prefs.setString(_tokenKey, _token!);
    }
  }

  static final Dio _dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {'Accept': 'application/json'},
    ),
  )..interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (_token != null) {
            options.headers['Authorization'] = 'Token $_token';
          }
          handler.next(options);
        },
      ),
    );

  static ApiException _asException(DioException e) {
    final status = e.response?.statusCode;
    final data = e.response?.data;
    if (data is Map && data['detail'] is String) {
      return ApiException(data['detail'] as String, statusCode: status);
    }
    if (status == 401) {
      return const ApiException('Autentifikatsiya talab etiladi', statusCode: 401);
    }
    return ApiException(
      'Server bilan bog\'lanib bo\'lmadi. Internet aloqasini tekshiring.',
      statusCode: status,
    );
  }

  /// Ro'yxat qaytaradigan endpointlar uchun.
  static Future<List<Map<String, dynamic>>> getList(
    String path, {
    Map<String, dynamic>? query,
  }) async {
    try {
      final res = await _dio.get<List<dynamic>>(path, queryParameters: query);
      return (res.data ?? [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    } on DioException catch (e) {
      throw _asException(e);
    }
  }

  /// Bitta obyekt qaytaradigan endpointlar uchun.
  static Future<Map<String, dynamic>> getMap(
    String path, {
    Map<String, dynamic>? query,
  }) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(
        path,
        queryParameters: query,
      );
      return res.data ?? <String, dynamic>{};
    } on DioException catch (e) {
      throw _asException(e);
    }
  }

  static Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? body,
  }) async {
    try {
      final res = await _dio.post<dynamic>(path, data: body ?? const {});
      final data = res.data;
      if (data is Map) return Map<String, dynamic>.from(data);
      return <String, dynamic>{};
    } on DioException catch (e) {
      throw _asException(e);
    }
  }
}
