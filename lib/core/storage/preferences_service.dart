import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Centralized service to manage SharedPreferences storage.
class PreferencesService {
  final SharedPreferences _prefs;

  PreferencesService(this._prefs);

  static const String keyIsLoggedIn = 'is_logged_in';
  static const String keyAccessToken = 'access_token';
  static const String keyRefreshToken = 'refresh_token';
  static const String keyAuthResponse = 'auth_response_json';
  static const String keyUserData = 'user_data_json';
  static const String keyRememberMe = 'remember_me';
  static const String keyIsCompleteProfile = 'is_complete_profile';
  static const String keyDashboardData = 'dashboard_data_json';
  static const String keyPaymentsOverview = 'payments_overview_json';
  static const String keyPaymentsList = 'payments_list_json';
  static const String keyComplaintCategories = 'complaint_categories_json';
  static const String keyStaffList = 'staff_list_json';
  static const String keyComplaintsList = 'complaints_list_json';
  static const String keyVisitorsList = 'visitors_list_json';

  /// Save complete login response to SharedPreferences.
  Future<bool> saveLoginResponse({
    required Map<String, dynamic> responseJson,
    bool rememberMe = true,
  }) async {
    final data = responseJson['data'] as Map<String, dynamic>?;
    final accessToken = data?['access_token']?.toString() ?? '';
    final refreshToken = data?['refresh_token']?.toString() ?? '';
    final user = data?['user'] as Map<String, dynamic>?;
    final isComplete = user?['is_complete_profile'] as bool? ?? false;

    await _prefs.setBool(keyIsLoggedIn, true);
    await _prefs.setBool(keyRememberMe, rememberMe);
    await _prefs.setBool(keyIsCompleteProfile, isComplete);
    await _prefs.setString(keyAccessToken, accessToken);
    await _prefs.setString(keyRefreshToken, refreshToken);
    await _prefs.setString(keyAuthResponse, jsonEncode(responseJson));
    if (user != null) {
      await _prefs.setString(keyUserData, jsonEncode(user));
    }
    return true;
  }

  /// Save or update user profile data dictionary directly in storage.
  Future<bool> saveUserData(Map<String, dynamic> userMap) async {
    final Map<String, dynamic> actualUser = (userMap.containsKey('data') && userMap['data'] is Map<String, dynamic>)
        ? (((userMap['data'] as Map<String, dynamic>)['user'] is Map<String, dynamic>)
            ? (userMap['data'] as Map<String, dynamic>)['user'] as Map<String, dynamic>
            : userMap['data'] as Map<String, dynamic>)
        : (userMap.containsKey('user') && userMap['user'] is Map<String, dynamic>
            ? userMap['user'] as Map<String, dynamic>
            : userMap);

    await _prefs.setString(keyUserData, jsonEncode(actualUser));
    if (actualUser.containsKey('is_complete_profile')) {
      await _prefs.setBool(
        keyIsCompleteProfile,
        actualUser['is_complete_profile'] as bool? ?? false,
      );
    }
    return true;
  }

  /// Update tokens and optionally user profile after token refresh.
  Future<bool> updateTokens({
    required String accessToken,
    required String refreshToken,
    Map<String, dynamic>? user,
    Map<String, dynamic>? fullResponse,
  }) async {
    await _prefs.setString(keyAccessToken, accessToken);
    await _prefs.setString(keyRefreshToken, refreshToken);
    if (user != null) {
      if (user.containsKey('is_complete_profile')) {
        await _prefs.setBool(
          keyIsCompleteProfile,
          user['is_complete_profile'] as bool? ?? false,
        );
      }
      await _prefs.setString(keyUserData, jsonEncode(user));
    }
    if (fullResponse != null) {
      await _prefs.setString(keyAuthResponse, jsonEncode(fullResponse));
    }
    return true;
  }

  /// Check if user has an active saved session.
  bool get isLoggedIn {
    final loggedIn = _prefs.getBool(keyIsLoggedIn) ?? false;
    final token = _prefs.getString(keyAccessToken);
    return loggedIn && token != null && token.isNotEmpty;
  }

  /// Check if user has completed their profile.
  bool get isCompleteProfile => _prefs.getBool(keyIsCompleteProfile) ?? false;

  /// Get the saved access token.
  String? get accessToken => _prefs.getString(keyAccessToken);

  /// Get the saved refresh token.
  String? get refreshToken => _prefs.getString(keyRefreshToken);

