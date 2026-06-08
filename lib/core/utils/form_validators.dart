/// Pure validator functions for all form fields.
/// Each function returns an error string or null (valid).
/// No Flutter/Firebase dependencies — tested as plain Dart.
class FormValidators {
  FormValidators._();

  // ── Auth ─────────────────────────────────────────────────────────────────

  static String? email(String? v) {
    if (v == null || v.isEmpty) return 'Введіть email';
    if (!v.contains('@')) return 'Невірний email';
    return null;
  }

  static String? password(String? v) {
    if (v == null || v.isEmpty) return 'Введіть пароль';
    if (v.length < 6) return 'Мінімум 6 символів';
    return null;
  }

  /// Use as: validator: (v) => FormValidators.confirmPasswordWith(v, _passCtrl.text)
  /// Read _passCtrl.text inside the lambda so it's evaluated at validation time.
  static String? confirmPasswordWith(String? v, String password) {
    if (v == null || v.isEmpty) return 'Підтвердіть пароль';
    if (v != password) return 'Паролі не збігаються';
    return null;
  }

  /// Full name (person) — trims whitespace.
  static String? fullName(String? v) {
    if (v == null || v.trim().isEmpty) return "Введіть ім'я";
    return null;
  }

  // ── Athlete ──────────────────────────────────────────────────────────────

  static String? lastName(String? v) {
    if (v == null || v.isEmpty) return 'Введіть прізвище';
    return null;
  }

  static String? firstName(String? v) {
    if (v == null || v.isEmpty) return "Введіть ім'я";
    return null;
  }

  // ── Competitions ─────────────────────────────────────────────────────────

  static String? competitionName(String? v) {
    if (v == null || v.isEmpty) return 'Введіть назву';
    return null;
  }

  /// Place must be a positive integer (>= 1).
  static String? place(String? v) {
    if (v == null || v.isEmpty) return 'Введіть місце (≥ 1)';
    final p = int.tryParse(v);
    if (p == null || p < 1) return 'Введіть місце (≥ 1)';
    return null;
  }

  /// Points must be a non-negative integer (>= 0).
  static String? points(String? v) {
    if (v == null || v.isEmpty) return 'Введіть бали';
    if (int.tryParse(v) == null) return 'Лише цифри';
    if (int.parse(v) < 0) return 'Бали ≥ 0';
    return null;
  }
}
