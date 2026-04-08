import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'dart:developer' as dev;

import 'app.dart';
import 'services/supabase_config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );

  // 🔥 SAFE LOGGING (NO WARNING)
  Supabase.instance.client.auth.onAuthStateChange.listen((data) {
    final event = data.event;

    if (event == AuthChangeEvent.passwordRecovery) {
      dev.log("🔐 PASSWORD RECOVERY DETECTED");
    }
  });

  // Hive (offline cache)
  await Hive.initFlutter();
  await Hive.openBox('notes_cache');

  runApp(const MyNoteApp());
}