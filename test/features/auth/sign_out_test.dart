import 'package:flutter_test/flutter_test.dart';
import 'package:judo_app/app.dart';

// ── Redirect logic (pure, no Flutter/Firebase needed) ────────────────────────

void main() {
  group('computeRedirect — розлогінений юзер', () {
    test('з /team → редирект на /auth/login', () {
      expect(
        computeRedirect(isLoading: false, isLoggedIn: false, currentPath: '/team'),
        '/auth/login',
      );
    });

    test('з /rating → редирект на /auth/login', () {
      expect(
        computeRedirect(isLoading: false, isLoggedIn: false, currentPath: '/rating'),
        '/auth/login',
      );
    });

    test('з /splash → редирект на /auth/login', () {
      expect(
        computeRedirect(isLoading: false, isLoggedIn: false, currentPath: '/splash'),
        '/auth/login',
      );
    });

    test('вже на /auth/login → без редиректу', () {
      expect(
        computeRedirect(isLoading: false, isLoggedIn: false, currentPath: '/auth/login'),
        isNull,
      );
    });

    test('на /auth/register → без редиректу', () {
      expect(
        computeRedirect(isLoading: false, isLoggedIn: false, currentPath: '/auth/register'),
        isNull,
      );
    });
  });

  group('computeRedirect — авторизований юзер', () {
    test('з /auth/login → редирект на /home', () {
      expect(
        computeRedirect(isLoading: false, isLoggedIn: true, currentPath: '/auth/login'),
        '/home',
      );
    });

    test('з /auth/register → редирект на /home', () {
      expect(
        computeRedirect(isLoading: false, isLoggedIn: true, currentPath: '/auth/register'),
        '/home',
      );
    });

    test('на /team → без редиректу', () {
      expect(
        computeRedirect(isLoading: false, isLoggedIn: true, currentPath: '/team'),
        isNull,
      );
    });

    test('на /rating → без редиректу', () {
      expect(
        computeRedirect(isLoading: false, isLoggedIn: true, currentPath: '/rating'),
        isNull,
      );
    });

    test('з /splash → редирект на /home', () {
      expect(
        computeRedirect(isLoading: false, isLoggedIn: true, currentPath: '/splash'),
        '/home',
      );
    });
  });

  group('computeRedirect — завантаження', () {
    test('завантаження → /splash якщо не на /splash', () {
      expect(
        computeRedirect(isLoading: true, isLoggedIn: false, currentPath: '/team'),
        '/splash',
      );
    });

    test('вже на /splash під час завантаження → без редиректу', () {
      expect(
        computeRedirect(isLoading: true, isLoggedIn: false, currentPath: '/splash'),
        isNull,
      );
    });

    test('isLoggedIn ігнорується під час завантаження', () {
      expect(
        computeRedirect(isLoading: true, isLoggedIn: true, currentPath: '/team'),
        '/splash',
      );
    });
  });

  group('computeRedirect — сценарій розлогінення', () {
    // Simulates the sequence of states when user taps "Вийти":
    // 1. User is logged in, on /team
    // 2. signOut() is called → Firebase auth emits null → isLoggedIn = false
    // 3. Router re-evaluates redirect → must return /auth/login

    test('після розлогінення з /team → /auth/login', () {
      // Before sign out
      expect(
        computeRedirect(isLoading: false, isLoggedIn: true, currentPath: '/team'),
        isNull, // stays on /team
      );
      // After sign out (auth state → null)
      expect(
        computeRedirect(isLoading: false, isLoggedIn: false, currentPath: '/team'),
        '/auth/login', // must redirect
      );
    });

    test('після розлогінення з /belts → /auth/login', () {
      expect(
        computeRedirect(isLoading: false, isLoggedIn: false, currentPath: '/belts'),
        '/auth/login',
      );
    });

    test('після розлогінення з /settings → /auth/login', () {
      expect(
        computeRedirect(isLoading: false, isLoggedIn: false, currentPath: '/settings'),
        '/auth/login',
      );
    });
  });

}
