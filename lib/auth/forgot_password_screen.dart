import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final AuthService _auth = AuthService();
  final _emailCtrl = TextEditingController();

  bool _isLoading = false;
  String? _message;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendResetEmail() async {
    final email = _emailCtrl.text.trim();

    if (email.isEmpty) {
      setState(() {
        _error = 'Enter your recovery email.';
        _message = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
      _message = null;
    });

    try {
      await _auth.sendPasswordResetEmail(email);

      if (!mounted) return;

      setState(() {
        _message = "Reset link sent to your email!";
      });
    } catch (e) {
      setState(() {
        _error = 'Error sending reset email: $e';
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
      appBar: AppBar(title: const Text('Reset Password')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'Enter your recovery email to receive a reset link.',
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
                onPressed: _isLoading ? null : _sendResetEmail,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Send Reset Email'),
              ),
            ),

            const SizedBox(height: 12),

            if (_error != null)
              Text(_error!, style: const TextStyle(color: Colors.red)),

            if (_message != null) ...[
              Text(
                _message!,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Colors.green,
                ),
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