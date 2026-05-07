import 'dart:math';

const _alphabet =
    '0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ';

String newIdempotencyKey([Random? rng]) {
  final r = rng ?? Random.secure();
  final buf = StringBuffer();
  for (var i = 0; i < 22; i++) {
    buf.write(_alphabet[r.nextInt(_alphabet.length)]);
  }
  return buf.toString();
}
