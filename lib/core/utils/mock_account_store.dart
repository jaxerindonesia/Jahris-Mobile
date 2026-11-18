import 'dart:convert';

import 'package:crypto/crypto.dart';

class MockAccount {
  const MockAccount({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.branchName,
    required this.passwordDigest,
    required this.mustChangePassword,
  });

  final String id;
  final String name;
  final String email;
  final String role;
  final String branchName;
  final String passwordDigest;
  final bool mustChangePassword;

  MockAccount copyWith({
    String? name,
    String? email,
    String? role,
    String? branchName,
    String? passwordDigest,
    bool? mustChangePassword,
  }) {
    return MockAccount(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      branchName: branchName ?? this.branchName,
      passwordDigest: passwordDigest ?? this.passwordDigest,
      mustChangePassword: mustChangePassword ?? this.mustChangePassword,
    );
  }
}

abstract final class MockAccountStore {
  static final Map<String, MockAccount> _accounts = {};

  static String _digest(String password) =>
      sha256.convert(utf8.encode(password)).toString();

  static void register({
    required String id,
    required String name,
    required String email,
    required String role,
    required String branchName,
    required String password,
    required bool mustChangePassword,
  }) {
    _accounts[email.trim().toLowerCase()] = MockAccount(
      id: id,
      name: name,
      email: email.trim(),
      role: role,
      branchName: branchName,
      passwordDigest: _digest(password),
      mustChangePassword: mustChangePassword,
    );
  }

  static MockAccount? authenticate(String email, String password) {
    final account = _accounts[email.trim().toLowerCase()];
    if (account == null || account.passwordDigest != _digest(password)) {
      return null;
    }
    return account;
  }

  static bool contains(String email) =>
      _accounts.containsKey(email.trim().toLowerCase());

  static void resetPassword({
    required String email,
    required String password,
    required bool mustChangePassword,
  }) {
    final key = email.trim().toLowerCase();
    final account = _accounts[key];
    if (account == null) return;
    _accounts[key] = account.copyWith(
      passwordDigest: _digest(password),
      mustChangePassword: mustChangePassword,
    );
  }

  static void completePasswordChange(String email, String password) {
    resetPassword(email: email, password: password, mustChangePassword: false);
  }

  static void updateEmployee({
    required String id,
    required String name,
    required String email,
    required String role,
    required String branchName,
  }) {
    final entry = _accounts.entries
        .where((item) => item.value.id == id)
        .firstOrNull;
    if (entry == null) return;
    final updated = entry.value.copyWith(
      name: name,
      email: email.trim(),
      role: role,
      branchName: branchName,
    );
    _accounts.remove(entry.key);
    _accounts[email.trim().toLowerCase()] = updated;
  }

  static void remove(String email) =>
      _accounts.remove(email.trim().toLowerCase());
}
