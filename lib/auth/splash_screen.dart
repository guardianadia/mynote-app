import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/note_service.dart';
import '../screens/notes_list_screen.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _goNext();
  }

  Future<void> _goNext() async {
    // keep splash delay
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    final noteService = NoteService();

    // =========================
    // INIT HIVE FIRST
    // =========================
    await noteService.init();

    // =========================
    // FIX: WAIT FOR SESSION RESTORE
    // =========================
    await Future.delayed(const Duration(milliseconds: 300));

    // =========================
    // CHECK LOGIN (OFFLINE SAFE)
    // =========================
    final session = Supabase.instance.client.auth.currentSession;
    final loggedIn = session != null;

    // =========================
    // SYNC SUPABASE → HIVE (ONLINE ONLY)
    // =========================
    if (loggedIn) {
      try {
        await noteService.getNotes();
      } catch (_) {
        // offline safe
      }
    }

    if (!mounted) return;

    // =========================
    // NAVIGATION
    // =========================
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) =>
            loggedIn ? const NotesListScreen() : const LoginScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text(
          'MyNote',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}