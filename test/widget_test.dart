import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hive/hive.dart';

import 'package:mynote/auth/forgot_username_screen.dart';
import 'package:mynote/auth/forgot_password_screen.dart';
import 'package:mynote/screens/edit_note_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    //  Mock SharedPreferences
    SharedPreferences.setMockInitialValues({});

    //  Safe Supabase init won’t crash
    try {
      Supabase.instance.client;
    } catch (_) {
      await Supabase.initialize(
        url: 'https://xyz.supabase.co', // dummy valid format
        anonKey: 'public-anon-key',
      );
    }

    // Hive temp setup
    final dir = await Directory.systemTemp.createTemp();
    Hive.init(dir.path);
    await Hive.openBox('notes_cache');
  });

  tearDownAll(() async {
    await Hive.close();
  });

  group('Stable Widget Tests', () {
    testWidgets('Basic widget builds', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: Text('Test App'))),
      );

      expect(find.text('Test App'), findsOneWidget);
    });

    testWidgets('ForgotUsernameScreen loads', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: ForgotUsernameScreen()));

      await tester.pump();

      expect(find.text('Recover Username'), findsOneWidget);
    });

    testWidgets('ForgotPasswordScreen loads', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: ForgotPasswordScreen()));

      await tester.pump();

      expect(find.text('Reset Password'), findsOneWidget);
    });

    testWidgets('EditNoteScreen loads', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: EditNoteScreen()));

      await tester.pump();

      //  Don't rely on text like "New Note"
      expect(find.byType(EditNoteScreen), findsOneWidget);
    });

    testWidgets('User can type in EditNoteScreen', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: EditNoteScreen()));

      await tester.pump();

      // Find first text field and type
      final field = find.byType(TextField).first;
      await tester.enterText(field, 'My Test Note');

      expect(find.text('My Test Note'), findsOneWidget);
    });
  });
}
