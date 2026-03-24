import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class ForgotUsernameScreen extends StatefulWidget {
  const ForgotUsernameScreen({super.key});

  @override
  State<ForgotUsernameScreen> createState() => _ForgotUsernameScreenState();
}

class _ForgotUsernameScreenState extends State<ForgotUsernameScreen> {
  final AuthService _auth = AuthService();
  final _emailCtrl = TextEditingController();

  bool _isLoading = false;
  String? _result;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _recover() async {
    final email = _emailCtrl.text.trim();

    if (email.isEmpty) {
      setState(() {
        _error = 'Enter your recovery email.';
        _result = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
      _result = null;
    });

    try {
      final username = await _auth.recoverUsernameByEmail(email);

      if (username == null || username.isEmpty) {
        setState(() {
          _error = 'No account found with that email.';
        });
        return;
      }

      setState(() {
        _result = 'Your username is: $username';
      });
    } catch (e) {
      setState(() {
        _error = 'Error recovering username: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _backToLogin() {
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Forgot Username')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'Enter your recovery email to find your username.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),

            TextField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Recovery Email',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _recover,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Recover Username'),
              ),
            ),

            const SizedBox(height: 12),

            if (_error != null)
              Text(_error!, style: const TextStyle(color: Colors.red)),

            if (_result != null) ...[
              Text(
                _result!,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _backToLogin,
                  child: const Text('Back to Login'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
