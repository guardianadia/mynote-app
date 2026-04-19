import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'dart:developer' as dev;
import 'package:hive/hive.dart';

import '../models/note.dart';

class NoteService {
  final supabase = Supabase.instance.client;
  final _uuid = const Uuid();

  //  Hive cache (NEW)
  final Box _box = Hive.box('notes_cache');

  // =========================
  // SAVE / UPDATE (NO UI CHANGE)
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
      //  Cloud first (same as before)
      await supabase.from('notes').upsert(
        data,
        onConflict: 'id',
      );

      dev.log(isNew ? "✅ INSERTED" : "✅ UPDATED");

      //  Cache locally
      _box.put(id, data);

    } catch (e) {
      dev.log("⚠️ OFFLINE MODE: saving locally");

      //  Offline fallback
      _box.put(id, data);
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

    //  Remove from cache too
    _box.delete(id);
  }

  // =========================
  // GET NOTES (SMART FETCH)
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

      //  Sync cache
      await _box.clear();
      for (var n in notes) {
        _box.put(n.id, n.toMap());
      }

      return notes;

    } catch (e) {
      dev.log("⚠️ OFFLINE MODE: loading from cache");

      // fallback
      final cached = _box.values.toList();

      return cached
          .map((e) => Note.fromMap(Map<String, dynamic>.from(e)))
          .toList();
    }
  }

  // =========================
  // REALTIME STREAM (UNCHANGED)
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