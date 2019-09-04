import 'package:test/test.dart';
import '../lib/uuid.dart';

void main () {
  test('Uuid.v1 generates a valid looking UUID', () {
    var uuid1 = Uuid.makeV1();
    expect(uuid1.toCanonical().length, equals(32+4));
  });

  test('Uuid.v4 generates a valid looking UUID', () {
    var uuid4 = Uuid.makeV4();
    expect(uuid4.toCanonical().length, equals(32+4));
    expect(uuid4.toCanonical()[14], equals('4'));
  });

  test('Uuid encode/decode from base62 preserves value', () {
    var uuid1 = Uuid.makeV1();
    expect(uuid1, equals(uuid1));
    expect(Uuid.fromBase62(Uuid.toBase62(uuid1)), equals(uuid1));
  });
}
