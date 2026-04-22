import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hive/hive.dart';

import 'package:mynote/screens/edit_note_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

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

    //  Setup Hive (used in the app)
    final dir = await Directory.systemTemp.createTemp();
    Hive.init(dir.path);
    await Hive.openBox('notes_cache');
  });

  tearDownAll(() async {
    await Hive.close();
  });

  group('EditNoteScreen Tests', () {
    testWidgets('Screen loads', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: EditNoteScreen()));

      await tester.pump();

      expect(find.byType(EditNoteScreen), findsOneWidget);
    });

    testWidgets('Has text fields', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: EditNoteScreen()));

      await tester.pump();

      expect(find.byType(TextField), findsWidgets);
    });

    testWidgets('User can type in a field', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: EditNoteScreen()));

      await tester.pump();

      final field = find.byType(TextField).first;
      await tester.enterText(field, 'Test Note');

      expect(find.text('Test Note'), findsOneWidget);
    });

    testWidgets('Has interactive elements (buttons)', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: EditNoteScreen()));

      await tester.pump();

      final hasButtons =
          find.byType(IconButton).evaluate().isNotEmpty ||
          find.byType(FloatingActionButton).evaluate().isNotEmpty ||
          find.byType(TextButton).evaluate().isNotEmpty;

      expect(hasButtons, true);
    });
  });
}
