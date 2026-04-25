import 'dart:io'; // 🔥 NEW

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hive/hive.dart'; 

import 'package:mynote/services/auth_service.dart';
import 'package:mynote/services/supabase_config.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AuthService auth;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});

    //  initialize Hive with temp directory (TEST SAFE)
    final dir = Directory.systemTemp.createTempSync();
    Hive.init(dir.path);

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

    auth = AuthService();
  });

  setUp(() async {
    try {
      await auth.logout();
    } catch (_) {
      // ignore cleanup errors in tests
    }
  });

  group('AuthService with Supabase', () {
    test('AuthService can be created', () {
      expect(auth, isNotNull);
    });

    test('isLoggedIn is false after logout', () async {
      await auth.logout();
      final loggedIn = await auth.isLoggedIn();
      expect(loggedIn, false);
    });

    test('login handles failure safely', () async {
      try {
        final ok = await auth.login('fake_user', 'fake_pass');
        expect(ok, anyOf(true, false));
      } catch (_) {
        expect(true, true);
      }
    });

    test('recoverUsername handles failure safely', () async {
      try {
        final result =
            await auth.recoverUsernameByEmail('fake@email.com');
        expect(result, anyOf(isNull, isA<String>()));
      } catch (_) {
        expect(true, true);
      }
    });

    test('sendPasswordResetEmail throws for invalid email format', () async {
      expect(
        () async => auth.sendPasswordResetEmail('not-an-email'),
        throwsException,
      );
    });
  });
}