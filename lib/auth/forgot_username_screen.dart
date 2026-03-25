import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
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
  String? _message;
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
      //  STEP 1: Get username from DB
      final username = await _auth.recoverUsernameByEmail(email);

      if (username == null || username.isEmpty) {
        setState(() {
          _error = 'No account found with that email.';
        });
        return;
      }

      //  STEP 2: CALL SUPABASE FUNCTION (SEND EMAIL)
      await http.post(
        Uri.parse("https://loaallkwmwgqlxhndwrf.supabase.co/functions/v1/send-username"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImxvYWFsbGt3bXdncWx4aG5kd3JmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzQwNTM2MDgsImV4cCI6MjA4OTYyOTYwOH0.75Vf0xOH4eHYufPZm24U5M0buXKaxkzlPSKBCIlhvgk",
          "apikey":"eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImxvYWFsbGt3bXdncWx4aG5kd3JmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzQwNTM2MDgsImV4cCI6MjA4OTYyOTYwOH0.75Vf0xOH4eHYufPZm24U5M0buXKaxkzlPSKBCIlhvgk"},
        body: jsonEncode({
          "email": email,
          "username": username,
        }),
      );

      //  STEP 3: SUCCESS MESSAGE
      setState(() {
        _message = "📧 Username sent to your email!";
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
      appBar: AppBar(title: const Text('Recover Username')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'Enter your recovery email to receive your username.',
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
                    : const Text('Send Username'),
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
