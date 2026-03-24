import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../screens/notes_list_screen.dart';
import 'register_screen.dart';
import 'forgot_username_screen.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final AuthService _auth = AuthService();

  bool _hidePass = true;
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _userCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final u = _userCtrl.text.trim();
    final p = _passCtrl.text.trim();

    if (u.isEmpty || p.isEmpty) {
      setState(() => _error = 'Enter username and password.');
      return;
    }

    setState(() {
      _error = null;
      _isLoading = true;
    });

    try {
      final ok = await _auth.login(u, p);

      if (!ok) {
        setState(() => _error = 'Wrong username or password.');
        return;
      }

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const NotesListScreen()),
      );
    } catch (e) {
      setState(() {
        _error = 'Login failed: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _goToRegister() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const RegisterScreen()),
    );
  }

  void _goToForgotUsername() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ForgotUsernameScreen()),
    );
  }

  void _goToForgotPassword() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(height: 12),
            const Text(
              'MyNote Login',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _userCtrl,
              decoration: const InputDecoration(
                labelText: 'Username',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _passCtrl,
              obscureText: _hidePass,
              decoration: InputDecoration(
                labelText: 'Password',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(
                    _hidePass ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () => setState(() => _hidePass = !_hidePass),
                ),
              ),
            ),
            const SizedBox(height: 10),
            if (_error != null)
              Text(_error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _login,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Login'),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _isLoading ? null : _goToRegister,
                child: const Text('Create New Account'),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: _isLoading ? null : _goToForgotUsername,
                  child: const Text('Forgot username?'),
                ),
                TextButton(
                  onPressed: _isLoading ? null : _goToForgotPassword,
                  child: const Text('Forgot password?'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
