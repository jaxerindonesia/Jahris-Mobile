import 'package:flutter_test/flutter_test.dart';
import 'package:jahris_mobile/core/config/env.dart';

void main() {
  test('API web aktif secara default', () {
    expect(Env.useMock, isFalse);
  });
}