  /// Get the raw saved auth response map.
  Map<String, dynamic>? getSavedAuthResponse() {
    final jsonStr = _prefs.getString(keyAuthResponse);
    if (jsonStr == null || jsonStr.isEmpty) return null;
    try {
      return jsonDecode(jsonStr) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  /// Get the saved user map.
  Map<String, dynamic>? getSavedUser() {
    final jsonStr = _prefs.getString(keyUserData);
    if (jsonStr == null || jsonStr.isEmpty) return null;
    try {
      return jsonDecode(jsonStr) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  /// Clear all saved auth credentials on logout.
  Future<bool> clearAuth() async {
    await _prefs.remove(keyIsLoggedIn);
    await _prefs.remove(keyIsCompleteProfile);
    await _prefs.remove(keyAccessToken);
    await _prefs.remove(keyRefreshToken);
    await _prefs.remove(keyAuthResponse);
    await _prefs.remove(keyUserData);
    await _prefs.remove(keyDashboardData);
    await _prefs.remove(keyPaymentsOverview);
    await _prefs.remove(keyPaymentsList);
    await _prefs.remove(keyComplaintCategories);
    return true;
  }

  /// Save cached dashboard JSON.
  Future<bool> saveDashboardData(Map<String, dynamic> data) async {
    return _prefs.setString(keyDashboardData, jsonEncode(data));
  }

  /// Get cached dashboard JSON.
  Map<String, dynamic>? getSavedDashboard() {
    final jsonStr = _prefs.getString(keyDashboardData);
    if (jsonStr == null || jsonStr.isEmpty) return null;
    try {
      return jsonDecode(jsonStr) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  /// Save cached payments overview JSON.
  Future<bool> savePaymentsOverview(Map<String, dynamic> data) async {
    return _prefs.setString(keyPaymentsOverview, jsonEncode(data));
  }

  /// Get cached payments overview JSON.
  Map<String, dynamic>? getSavedPaymentsOverview() {
    final jsonStr = _prefs.getString(keyPaymentsOverview);
    if (jsonStr == null || jsonStr.isEmpty) return null;
    try {
      return jsonDecode(jsonStr) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  /// Save cached payments list JSON.
  Future<bool> savePaymentsList(List<Map<String, dynamic>> data) async {
    return _prefs.setString(keyPaymentsList, jsonEncode(data));
  }

  /// Get cached payments list JSON.
  List<Map<String, dynamic>>? getSavedPaymentsList() {
    final jsonStr = _prefs.getString(keyPaymentsList);
    if (jsonStr == null || jsonStr.isEmpty) return null;
    try {
      final decoded = jsonDecode(jsonStr);
      if (decoded is List) {
        return decoded
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Save cached complaint categories JSON.
  Future<bool> saveComplaintCategories(List<Map<String, dynamic>> data) async {
    return _prefs.setString(keyComplaintCategories, jsonEncode(data));
  }

  /// Get cached complaint categories JSON.
  List<Map<String, dynamic>>? getSavedComplaintCategories() {
    final jsonStr = _prefs.getString(keyComplaintCategories);
    if (jsonStr == null || jsonStr.isEmpty) return null;
    try {
      final decoded = jsonDecode(jsonStr);
      if (decoded is List) {
        return decoded.whereType<Map<String, dynamic>>().toList();
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Save cached staff list JSON.
  Future<bool> saveStaffList(List<Map<String, dynamic>> data) async {
    return _prefs.setString(keyStaffList, jsonEncode(data));
  }

  /// Get cached staff list JSON.
  List<Map<String, dynamic>>? getSavedStaffList() {
    final jsonStr = _prefs.getString(keyStaffList);
    if (jsonStr == null || jsonStr.isEmpty) return null;
    try {
      final decoded = jsonDecode(jsonStr);
      if (decoded is List) {
        return decoded.whereType<Map<String, dynamic>>().toList();
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Save cached complaints list JSON.
  Future<bool> saveComplaintsList(List<Map<String, dynamic>> data) async {
    return _prefs.setString(keyComplaintsList, jsonEncode(data));
  }

  /// Get cached complaints list JSON.
  List<Map<String, dynamic>>? getSavedComplaintsList() {
    final jsonStr = _prefs.getString(keyComplaintsList);
    if (jsonStr == null || jsonStr.isEmpty) return null;
    try {
      final decoded = jsonDecode(jsonStr);
      if (decoded is List) {
        return decoded.whereType<Map<String, dynamic>>().toList();
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Save cached visitors list JSON.
  Future<bool> saveVisitorsList(List<Map<String, dynamic>> data) async {
    return _prefs.setString(keyVisitorsList, jsonEncode(data));
  }

  /// Get cached visitors list JSON.
  List<Map<String, dynamic>>? getSavedVisitorsList() {
    final jsonStr = _prefs.getString(keyVisitorsList);
    if (jsonStr == null || jsonStr.isEmpty) return null;
    try {
      final decoded = jsonDecode(jsonStr);
      if (decoded is List) {
        return decoded.whereType<Map<String, dynamic>>().toList();
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}
