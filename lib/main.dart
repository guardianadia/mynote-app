import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'app.dart';
import 'services/supabase_config.dart';
import 'services/note_service.dart'; 

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // =========================
  // INIT SUPABASE
  // =========================
  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );

  // =========================
  // INIT HIVE (OFFLINE CACHE)
  // =========================
  await Hive.initFlutter();
  await Hive.openBox('notes_cache'); //  (doesn't break anything)

  // =========================
  // INIT NOTE SERVICE (PER USER)
  // =========================
  final noteService = NoteService();
  await noteService.init(); //  THIS IS THE IMPORTANT ADD PER USER INITIALIZATION

  // =========================
  // START APP
  // =========================
  runApp(const MyNoteApp());
}