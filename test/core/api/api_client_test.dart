import 'package:fling/core/api/idempotency_key.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('idempotency keys are 22 chars, alphanumeric', () {
    for (var i = 0; i < 50; i++) {
      final k = newIdempotencyKey();
      expect(k.length, 22);
      expect(RegExp(r'^[0-9A-Za-z]+$').hasMatch(k), isTrue);
    }
  });

  test('idempotency keys are unique across many draws', () {
    final keys = {for (var i = 0; i < 1000; i++) newIdempotencyKey()};
    expect(keys.length, 1000);
  });
}
