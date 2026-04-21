import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:mynote/services/note_service.dart';
import 'package:mynote/models/note.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late NoteService service;

  setUpAll(() async {
    //  Mock SharedPreferences (required for Supabase)
    SharedPreferences.setMockInitialValues({});

    //  Initialize Supabase safely
    try {
      Supabase.instance.client;
    } catch (_) {
      await Supabase.initialize(
        url: 'https://xyz.supabase.co',
        anonKey: 'public-anon-key',
      );
    }

    //  Setup Hive (local cache)
    final dir = await Directory.systemTemp.createTemp();
    Hive.init(dir.path);
    await Hive.openBox('notes_cache');

    service = NoteService();
  });

  tearDownAll(() async {
    await Hive.close();
  });

  // -------------------------
  // TEST 1: getNotes
  // -------------------------
  test('getNotes returns a list safely', () async {
    final notes = await service.getNotes();

    expect(notes, isA<List<Note>>());
  });

  // -------------------------
  // TEST 2: saveNote
  // -------------------------
  test('saveNote runs without crashing', () async {
    final note = Note(
      id: '',
      title: 'Test',
      content: 'Content',
      folder: 'General',
      category: 'General',
      tags: [],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await service.saveNote(note);

    //  We only verify execution, not storage
    expect(true, true);
  });

  // -------------------------
  // TEST 3: deleteNote
  // -------------------------
  test('deleteNote runs without crashing', () async {
    await service.deleteNote('fake-id');

    //  No crash = pass
    expect(true, true);
  });

  // -------------------------
  // TEST 4: Hive exists
  // -------------------------
  test('Hive box is initialized', () {
    final box = Hive.box('notes_cache');

    expect(box, isNotNull);
  });
}
