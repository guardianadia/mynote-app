import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _client = Supabase.instance.client;

  // =========================
  // CHECK LOGIN
  // =========================
  Future<bool> isLoggedIn() async {
    return _client.auth.currentSession != null;
  }

  // =========================
  // LOGOUT
  // =========================
  Future<void> logout() async {
    await _client.auth.signOut();
  }

  // =========================
  // REGISTER USER
  // =========================
  Future<void> register({
    required String username,
    required String password,
    required String recoveryEmail,
    required List<String> securityQuestions,
    required List<String> securityAnswers,
  }) async {
    final email = recoveryEmail.trim().toLowerCase();

    final response = await _client.auth.signUp(
      email: email,
      password: password,
    );

    final user = response.user;
    if (user == null) {
      throw Exception('Signup failed.');
    }

    await _client.from('profiles').insert({
      'id': user.id,
      'username': username.trim(),
      'recovery_email': email,
      'security_questions': securityQuestions,
      'security_answers': securityAnswers
          .map((a) => a.toLowerCase().trim())
          .toList(),
    });
  }

  // =========================
  // LOGIN
  // =========================
  Future<bool> login(String username, String password) async {
    try {
      final result = await _client
          .from('profiles')
          .select('recovery_email')
          .eq('username', username.trim())
          .maybeSingle();

      if (result == null) return false;

      final email = result['recovery_email'] as String?;
      if (email == null) return false;

      await _client.auth.signInWithPassword(email: email, password: password);

      return true;
    } catch (_) {
      return false;
    }
  }

  // =========================
  // FIXED PASSWORD RESET EMAIL
  // =========================
  Future<void> sendPasswordResetEmail(String email) async {
    final cleanEmail = email.trim().toLowerCase();

    final response = await _client.functions.invoke(
      'send-reset-email',
      body: {'email': cleanEmail},
    );

    //  NEW WAY TO HANDLE ERRORS
    if (response.status != 200) {
      throw Exception(response.data);
    }
  }

  // =========================
  // RECOVER USERNAME
  // =========================
  Future<String?> recoverUsernameByEmail(String email) async {
    final result = await _client
        .from('profiles')
        .select('username')
        .eq('recovery_email', email.toLowerCase().trim())
        .maybeSingle();

    return result?['username'] as String?;
  }

  // =========================
  // GET USER PROFILE
  // =========================
  Future<Map<String, dynamic>?> getUser() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;

    final result = await _client
        .from('profiles')
        .select()
        .eq('id', user.id)
        .maybeSingle();

    return result;
  }

  // =========================
  // UPDATE RECOVERY EMAIL
  // =========================
  Future<void> updateRecoveryEmail(String email) async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    await _client
        .from('profiles')
        .update({'recovery_email': email.trim().toLowerCase()})
        .eq('id', user.id);
  }

  // =========================
  // UPDATE PASSWORD (LOGGED IN USER)
  // =========================
  Future<void> updatePassword(String newPassword) async {
    await _client.auth.updateUser(UserAttributes(password: newPassword));
  }

  // =========================
  // GET SECURITY QUESTIONS
  // =========================
  Future<List<String>?> getSecurityQuestions() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;

    final result = await _client
        .from('profiles')
        .select('security_questions')
        .eq('id', user.id)
        .maybeSingle();

    return result == null
        ? null
        : List<String>.from(result['security_questions'] ?? []);
  }

  // =========================
  // VERIFY SECURITY ANSWERS
  // =========================
  Future<bool> verifySecurityAnswers(List<String> answers) async {
    final user = _client.auth.currentUser;
    if (user == null) return false;

    final result = await _client
        .from('profiles')
        .select('security_answers')
        .eq('id', user.id)
        .maybeSingle();

    if (result == null) return false;

    final stored = List<String>.from(result['security_answers'] ?? []);
    final input = answers.map((a) => a.toLowerCase().trim()).toList();

    if (stored.length != input.length) return false;

    for (int i = 0; i < stored.length; i++) {
      if (stored[i] != input[i]) return false;
    }

    return true;
  }

  // =========================
  // DELETE ACCOUNT
  // =========================
  Future<void> clearAccount() async {
    final user = _client.auth.currentUser;

    if (user != null) {
      await _client.from('notes').delete().eq('user_id', user.id);
      await _client.from('profiles').delete().eq('id', user.id);
    }

    await _client.auth.signOut();
  }
}
