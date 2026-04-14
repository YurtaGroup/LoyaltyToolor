import 'dart:io';

import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'device_id_service.dart';

/// Base URL configured via --dart-define, or cool-group production by default.
/// The /api/v1/* compatibility layer on cool-group translates calls to the
/// native endpoints, so NO other code changes are needed in this app.
const _envUrl = String.fromEnvironment('API_URL', defaultValue: '');
final String apiBaseUrl = _envUrl.isNotEmpty
    ? _envUrl
    : 'https://coolgroup-api.onrender.com';

/// Dio-based HTTP client singleton.
/// Call [init] once in main() before runApp().
class ApiService {
  ApiService._();

  static late Dio _dio;

  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';
  static const _guestTokenKey = 'guest_access_token';

  static Future<SharedPreferences> get _prefs async =>
      SharedPreferences.getInstance();

  /// Expose the Dio instance for direct use in repositories / providers.
  static Dio get dio => _dio;

  // ── Initialization ────────────────────────────────────────────────────

  /// Create and configure the shared [Dio] instance.
  static Future<void> init() async {
    _dio = Dio(
      BaseOptions(
        baseUrl: apiBaseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: _onRequest,
        onError: _onError,
      ),
    );
  }

  // ── Interceptors ──────────────────────────────────────────────────────

