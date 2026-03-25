import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import 'dart:developer' as dev;

import '../models/note.dart';

class NoteService {
  final supabase = Supabase.instance.client;
  final _box = Hive.box('notes_cache');
  final _uuid = const Uuid();

  // =========================
  //  SAVE / UPDATE (FINAL FIX)
  // =========================
  Future<void> saveNote(Note note) async {
    final user = supabase.auth.currentUser;

    if (user == null) {
      dev.log("USER NOT LOGGED IN");
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
      //  THIS FIXES EVERYTHING
      await supabase.from('notes').upsert(
        data,
        onConflict: 'id', // 🚨 CRITICAL
      );

      _box.put(id, data);
    } catch (e) {
      dev.log("SAVE ERROR: $e");

      // offline fallback
      _box.put(id, data);
    }
  }

  // =========================
  // DELETE NOTE
  // =========================
  Future<void> deleteNote(String id) async {
    try {
      await supabase.from('notes').delete().eq('id', id);
    } catch (e) {
      dev.log("DELETE ERROR: $e");
    }

    _box.delete(id);
  }

  // =========================
  // GET NOTES
  // =========================
  Future<List<Note>> getNotes() async {
    final user = supabase.auth.currentUser;

    try {
      final res = await supabase
          .from('notes')
          .select()
          .eq('user_id', user!.id)
          .order('updated_at', ascending: false);

      final notes =
          (res as List).map((e) => Note.fromMap(e)).toList();

      for (var n in notes) {
        _box.put(n.id, n.toMap());
      }

      return notes;
    } catch (e) {
      dev.log("FETCH ERROR: $e");

      final cached = _box.values.toList();
      return cached
          .map((e) => Note.fromMap(Map<String, dynamic>.from(e)))
          .toList();
    }
  }

  // =========================
  // REALTIME STREAM
  // =========================
  Stream<List<Note>> listenToNotes() {
    final user = supabase.auth.currentUser;

    return supabase
        .from('notes')
        .stream(primaryKey: ['id'])
        .eq('user_id', user!.id)
        .order('updated_at', ascending: false)
        .map((data) =>
            data.map((e) => Note.fromMap(e)).toList());
  }
}