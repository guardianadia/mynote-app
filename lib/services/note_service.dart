import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'dart:developer' as dev;
import 'package:hive/hive.dart';

import '../models/note.dart';

class NoteService {
  final supabase = Supabase.instance.client;
  final _uuid = const Uuid();

  Box? _box;

  // =========================
  // INIT (UNCHANGED)
  // =========================
  Future<void> init() async {
    final user = supabase.auth.currentUser;

    final boxName =
        user != null ? 'notes_${user.id}' : 'notes_guest';

    _box = await Hive.openBox(boxName);
  }

  // =========================
  //  SAFE BOX ACCESS 
  // =========================
  Future<Box> _ensureBox() async {
    if (_box == null) {
      await init(); //  auto-fix if not initialized
    }
    return _box!;
  }

  // =========================
  // SAVE / UPDATE (SAFE)
  // =========================
  Future<void> saveNote(Note note) async {
    final box = await _ensureBox();

    final user = supabase.auth.currentUser;

    final isNew = note.id.isEmpty;
    final id = isNew ? _uuid.v4() : note.id;

    final now = DateTime.now().toIso8601String();

    final data = {
      ...note.toMap(),
      'id': id,
      'user_id': user?.id,
      'created_at': isNew
          ? now
          : note.createdAt.toIso8601String(),
      'updated_at': now,
    };

    await box.put(id, data);
    dev.log("Saved locally (Hive)");

    try {
      if (user != null) {
        await supabase.from('notes').upsert(
          data,
          onConflict: 'id',
        );
        dev.log(isNew ? "Inserted (cloud)" : "Updated (cloud)");
      }
    } catch (_) {
      dev.log("Offline → saved locally only");
    }
  }

  // =========================
  // DELETE NOTE (SAFE)
  // =========================
  Future<void> deleteNote(String id) async {
    final box = await _ensureBox();

    await box.delete(id);

    try {
      await supabase.from('notes').delete().eq('id', id);
    } catch (_) {
      dev.log("Offline → delete local only");
    }
  }

  // =========================
  // GET NOTES (SAFE)
  // =========================
  Future<List<Note>> getNotes() async {
    final box = await _ensureBox();
    final user = supabase.auth.currentUser;

    try {
      if (user != null) {
        final res = await supabase
            .from('notes')
            .select()
            .eq('user_id', user.id)
            .order('updated_at', ascending: false);

        final notes =
            (res as List).map((e) => Note.fromMap(e)).toList();

        if (notes.isNotEmpty) {
          await box.clear();
          for (var n in notes) {
            box.put(n.id, n.toMap());
          }
        }

        return notes;
      }
    } catch (_) {
      dev.log("Offline → using Hive");
    }

    final cached = box.values.toList();

    return cached
        .map((e) => Note.fromMap(Map<String, dynamic>.from(e)))
        .toList();
  }

  // =========================
  // STREAM (SAFE FIX)
  // =========================
  Stream<List<Note>> listenToNotes() async* {
    final box = await _ensureBox();

    List<Note> localNotes() {
      final cached = box.values.toList();

      return cached
          .map((e) => Note.fromMap(Map<String, dynamic>.from(e)))
          .toList();
    }

    // emit existing notes immediately
    yield localNotes();

    // listen for changes
    yield* box.watch().map((event) {
      return localNotes();
    });
  }
}