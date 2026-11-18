abstract final class Validators {
  static String? email(String? value) {
    final input = value?.trim() ?? '';
    if (input.isEmpty) return 'Email wajib diisi.';
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(input)) {
      return 'Masukkan alamat email yang valid.';
    }
    return null;
  }

  static String? password(String? value) {
    if ((value ?? '').isEmpty) return 'Password wajib diisi.';
    if (value!.length < 6) return 'Password minimal 6 karakter.';
    return null;
  }

  static String? employeePassword(String? value) {
    final input = value ?? '';
    if (input.isEmpty) return 'Password wajib diisi.';
    if (input.length < 8) return 'Password minimal 8 karakter.';
    if (!RegExp('[A-Za-z]').hasMatch(input) ||
        !RegExp('[0-9]').hasMatch(input)) {
      return 'Password harus mengandung huruf dan angka.';
    }
    return null;
  }

  static String? passwordConfirmation(String? value, String password) {
    if ((value ?? '').isEmpty) return 'Konfirmasi password wajib diisi.';
    if (value != password) return 'Konfirmasi password tidak sama.';
    return null;
  }
}
