import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'dart:developer' as dev;

import '../models/note.dart';

class NoteService {
  final supabase = Supabase.instance.client;
  final _uuid = const Uuid();

  // =========================
  // SAVE / UPDATE (FINAL CLEAN FIX)
  // =========================
  Future<void> saveNote(Note note) async {
    final user = supabase.auth.currentUser;

    if (user == null) {
      dev.log("❌ USER NOT LOGGED IN");
      return;
    }

    final isNew = note.id.isEmpty;
    final id = isNew ? _uuid.v4() : note.id;

    final now = DateTime.now().toIso8601String();

    final data = {
      ...note.toMap(),
      'id': id,
      'user_id': user.id,
      'created_at': isNew
          ? now
          : note.createdAt.toIso8601String(),
      'updated_at': now,
    };

    try {
      // 🔥 UPSERT = NO DUPLICATES + ALWAYS UPDATE
      await supabase.from('notes').upsert(
        data,
        onConflict: 'id',
      );

      dev.log(isNew ? "✅ INSERTED" : "✅ UPDATED");
    } catch (e) {
      dev.log("❌ SAVE ERROR: $e");
    }
  }

  // =========================
  // DELETE NOTE
  // =========================
  Future<void> deleteNote(String id) async {
    try {
      await supabase.from('notes').delete().eq('id', id);
      dev.log("🗑️ Deleted note");
    } catch (e) {
      dev.log("❌ DELETE ERROR: $e");
    }
  }

  // =========================
  // GET NOTES (PURE SUPABASE)
  // =========================
  Future<List<Note>> getNotes() async {
    final user = supabase.auth.currentUser;

    if (user == null) return [];

    try {
      final res = await supabase
          .from('notes')
          .select()
          .eq('user_id', user.id)
          .order('updated_at', ascending: false);

      final notes =
          (res as List).map((e) => Note.fromMap(e)).toList();

      return notes;
    } catch (e) {
      dev.log("❌ FETCH ERROR: $e");
      return [];
    }
  }

  // =========================
  // REALTIME STREAM (OPTIONAL)
  // =========================
  Stream<List<Note>> listenToNotes() {
    final user = supabase.auth.currentUser;

    if (user == null) {
      return const Stream.empty();
    }

    return supabase
        .from('notes')
        .stream(primaryKey: ['id'])
        .eq('user_id', user.id)
        .order('updated_at', ascending: false)
        .map((data) =>
            data.map((e) => Note.fromMap(e)).toList());
  }
}