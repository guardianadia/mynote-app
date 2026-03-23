import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:mynote/app.dart';
import 'package:mynote/auth/login_screen.dart';
import 'package:mynote/auth/register_screen.dart';
import 'package:mynote/auth/forgot_username_screen.dart';
import 'package:mynote/auth/forgot_password_screen.dart';
import 'package:mynote/auth/splash_screen.dart';
import 'package:mynote/screens/edit_note_screen.dart';
import 'package:mynote/services/supabase_config.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});

    try {
      Supabase.instance.client;
    } catch (_) {
      await Supabase.initialize(
        url: SupabaseConfig.url,
        anonKey: SupabaseConfig.anonKey,
        authOptions: const FlutterAuthClientOptions(
          authFlowType: AuthFlowType.implicit,
        ),
      );
    }
  });

  group('MyNote Widget Tests', () {
    testWidgets('App builds successfully', (WidgetTester tester) async {
      await tester.pumpWidget(const MyNoteApp());
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('SplashScreen shows MyNote text', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SplashScreen(),
        ),
      );

      expect(find.text('MyNote'), findsOneWidget);

      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();
    });

    testWidgets('LoginScreen UI loads correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: LoginScreen(),
        ),
      );

      await tester.pump();

      expect(find.text('MyNote Login'), findsOneWidget);
      expect(find.text('Username'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Login'), findsWidgets);
      expect(find.text('Create New Account'), findsOneWidget);
      expect(find.text('Forgot username?'), findsOneWidget);
      expect(find.text('Forgot password?'), findsOneWidget);
    });

    testWidgets('RegisterScreen UI loads correctly',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: RegisterScreen(),
        ),
      );

      await tester.pump();

      expect(find.textContaining('Create'), findsWidgets);
      expect(find.text('New Username'), findsOneWidget);
      expect(find.text('New Password'), findsOneWidget);
      expect(find.text('Recovery Email'), findsOneWidget);
      expect(find.text('Security Questions (3)'), findsOneWidget);
    });

    testWidgets('ForgotUsernameScreen UI loads',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ForgotUsernameScreen(),
        ),
      );

      await tester.pump();

      expect(find.text('Forgot Username'), findsOneWidget);
      expect(find.text('Recovery Email'), findsOneWidget);
      expect(find.text('Recover Username'), findsOneWidget);
    });

    testWidgets('ForgotPasswordScreen UI loads',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ForgotPasswordScreen(),
        ),
      );

      await tester.pump();

      expect(find.text('Forgot Password'), findsOneWidget);
      expect(find.text('Recovery Email'), findsOneWidget);
      expect(find.text('Send Reset Email'), findsOneWidget);
    });

    testWidgets('EditNoteScreen UI loads', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: EditNoteScreen(),
        ),
      );

      await tester.pump();

      expect(find.text('New Note'), findsOneWidget);
      expect(find.text('Title'), findsOneWidget);
      expect(find.text('Category'), findsOneWidget);
      expect(find.text('Note'), findsOneWidget);
    });

    testWidgets('LoginScreen accepts input', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: LoginScreen(),
        ),
      );

      await tester.pump();

      final fields = find.byType(TextField);
      expect(fields, findsNWidgets(2));

      await tester.enterText(fields.at(0), 'testuser');
      await tester.enterText(fields.at(1), 'password123');
      await tester.pump();

      expect(find.text('testuser'), findsOneWidget);
      expect(find.text('password123'), findsOneWidget);
    });

    testWidgets('RegisterScreen accepts input',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: RegisterScreen(),
        ),
      );

      await tester.pump();

      final fields = find.byType(TextField);
      expect(fields, findsAtLeastNWidgets(6));

      await tester.enterText(fields.at(0), 'newuser');
      await tester.enterText(fields.at(1), 'newpassword');
      await tester.enterText(fields.at(2), 'test@email.com');
      await tester.enterText(fields.at(3), 'Elizabeth');
      await tester.enterText(fields.at(4), 'Max');
      await tester.enterText(fields.at(5), 'Purple');
      await tester.pump();

      expect(find.text('newuser'), findsOneWidget);
      expect(find.text('newpassword'), findsOneWidget);
    });
  });
}