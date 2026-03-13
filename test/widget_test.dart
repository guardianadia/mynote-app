import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive/hive.dart';

import 'package:mynote/app.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('mynote_test_hive_');
    Hive.init(tempDir.path);
    await Hive.openBox('notesBox');
  });

  setUp(() async {
    await Hive.box('notesBox').clear();
  });

  tearDownAll(() async {
    await Hive.box('notesBox').close();
    await Hive.close();

    // optional cleanup
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  testWidgets('Splash shows MyNote text', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({'mynote_logged_in': false});

    await tester.pumpWidget(const MyNoteApp());

    expect(find.text('MyNote'), findsOneWidget);

    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
  });

  testWidgets('When logged out, app navigates to Login screen after splash',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({'mynote_logged_in': false});

    await tester.pumpWidget(const MyNoteApp());

    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    expect(find.text('Create New Account'), findsOneWidget);
    expect(find.text('Forgot username?'), findsOneWidget);
    expect(find.text('Forgot password?'), findsOneWidget);
  });

  testWidgets('When logged in, app navigates to NotesList and shows FAB',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({'mynote_logged_in': true});

    await tester.pumpWidget(const MyNoteApp());

    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    expect(find.byType(FloatingActionButton), findsOneWidget);
    expect(find.byIcon(Icons.add), findsOneWidget);
  });
}