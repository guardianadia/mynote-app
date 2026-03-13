import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mynote/services/auth_service.dart';

void main() {
  late AuthService auth;

  setUp(() {
    auth = AuthService();
    // Fresh storage before every test
    SharedPreferences.setMockInitialValues({});
  });

  group('AuthService - Register/Login/Logout + Recovery', () {
    test('VALID: register creates an account and logs in', () async {
      await auth.register(
        username: 'nadia',
        password: '1234',
        recoveryEmail: 'nadia@email.com',
        securityQuestions: const ['Q1', 'Q2', 'Q3'],
        securityAnswers: const ['a1', 'a2', 'a3'],
      );

      expect(await auth.hasAccount(), true);
      expect(await auth.isLoggedIn(), true);
    });

    test('VALID: login succeeds with correct username/password', () async {
      await auth.register(
        username: 'user1',
        password: 'pass1',
        recoveryEmail: 'user1@email.com',
        securityQuestions: const ['Q1', 'Q2', 'Q3'],
        securityAnswers: const ['a1', 'a2', 'a3'],
      );

      // logout first so login actually tests the login path
      await auth.logout();
      expect(await auth.isLoggedIn(), false);

      final ok = await auth.login('user1', 'pass1');
      expect(ok, true);
      expect(await auth.isLoggedIn(), true);
    });

    test('INVALID: login fails with wrong password', () async {
      await auth.register(
        username: 'user1',
        password: 'pass1',
        recoveryEmail: 'user1@email.com',
        securityQuestions: const ['Q1', 'Q2', 'Q3'],
        securityAnswers: const ['a1', 'a2', 'a3'],
      );

      await auth.logout();

      final ok = await auth.login('user1', 'WRONG');
      expect(ok, false);
      expect(await auth.isLoggedIn(), false);
    });

    test('INVALID: login fails if no account exists', () async {
      final ok = await auth.login('any', 'any');
      expect(ok, false);
      expect(await auth.isLoggedIn(), false);
    });

    test('VALID: logout sets loggedIn = false', () async {
      await auth.register(
        username: 'u',
        password: 'p',
        recoveryEmail: 'u@email.com',
        securityQuestions: const ['Q1', 'Q2', 'Q3'],
        securityAnswers: const ['a1', 'a2', 'a3'],
      );

      expect(await auth.isLoggedIn(), true);

      await auth.logout();
      expect(await auth.isLoggedIn(), false);
    });

    test(
      'VALID: recoverUsernameByEmail returns username (case-insensitive email)',
      () async {
        await auth.register(
          username: 'NadiaG',
          password: 'p',
          recoveryEmail: 'NADIA@EMAIL.COM',
          securityQuestions: const ['Q1', 'Q2', 'Q3'],
          securityAnswers: const ['a1', 'a2', 'a3'],
        );

        final u = await auth.recoverUsernameByEmail('nadia@email.com');
        expect(u, 'NadiaG');
      },
    );

    test(
      'INVALID: recoverUsernameByEmail returns null for wrong email',
      () async {
        await auth.register(
          username: 'user',
          password: 'p',
          recoveryEmail: 'user@email.com',
          securityQuestions: const ['Q1', 'Q2', 'Q3'],
          securityAnswers: const ['a1', 'a2', 'a3'],
        );

        final u = await auth.recoverUsernameByEmail('wrong@email.com');
        expect(u, isNull);
      },
    );

    test(
      'VALID: resetPasswordWithSecurityAnswers succeeds with correct answers',
      () async {
        await auth.register(
          username: 'user',
          password: 'oldPass',
          recoveryEmail: 'user@email.com',
          securityQuestions: const ['Q1', 'Q2', 'Q3'],
          securityAnswers: const ['blue', 'dog', 'nj'],
        );

        final ok = await auth.resetPasswordWithSecurityAnswers(
          answers: const ['Blue', 'DOG', 'NJ'], // case-insensitive
          newPassword: 'newPass',
        );
        expect(ok, true);

        // Confirm new password works
        await auth.logout();
        final loginOk = await auth.login('user', 'newPass');
        expect(loginOk, true);
      },
    );

    test(
      'INVALID: resetPasswordWithSecurityAnswers fails with wrong answers',
      () async {
        await auth.register(
          username: 'user',
          password: 'oldPass',
          recoveryEmail: 'user@email.com',
          securityQuestions: const ['Q1', 'Q2', 'Q3'],
          securityAnswers: const ['a1', 'a2', 'a3'],
        );

        final ok = await auth.resetPasswordWithSecurityAnswers(
          answers: const ['x', 'y', 'z'],
          newPassword: 'newPass',
        );
        expect(ok, false);
      },
    );

    test(
      'INVALID: getSecurityQuestions returns null when no account exists',
      () async {
        final qs = await auth.getSecurityQuestions();
        expect(qs, isNull);
      },
    );

    test('VALID: clearAccount removes account + loggedIn false', () async {
      await auth.register(
        username: 'user',
        password: 'pass',
        recoveryEmail: 'user@email.com',
        securityQuestions: const ['Q1', 'Q2', 'Q3'],
        securityAnswers: const ['a1', 'a2', 'a3'],
      );

      expect(await auth.hasAccount(), true);
      expect(await auth.isLoggedIn(), true);

      await auth.clearAccount();

      expect(await auth.hasAccount(), false);
      expect(await auth.isLoggedIn(), false);
    });
  });
}
