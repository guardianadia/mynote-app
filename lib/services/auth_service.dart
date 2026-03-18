import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const _keyUser = 'mynote_user_v1';
  static const _keyLoggedIn = 'mynote_logged_in';

  // Store ONE user for this class project (simple local auth)
  Future<bool> hasAccount() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_keyUser);
  }

  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyLoggedIn) ?? false;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyLoggedIn, false);
  }

  Future<void> clearAccount() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyUser);
    await prefs.setBool(_keyLoggedIn, false);
  }

  Future<Map<String, dynamic>?> _readUser() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyUser);
    if (raw == null) return null;
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  Future<void> _writeUser(Map<String, dynamic> user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUser, jsonEncode(user));
  }

  /// Register a new account with 3 security Q/A + recovery email
  Future<void> register({
    required String username,
    required String password,
    required String recoveryEmail,
    required List<String> securityQuestions,
    required List<String> securityAnswers,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    final user = <String, dynamic>{
      'username': username,
      'password': password,
      'recoveryEmail': recoveryEmail.toLowerCase().trim(),
      'securityQuestions': securityQuestions,
      'securityAnswers': securityAnswers.map((a) => a.toLowerCase().trim()).toList(),
    };

    await _writeUser(user);
    await prefs.setBool(_keyLoggedIn, true);
  }

  Future<bool> login(String username, String password) async {
    final prefs = await SharedPreferences.getInstance();
    final user = await _readUser();
    if (user == null) return false;

    final ok = user['username'] == username.trim() && user['password'] == password;
    if (ok) {
      await prefs.setBool(_keyLoggedIn, true);
    }
    return ok;
  }

  /// Recover username by email (returns username or null)
  Future<String?> recoverUsernameByEmail(String email) async {
    final user = await _readUser();
    if (user == null) return null;

    final saved = (user['recoveryEmail'] ?? '').toString().toLowerCase().trim();
    if (saved == email.toLowerCase().trim()) {
      return (user['username'] ?? '').toString();
    }
    return null;
  }

  /// Verify 3 answers match; then reset password
  Future<bool> resetPasswordWithSecurityAnswers({
    required List<String> answers,
    required String newPassword,
  }) async {
    final user = await _readUser();
    if (user == null) return false;

    final savedAnswers = (user['securityAnswers'] as List?)?.cast<String>() ?? [];
    if (savedAnswers.length != 3 || answers.length != 3) return false;

    final normalized = answers.map((a) => a.toLowerCase().trim()).toList();
    final ok = savedAnswers[0] == normalized[0] &&
        savedAnswers[1] == normalized[1] &&
        savedAnswers[2] == normalized[2];

    if (!ok) return false;

    user['password'] = newPassword;
    await _writeUser(user);
    return true;
  }

  /// Show the security questions to the user (for the forgot-password screen)
  Future<List<String>?> getSecurityQuestions() async {
    final user = await _readUser();
    if (user == null) return null;
    final qs = (user['securityQuestions'] as List?)?.cast<String>();
    return qs;
  }
  Future<Map<String,dynamic>?> getUser() async{
    return await _readUser();
  }
  Future<void> updateRecoveryEmail(String email) async {
    final user = await _readUser();
    if (user==null) return;

    user['recoveryEmail'] = email.toLowerCase().trim();
    await _writeUser(user);
  }
  Future<void> updatePassword(String newPassword) async {
    final user = await _readUser();
    if (user==null) return;

    user['password'] = newPassword;
    await _writeUser(user);
  }

  
}