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
  final _newEmailCtrl = TextEditingController();
  final _confirmEmailCtrl = TextEditingController();
  final _newPassCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();

  bool _hideNewPass = true;
  bool _hideConfirmPass = true;

  String? _message;
  String? _error;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentEmail();
  }

  Future<void> _loadCurrentEmail() async {
    final user = await _auth.getUser();
    if (user != null) {
      setState(() {
        _oldEmailCtrl.text = user['recovery_email'] ?? '';
      });
    }
  }

  Future<void> _saveChanges() async {
    setState(() => _loading = true);

    final newEmail = _newEmailCtrl.text.trim();
    final confirmEmail = _confirmEmailCtrl.text.trim();
    final newPass = _newPassCtrl.text;
    final confirmPass = _confirmPassCtrl.text;

    // VALIDATION
    if (newEmail.isEmpty && newPass.isEmpty) {
      setState(() {
        _error = "Enter a new email or password.";
        _loading = false;
      });
      return;
    }

    if (newEmail.isNotEmpty && newEmail != confirmEmail) {
      setState(() {
        _error = "Emails do not match.";
        _loading = false;
      });
      return;
    }

    if (newPass.isNotEmpty && newPass != confirmPass) {
      setState(() {
        _error = "Passwords do not match.";
        _loading = false;
      });
      return;
    }

    try {
      if (newEmail.isNotEmpty) await _auth.updateRecoveryEmail(newEmail);
      if (newPass.isNotEmpty) await _auth.updatePassword(newPass);

      setState(() {
        _message = "Account updated successfully!";
        _error = null;
        _newEmailCtrl.clear();
        _confirmEmailCtrl.clear();
        _newPassCtrl.clear();
        _confirmPassCtrl.clear();
      });

      _loadCurrentEmail();
    } catch (e) {
      setState(() {
        _error = "Update failed: $e";
      });
    }

    setState(() => _loading = false);
  }

  Future<void> _deleteAccount() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete Account"),
        content: const Text(
            "Are you sure you want to delete your account? This action cannot be undone."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              "Delete",
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _auth.clearAccount();
        if (!mounted) return;
        Navigator.pop(context); // go back after deleting
      } catch (e) {
        setState(() => _error = "Delete failed: $e");
      }
    }
  }

  @override
  void dispose() {
    _oldEmailCtrl.dispose();
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
            // CURRENT EMAIL
            _sectionTitle("Current Email"),
            TextField(
              controller: _oldEmailCtrl,
              readOnly: true,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),

            // NEW EMAIL
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

            // NEW PASSWORD
            _sectionTitle("New Password"),
            TextField(
              controller: _newPassCtrl,
              obscureText: _hideNewPass,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(
                      _hideNewPass ? Icons.visibility : Icons.visibility_off),
                  onPressed: () =>
                      setState(() => _hideNewPass = !_hideNewPass),
                ),
              ),
            ),
            const SizedBox(height: 10),
            _sectionTitle("Confirm New Password"),
            TextField(
              controller: _confirmPassCtrl,
              obscureText: _hideConfirmPass,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(_hideConfirmPass
                      ? Icons.visibility
                      : Icons.visibility_off),
                  onPressed: () =>
                      setState(() => _hideConfirmPass = !_hideConfirmPass),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // ERROR / SUCCESS MESSAGE
            if (_error != null)
              Text(_error!, style: const TextStyle(color: Colors.red)),
            if (_message != null)
              Text(_message!,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.green)),

            const SizedBox(height: 20),

            // SAVE CHANGES BUTTON
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _saveChanges,
                child: _loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text("Save Changes"),
              ),
            ),
            const SizedBox(height: 20),

            // DELETE ACCOUNT BUTTON
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _deleteAccount,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                ),
                child: const Text("Delete Account"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}