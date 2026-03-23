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
  String? _msg;
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
        _error = 'Please enter your recovery email.';
        _msg = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
      _msg = null;
    });

    try {
      await _auth.sendPasswordResetEmail(email);

      if (!mounted) return;

      setState(() {
        _msg =
            'Password reset email sent. Please check your inbox and follow the reset link.';
      });
    } catch (e) {
      setState(() {
        _error = 'Could not send reset email: $e';
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
      appBar: AppBar(title: const Text('Forgot Password')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'Enter your recovery email and we will send you a password reset link.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Recovery Email',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
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
            if (_msg != null) ...[
              Text(
                _msg!,
                style: const TextStyle(fontWeight: FontWeight.w700),
                textAlign: TextAlign.center,
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