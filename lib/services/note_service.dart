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
  // INIT
  // =========================
  Future<void> init() async {
    final user = supabase.auth.currentUser;

    final boxName =
        user != null ? 'notes_${user.id}' : 'notes_guest';

    _box = await Hive.openBox(boxName);
  }

  // =========================
  // SAFE BOX ACCESS
  // =========================
  Future<Box> _ensureBox() async {
    if (_box == null) {
      await init();
    }
    return _box!;
  }

  // =========================
  // SAVE / UPDATE 
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

    // ALWAYS SAVE LOCALLY
    await box.put(id, data);
    dev.log("Saved locally (Hive)");

    // ❗ REQUIRE USER FOR CLOUD
    if (user == null) {
      dev.log(" No user session → cannot sync to Supabase");
      return;
    }

    try {
      final response = await supabase
          .from('notes')
          .upsert(
            {
              ...data,
              'user_id': user.id,
            },
            onConflict: 'id',
          )
          .select();

      dev.log(" Supabase SUCCESS: $response");
    } catch (e) {
      dev.log(" Supabase ERROR: $e");
    }
  }

  // =========================
  // DELETE NOTE
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
  // GET NOTES
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
  // STREAM
  // =========================
  Stream<List<Note>> listenToNotes() async* {
    final box = await _ensureBox();

    List<Note> localNotes() {
      final cached = box.values.toList();

      return cached
          .map((e) => Note.fromMap(Map<String, dynamic>.from(e)))
          .toList();
    }

    yield localNotes();

    yield* box.watch().map((event) {
      return localNotes();
    });
  }
}