import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final AuthService _auth = AuthService();

  // ✅ Better UX states: loading / no account / loaded
  bool _loading = true;
  bool _noAccount = false;
  List<String> _questions = const [];

  final _a1Ctrl = TextEditingController();
  final _a2Ctrl = TextEditingController();
  final _a3Ctrl = TextEditingController();
  final _newPassCtrl = TextEditingController();

  bool _hidePass = true;
  String? _msg;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  @override
  void dispose() {
    _a1Ctrl.dispose();
    _a2Ctrl.dispose();
    _a3Ctrl.dispose();
    _newPassCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadQuestions() async {
    setState(() {
      _loading = true;
      _noAccount = false;
      _error = null;
      _msg = null;
    });

    final qs = await _auth.getSecurityQuestions();

    if (!mounted) return;

    if (qs == null || qs.length < 3) {
      setState(() {
        _loading = false;
        _noAccount = true;
        _questions = const [];
      });
      return;
    }

    setState(() {
      _loading = false;
      _noAccount = false;
      _questions = qs;
    });
  }

  Future<void> _reset() async {
    if (_noAccount) {
      setState(
        () => _error = 'No account exists yet. Please create an account first.',
      );
      return;
    }

    final a1 = _a1Ctrl.text.trim();
    final a2 = _a2Ctrl.text.trim();
    final a3 = _a3Ctrl.text.trim();
    final newPass = _newPassCtrl.text;

    if (a1.isEmpty || a2.isEmpty || a3.isEmpty || newPass.isEmpty) {
      setState(() => _error = 'Please fill out all fields.');
      return;
    }

    final ok = await _auth.resetPasswordWithSecurityAnswers(
      answers: [a1, a2, a3],
      newPassword: newPass,
    );

    if (!ok) {
      setState(() {
        _msg = null;
        _error = 'Answers do not match. Try again.';
      });
      return;
    }

    setState(() {
      _error = null;
      _msg = 'Password reset successful! Go back and login.';
    });
  }

  void _backToLogin() {
    // ✅ Go back to Login (pop this screen)
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Forgot Password')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (_loading) ...[
              const Text('Loading security questions...'),
              const SizedBox(height: 12),
              const CircularProgressIndicator(),
            ] else if (_noAccount) ...[
              const Text(
                'No account exists yet.\nPlease create an account first.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _backToLogin,
                  child: const Text('Back to Login'),
                ),
              ),
            ] else ...[
              const Text('Answer all 3 questions to reset your password.'),
              const SizedBox(height: 12),

              _qBlock(_questions[0], _a1Ctrl),
              const SizedBox(height: 10),
              _qBlock(_questions[1], _a2Ctrl),
              const SizedBox(height: 10),
              _qBlock(_questions[2], _a3Ctrl),
              const SizedBox(height: 12),

              TextField(
                controller: _newPassCtrl,
                obscureText: _hidePass,
                decoration: InputDecoration(
                  labelText: 'New Password',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _hidePass ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () => setState(() => _hidePass = !_hidePass),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _reset,
                  child: const Text('Reset Password'),
                ),
              ),
              const SizedBox(height: 12),

              if (_error != null)
                Text(_error!, style: const TextStyle(color: Colors.red)),
              if (_msg != null) ...[
                Text(
                  _msg!,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: _backToLogin,
                    child: const Text('Back to Login'),
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _qBlock(String q, TextEditingController ctrl) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(q, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'Answer',
          ),
        ),
      ],
    );
  }
}
