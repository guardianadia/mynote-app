import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<bool> isLoggedIn() async {
    return _client.auth.currentSession != null;
  }

  Future<void> logout() async {
    await _client.auth.signOut();
  }

  Future<void> register({
    required String username,
    required String password,
    required String recoveryEmail,
    required List<String> securityQuestions,
    required List<String> securityAnswers,
  }) async {
    final email = recoveryEmail.trim().toLowerCase();
    final cleanUsername = username.trim();

    final response = await _client.auth.signUp(
      email: email,
      password: password,
    );

    final user = response.user;
    if (user == null) {
      throw Exception('Signup failed. No user returned.');
    }

    await _client.from('profiles').insert({
      'id': user.id,
      'username': cleanUsername,
      'recovery_email': email,
      'security_questions': securityQuestions,
      'security_answers': securityAnswers
          .map((a) => a.toLowerCase().trim())
          .toList(),
    });
  }

  Future<bool> login(String username, String password) async {
    final usernameTrimmed = username.trim();

    final result = await _client
        .from('profiles')
        .select('recovery_email')
        .eq('username', usernameTrimmed)
        .maybeSingle();

    if (result == null) return false;

    final email = result['recovery_email'] as String?;
    if (email == null || email.isEmpty) return false;

    try {
      await _client.auth.signInWithPassword(email: email, password: password);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    await _client.auth.resetPasswordForEmail(
      email.trim().toLowerCase(),
      redirectTo: 'https://mynote-reset-page.vercel.app',
    );
  }

  Future<String?> recoverUsernameByEmail(String email) async {
    final result = await _client
        .from('profiles')
        .select('username')
        .eq('recovery_email', email.toLowerCase().trim())
        .maybeSingle();

    if (result == null) return null;

    return result['username'] as String?;
  }

  Future<List<String>?> getSecurityQuestions() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;

    final result = await _client
        .from('profiles')
        .select('security_questions')
        .eq('id', user.id)
        .maybeSingle();

    if (result == null) return null;

    return List<String>.from(result['security_questions'] ?? []);
  }

  Future<void> clearAccount() async {
    final user = _client.auth.currentUser;

    if (user != null) {
      await _client.from('notes').delete().eq('user_id', user.id);
      await _client.from('profiles').delete().eq('id', user.id);
    }

    await _client.auth.signOut();
  }
}
