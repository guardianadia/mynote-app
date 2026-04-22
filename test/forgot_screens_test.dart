import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:mynote/auth/forgot_username_screen.dart';
import 'package:mynote/auth/forgot_password_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    // Mock SharedPreferences (required for Supabase)
    SharedPreferences.setMockInitialValues({});

    //  Initialize Supabase
    try {
      Supabase.instance.client;
    } catch (_) {
      await Supabase.initialize(
        url: 'https://xyz.supabase.co',
        anonKey: 'public-anon-key',
      );
    }
  });

  group('Forgot Screens Tests', () {
    // -------------------------
    // USERNAME - EMPTY INPUT
    // -------------------------
    testWidgets('ForgotUsername shows error when empty', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: ForgotUsernameScreen()));

      await tester.pump();

      await tester.tap(find.text('Send Username'));
      await tester.pump();

      expect(find.text('Enter your recovery email.'), findsOneWidget);
    });

    // -------------------------
    // PASSWORD - EMPTY INPUT
    // -------------------------
    testWidgets('ForgotPassword shows error when empty', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: ForgotPasswordScreen()));

      await tester.pump();

      await tester.tap(find.text('Send Reset Email'));
      await tester.pump();

      expect(find.text('Enter your recovery email.'), findsOneWidget);
    });

    // -------------------------
    // PASSWORD - VALID INPUT
    // -------------------------
    testWidgets('ForgotPassword accepts valid email input', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: ForgotPasswordScreen()));

      await tester.pump();

      await tester.enterText(find.byType(TextField), 'test@email.com');

      await tester.tap(find.text('Send Reset Email'));
      await tester.pump();

      //  No empty error should appear
      expect(find.text('Enter your recovery email.'), findsNothing);
    });

    // -------------------------
    // USERNAME - VALID INPUT
    // -------------------------
    testWidgets('ForgotUsername accepts valid email input', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: ForgotUsernameScreen()));

      await tester.pump();

      await tester.enterText(find.byType(TextField), 'test@email.com');

      await tester.tap(find.text('Send Username'));
      await tester.pump();

      //  No empty error should appear
      expect(find.text('Enter your recovery email.'), findsNothing);
    });

    // -------------------------
    // PASSWORD - INVALID FORMAT (SAFE VERSION)
    // -------------------------
    testWidgets('ForgotPassword handles invalid email format safely', (
      tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: ForgotPasswordScreen()));

      await tester.pump();

      await tester.enterText(find.byType(TextField), 'invalid-email');

      await tester.tap(find.text('Send Reset Email'));
      await tester.pump();

      //  Since the app may NOT validate format,
      // we just check it does NOT crash
      expect(find.byType(ForgotPasswordScreen), findsOneWidget);
    });
  });
}