  static Future<void> _onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Customer token wins when present; otherwise fall back to the
    // guest token so anonymous users can still reach public endpoints
    // and /api/me/events. Never attach both.
    final customer = await getAccessToken();
    if (customer != null && customer.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $customer';
    } else {
      final guest = await getGuestToken();
      if (guest != null && guest.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $guest';
      }
    }
    handler.next(options);
  }

  static Future<void> _onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    // Retry once on 502 (transient gateway error)
    if (err.response?.statusCode == 502) {
      final opts = err.requestOptions;
      if (opts.extra['_retried'] != true) {
        opts.extra['_retried'] = true;
        try {
          await Future.delayed(const Duration(seconds: 1));
          final response = await _dio.fetch(opts);
          return handler.resolve(response);
        } on DioException catch (e) {
          return handler.next(e);
        }
      }
    }
    if (err.response?.statusCode == 401) {
      final path = err.requestOptions.path;
      final isAuthEndpoint = path.contains('/auth/');
      final alreadyRetried = err.requestOptions.extra['_retried_401'] == true;

      if (!isAuthEndpoint && !alreadyRetried) {
        final refreshed = await _tryRefreshToken();
        if (refreshed) {
          final opts = err.requestOptions;
          opts.extra['_retried_401'] = true;
          final newToken = await getAccessToken();
          opts.headers['Authorization'] = 'Bearer $newToken';
          try {
            final response = await _dio.fetch(opts);
            return handler.resolve(response);
          } on DioException catch (e) {
            return handler.next(e);
          }
        } else {
          await clearTokens();
        }
      }
    }
    handler.next(err);
  }

  /// Attempt to exchange the refresh token for a new access token.
  static Future<bool> _tryRefreshToken() async {
    final prefs = await _prefs;
    final refresh = prefs.getString(_refreshTokenKey);
    if (refresh == null) return false;

    try {
      final plainDio = Dio(BaseOptions(
        baseUrl: apiBaseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
      ));

      Response response;
      try {
        response = await plainDio.post(
          '/api/v1/auth/refresh',
          data: {'refresh_token': refresh},
        );
      } on DioException catch (e) {
        // Retry once on transient 502
        if (e.response?.statusCode == 502) {
          await Future.delayed(const Duration(seconds: 1));
          response = await plainDio.post(
            '/api/v1/auth/refresh',
            data: {'refresh_token': refresh},
          );
        } else {
          rethrow;
        }
      }

      final data = response.data as Map<String, dynamic>;
      final newAccess = data['access_token'] as String?;
      final newRefresh = data['refresh_token'] as String?;

      if (newAccess != null) {
        await setTokens(newAccess, newRefresh ?? refresh);
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  // ── Auth helpers ──────────────────────────────────────────────────────

  /// POST /api/v1/auth/send-otp — request OTP for phone number.
  /// Returns the full response data (includes otp_code for dev testing).
  static Future<Map<String, dynamic>> sendOtp(String phone) async {
    final response = await _dio.post(
      '/api/v1/auth/send-otp',
      data: {'phone': phone},
    );
    return response.data as Map<String, dynamic>;
  }

  /// POST /api/v1/auth/verify-otp — verify OTP and get tokens.
  static Future<Map<String, dynamic>> verifyOtp(
    String phone,
    String otpCode,
  ) async {
    final response = await _dio.post(
      '/api/v1/auth/verify-otp',
      data: {'phone': phone, 'otp_code': otpCode},
    );

    final data = response.data as Map<String, dynamic>;
    final access = data['access_token'] as String?;
    final refresh = data['refresh_token'] as String?;

    if (access != null && refresh != null) {
      await setTokens(access, refresh);
    }

    return data;
  }

  /// Clear stored tokens (local logout).
  static Future<void> logout() async {
    await clearTokens();
  }

  /// Returns `true` when an access token exists in secure storage.
  static Future<bool> isLoggedIn() async {
    final token = await getAccessToken();
    return token != null;
  }

  // ── Token storage ─────────────────────────────────────────────────────

  static Future<void> setTokens(String access, String refresh) async {
    final prefs = await _prefs;
    await prefs.setString(_accessTokenKey, access);
    await prefs.setString(_refreshTokenKey, refresh);
  }

  static Future<void> clearTokens() async {
    final prefs = await _prefs;
    await prefs.remove(_accessTokenKey);
    await prefs.remove(_refreshTokenKey);
  }

  static Future<String?> getAccessToken() async {
    final prefs = await _prefs;
    return prefs.getString(_accessTokenKey);
  }

  // ── Guest token ──────────────────────────────────────────────────────
  //
  // Guest tokens authenticate anonymous device-bound sessions on first
  // app launch. They are NOT cleared on logout — the same device keeps
  // its anonymous tracking identity across login cycles.

  static Future<String?> getGuestToken() async {
    final prefs = await _prefs;
    return prefs.getString(_guestTokenKey);
  }

  static Future<void> setGuestToken(String token) async {
    final prefs = await _prefs;
    await prefs.setString(_guestTokenKey, token);
  }

  /// Ensure a guest token exists. Called once at app startup after
  /// [init]. No-op if the user already has a customer or guest token.
  /// Failures are swallowed — the app still works without a guest
  /// token, it just loses anonymous analytics until the next launch.
  static Future<void> bootstrapGuest() async {
    if (await isLoggedIn()) return;
    final existing = await getGuestToken();
    if (existing != null && existing.isNotEmpty) return;

    try {
      final deviceId = await DeviceIdService.get();
      final platform = Platform.isIOS
          ? 'ios'
          : Platform.isAndroid
              ? 'android'
              : Platform.isMacOS
                  ? 'macos'
                  : 'other';
      final plain = Dio(BaseOptions(baseUrl: apiBaseUrl));
      final response = await plain.post(
        '/api/me/guest/init',
        data: {
          'device_id': deviceId,
          'platform': platform,
          'app_version': '1.0.0',
          'locale': 'ru',
        },
      );
      final data = response.data as Map<String, dynamic>;
      final token = data['guest_token'] as String?;
      if (token != null && token.isNotEmpty) {
        await setGuestToken(token);
      }
    } catch (_) {
      // Silent failure — analytics will resume on the next successful
      // bootstrap or after the user logs in.
    }
  }

  /// Decode the `sub` field out of the guest JWT so we can send it
  /// along with verify-otp for the server-side merge. Returns null if
  /// no guest token is stored or the token is malformed.
  static Future<String?> getGuestSubject() async {
    final token = await getGuestToken();
    if (token == null) return null;
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;
      final padded = parts[1].padRight(
        parts[1].length + (4 - parts[1].length % 4) % 4,
        '=',
      );
      final payloadJson = String.fromCharCodes(
        _base64UrlDecode(padded),
      );
      final match = RegExp(r'"sub"\s*:\s*"([^"]+)"').firstMatch(payloadJson);
      return match?.group(1);
    } catch (_) {
      return null;
    }
  }

  static List<int> _base64UrlDecode(String input) {
    return Uri.parse('data:text/plain;base64,$input')
        .data!
        .contentAsBytes();
  }

  /// Quick connectivity check — pings the API health endpoint.
  static Future<bool> isOnline() async {
    try {
      await _dio.get('/api/v1/health');
      return true;
    } catch (_) {
      return false;
    }
  }
}
