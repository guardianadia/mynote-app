import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hive/hive.dart';

import 'package:mynote/auth/login_screen.dart';
import 'package:mynote/auth/register_screen.dart';
import 'package:mynote/auth/forgot_username_screen.dart';
import 'package:mynote/auth/forgot_password_screen.dart';
import 'package:mynote/auth/splash_screen.dart';
import 'package:mynote/screens/edit_note_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    // Mock local storage
    SharedPreferences.setMockInitialValues({});

    // Fake Supabase init (needed because AuthService reads it)
    await Supabase.initialize(
      url: 'https://test.supabase.co',
      anonKey: 'test-key',
    );

    // Hive temp init (safe for tests)
    final dir = await Directory.systemTemp.createTemp();
    Hive.init(dir.path);
    await Hive.openBox('notes_cache');
  });

  tearDownAll(() async {
    await Hive.close();
  });

  group('MyNote Widget Tests', () {

    testWidgets('Basic widget builds', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: Text('Test App')),
        ),
      );
      await tester.pump();

      expect(find.text('Test App'), findsOneWidget);
    });

    //  SPLASH FIX (NO HANG)
    testWidgets('SplashScreen shows MyNote text', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: SplashScreen()),
      );

      // Render ONLY the first frame
      await tester.pump();

      // DO NOT pump more time (avoids delay + navigation)
      expect(find.text('MyNote'), findsOneWidget);
    });

    testWidgets('LoginScreen loads', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: LoginScreen()),
      );
      await tester.pump();

      expect(find.text('Login'), findsOneWidget);
    });

    testWidgets('RegisterScreen loads', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: RegisterScreen()),
      );
      await tester.pump();

      expect(find.textContaining('Create'), findsWidgets);
    });

    testWidgets('ForgotUsernameScreen loads', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: ForgotUsernameScreen()),
      );
      await tester.pump();

      expect(find.text('Recover Username'), findsOneWidget);
    });

    testWidgets('ForgotPasswordScreen loads', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: ForgotPasswordScreen()),
      );
      await tester.pump();

      expect(find.text('Reset Password'), findsOneWidget);
    });

    testWidgets('EditNoteScreen loads', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: EditNoteScreen()),
      );
      await tester.pump();

      expect(find.text('New Note'), findsOneWidget);
    });
  });
}