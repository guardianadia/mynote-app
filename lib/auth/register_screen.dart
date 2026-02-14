import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../screens/notes_list_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final AuthService _auth = AuthService();

  final _userCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();

  final _a1Ctrl = TextEditingController();
  final _a2Ctrl = TextEditingController();
  final _a3Ctrl = TextEditingController();

  bool _hidePass = true;
  String? _error;

  static const _questions = <String>[
    'What city were you born in?',
    'What is the name of your first pet?',
    'What is your favorite color?',
  ];

  @override
  void dispose() {
    _userCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    _emailCtrl.dispose();
    _a1Ctrl.dispose();
    _a2Ctrl.dispose();
    _a3Ctrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    final username = _userCtrl.text.trim();
    final password = _passCtrl.text;
    final confirm = _confirmCtrl.text;
    final email = _emailCtrl.text.trim();
    

    final a1 = _a1Ctrl.text.trim();
    final a2 = _a2Ctrl.text.trim();
    final a3 = _a3Ctrl.text.trim();

    if (username.isEmpty || password.isEmpty || email.isEmpty || a1.isEmpty || a2.isEmpty || a3.isEmpty) {
      setState(() => _error = 'Please fill out all fields.');
      return;
    }
    // Confirm password
    if(password !=confirm){
      setState(()=> _error ='Passwords do not match.');
      return; // stop registration if they dont match.
        
      
    }

    // For this class project: allow only one account; overwrite if already exists
    await _auth.register(
      username: username,
      password: password,
      recoveryEmail: email,
      securityQuestions: _questions,
      securityAnswers: [a1, a2, a3],
    );

    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const NotesListScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Account')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _userCtrl,
              decoration: const InputDecoration(labelText: 'New Username', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: _passCtrl,
              obscureText: _hidePass,
              decoration: InputDecoration(
                labelText: 'New Password',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(_hidePass ? Icons.visibility : Icons.visibility_off),
                  onPressed: () => setState(() => _hidePass = !_hidePass),
                ),
              ),
            ),

            const SizedBox(height: 12),
            TextField(
              controller: _confirmCtrl,
              obscureText: _hidePass,
              decoration: InputDecoration(
                labelText: 'Confirm Password',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                icon: Icon(_hidePass ? Icons.visibility : Icons.visibility_off),
                 onPressed: () => setState(() => _hidePass = !_hidePass),   
                 ),
                ),
              ),
            
            const SizedBox(height: 12),

            TextField(
              controller: _emailCtrl,
              decoration: const InputDecoration(labelText: 'Recovery Email', border: OutlineInputBorder()),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),

            const Align(
              alignment: Alignment.centerLeft,
              child: Text('Security Questions (3)', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
            const SizedBox(height: 8),

            _qBlock(_questions[0], _a1Ctrl),
            const SizedBox(height: 10),
            _qBlock(_questions[1], _a2Ctrl),
            const SizedBox(height: 10),
            _qBlock(_questions[2], _a3Ctrl),

            const SizedBox(height: 10),
            if (_error != null) Text(_error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 10),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _register,
                child: const Text('Create Account'),
              ),
            ),
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
          decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'Answer'),
        ),
      ],
    );
  }
}