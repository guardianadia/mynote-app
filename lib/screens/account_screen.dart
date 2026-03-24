import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final AuthService _auth = AuthService();

  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  bool _loading = false;
  String? _message;

  Future<void> _loadUser() async {
    final user = await _auth.getUser();

    if (user != null) {
      _emailCtrl.text = user['recovery_email'] ?? '';
    }
  }

  Future<void> _updateEmail() async {
    setState(() => _loading = true);

    await _auth.updateRecoveryEmail(_emailCtrl.text);

    setState(() {
      _loading = false;
      _message = "Email updated!";
    });
  }

  Future<void> _updatePassword() async {
    setState(() => _loading = true);

    await _auth.updatePassword(_passCtrl.text);

    setState(() {
      _loading = false;
      _message = "Password updated!";
    });
  }

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Account')),

      body: Padding(
        padding: const EdgeInsets.all(16),

        child: Column(
          children: [
            // EMAIL FIELD
            TextField(
              controller: _emailCtrl,
              decoration: const InputDecoration(
                labelText: 'Recovery Email',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 10),

            // UPDATE EMAIL BUTTON
            ElevatedButton(
              onPressed: _loading ? null : _updateEmail,
              child: _loading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Update Email'),
            ),

            const SizedBox(height: 20),

            // PASSWORD FIELD
            TextField(
              controller: _passCtrl,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'New Password',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 10),

            // UPDATE PASSWORD BUTTON
            ElevatedButton(
              onPressed: _loading ? null : _updatePassword,
              child: _loading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Update Password'),
            ),

            const SizedBox(height: 20),

            if (_message != null)
              Text(
                _message!,
                style: const TextStyle(color: Colors.green),
              ),
          ],
        ),
      ),
    );
  }
}