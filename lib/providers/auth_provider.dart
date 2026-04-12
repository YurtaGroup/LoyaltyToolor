import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../models/loyalty.dart';
import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  AppUser? _user;
  LoyaltyAccount? _loyalty;
  bool _isLoggedIn = false;
  bool _isLoading = false;
  String? _error;

  // ── Rotating QR token ─────────────────────────────────────────────────
  String? _qrToken;
  Timer? _qrRefreshTimer;

  AppUser? get user => _user;
  LoyaltyAccount? get loyalty => _loyalty;
  bool get isLoggedIn => _isLoggedIn;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get qrToken => _qrToken;

  // ── OTP auth flow ─────────────────────────────────────────────────────

  /// Send OTP to the given phone number.
  /// Returns the OTP code from backend (for dev auto-fill).
  Future<String?> sendOtp(String phone) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await ApiService.sendOtp(phone);
      _isLoading = false;
      notifyListeners();
      return data['otp_code'] as String?;
    } catch (e) {
      _error = 'Ошибка отправки кода: $e';
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  /// Verify OTP code and complete login/registration.
  Future<void> verifyOtp(String phone, String otpCode) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await ApiService.verifyOtp(phone, otpCode);
    } catch (e) {
      _error = 'Неверный код';
      _isLoading = false;
      notifyListeners();
      return;
    }

    try {
      await fetchProfile();
    } catch (e) {
      _error = 'Ошибка профиля: $e';
      _isLoggedIn = false;
      _isLoading = false;
      notifyListeners();
      return;
    }

    try {
      await fetchLoyalty();
    } catch (e) {
      debugPrint('[AuthProvider] fetchLoyalty error: $e');
    }

    _isLoggedIn = true;
    startQrRefresh();
    if (_user != null) {
      // Analytics removed — was Mixpanel, now decommissioned.
    }
    _isLoading = false;
    notifyListeners();
  }

  /// Fetch user profile from GET /api/v1/users/me.
  Future<void> fetchProfile() async {
    try {
      final response = await ApiService.dio.get('/api/v1/users/me');
      final data = response.data as Map<String, dynamic>;
      _user = AppUser.fromJson(data);
    } catch (e) {
      debugPrint('[AuthProvider] fetchProfile error: $e');
      rethrow;
    }
  }

  /// Fetch loyalty account from GET /api/v1/loyalty/me.
  Future<void> fetchLoyalty() async {
    try {
      final response = await ApiService.dio.get('/api/v1/loyalty/me');
      final data = response.data as Map<String, dynamic>;
      _loyalty = LoyaltyAccount.fromJson(data);

      // Also fetch transactions and attach them
      try {
        final txnResponse =
            await ApiService.dio.get('/api/v1/loyalty/me/transactions');
        final txnData = txnResponse.data as Map<String, dynamic>;
        final items = txnData['items'] as List<dynamic>? ?? [];
        final transactions = items
            .map((t) =>
                LoyaltyTransaction.fromJson(t as Map<String, dynamic>))
            .toList();

        // Rebuild loyalty with transactions
        _loyalty = LoyaltyAccount(
          id: _loyalty!.id,
          qrCode: _loyalty!.qrCode,
          tier: _loyalty!.tier,
          points: _loyalty!.points,
          totalSpent: _loyalty!.totalSpent,
          transactions: transactions,
        );
      } catch (e) {
        debugPrint('[AuthProvider] fetchLoyalty transactions error: $e');
      }
    } catch (e) {
      debugPrint('[AuthProvider] fetchLoyalty error: $e');
    }
  }

  // ── Rotating QR token methods ──────────────────────────────────────────

  Future<void> fetchQrToken() async {
    try {
      final response = await ApiService.dio.get('/api/v1/loyalty/me/qr');
      final data = response.data as Map<String, dynamic>;
      _qrToken = data['qr_token'] as String?;
      notifyListeners();
    } catch (e) {
      debugPrint('[AuthProvider] fetchQrToken error: $e');
      if (_qrToken == null && _loyalty != null) {
        _qrToken = _loyalty!.qrCode;
        notifyListeners();
      }
    }
  }

  void startQrRefresh() {
    stopQrRefresh();
    fetchQrToken();
    _qrRefreshTimer = Timer.periodic(
      const Duration(seconds: 25),
      (_) => fetchQrToken(),
    );
  }

  void stopQrRefresh() {
    _qrRefreshTimer?.cancel();
    _qrRefreshTimer = null;
  }

  /// Try to restore session from stored tokens on app start.
  Future<void> tryRestoreSession() async {
    _isLoading = true;
    notifyListeners();

    try {
      final loggedIn = await ApiService.isLoggedIn();
      if (loggedIn) {
        await fetchProfile();
        await fetchLoyalty();
        _isLoggedIn = true;
        startQrRefresh();
      }
    } on DioException catch (e) {
      debugPrint('[AuthProvider] tryRestoreSession error: $e');
      final code = e.response?.statusCode;
      if (code == 401 || code == 403) {
        await ApiService.logout();
        _isLoggedIn = false;
      }
    } catch (e) {
      debugPrint('[AuthProvider] tryRestoreSession error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── Logout ────────────────────────────────────────────────────────────

  Future<void> logout() async {
    stopQrRefresh();
    try {
      await ApiService.logout();
    } catch (e) {
      debugPrint('[AuthProvider] logout error: $e');
    }
    // Analytics.reset() removed — Mixpanel decommissioned.
    _user = null;
    _loyalty = null;
    _qrToken = null;
    _isLoggedIn = false;
    _error = null;
    notifyListeners();
  }

  /// Clear the current error message.
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
