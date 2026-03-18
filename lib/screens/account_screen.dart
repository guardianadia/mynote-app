import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final AuthService _auth = AuthService();

  final _oldEmailCtrl = TextEditingController();
  final _oldPassCtrl = TextEditingController();

  final _newEmailCtrl = TextEditingController();
  final _confirmEmailCtrl = TextEditingController();

  final _newPassCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();

  bool _hideOld = true;
  bool _hideNew = true;
  bool _hideConfirm = true;

  String? _msg;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCurrentInfo();
  }

  Future<void> _loadCurrentInfo() async {
    final user = await _auth.getUser();

    if (user != null) {
      setState(() {
        _oldEmailCtrl.text = user['recoveryEmail'] ?? '';
        _oldPassCtrl.text = user['password'] ?? '';
      });
    }
  }

  Future<void> _save() async {
    final newEmail = _newEmailCtrl.text.trim();
    final confirmEmail = _confirmEmailCtrl.text.trim();

    final newPass = _newPassCtrl.text;
    final confirmPass = _confirmPassCtrl.text;

    if (newEmail.isEmpty && newPass.isEmpty) {
      setState(() => _error = "Enter a new email or password.");
      return;
    }

    if (newEmail.isNotEmpty && newEmail != confirmEmail) {
      setState(() => _error = "Emails do not match.");
      return;
    }

    if (newPass.isNotEmpty && newPass != confirmPass) {
      setState(() => _error = "Passwords do not match.");
      return;
    }

    if (newEmail.isNotEmpty) {
      await _auth.updateRecoveryEmail(newEmail);
    }

    if (newPass.isNotEmpty) {
      await _auth.updatePassword(newPass);
    }

    setState(() {
      _msg = "Account updated successfully.";
      _error = null;
    });

    _newEmailCtrl.clear();
    _confirmEmailCtrl.clear();
    _newPassCtrl.clear();
    _confirmPassCtrl.clear();

    _loadCurrentInfo();
  }

  @override
  void dispose() {
    _oldEmailCtrl.dispose();
    _oldPassCtrl.dispose();
    _newEmailCtrl.dispose();
    _confirmEmailCtrl.dispose();
    _newPassCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }

  Widget _sectionTitle(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Account Settings")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [

            _sectionTitle("Current Email"),
            TextField(
              controller: _oldEmailCtrl,
              readOnly: true,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),

            _sectionTitle("Current Password"),
            TextField(
              controller: _oldPassCtrl,
              obscureText: _hideOld,
              readOnly: true,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(_hideOld
                      ? Icons.visibility
                      : Icons.visibility_off),
                  onPressed: () => setState(() => _hideOld = !_hideOld),
                ),
              ),
            ),

            const SizedBox(height: 24),

            _sectionTitle("New Email"),
            TextField(
              controller: _newEmailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 10),

            _sectionTitle("Confirm New Email"),
            TextField(
              controller: _confirmEmailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 24),

            _sectionTitle("New Password"),
            TextField(
              controller: _newPassCtrl,
              obscureText: _hideNew,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(_hideNew
                      ? Icons.visibility
                      : Icons.visibility_off),
                  onPressed: () => setState(() => _hideNew = !_hideNew),
                ),
              ),
            ),

            const SizedBox(height: 10),

            _sectionTitle("Confirm New Password"),
            TextField(
              controller: _confirmPassCtrl,
              obscureText: _hideConfirm,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(_hideConfirm
                      ? Icons.visibility
                      : Icons.visibility_off),
                  onPressed: () =>
                      setState(() => _hideConfirm = !_hideConfirm),
                ),
              ),
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _save,
                child: const Text("Save Changes"),
              ),
            ),

            const SizedBox(height: 12),

            if (_error != null)
              Text(_error!, style: const TextStyle(color: Colors.red)),

            if (_msg != null)
              Text(_msg!, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}