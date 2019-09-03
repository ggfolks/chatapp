import 'package:test/test.dart';
import '../lib/uuid.dart';

void main () {
  test('Uuid.v1 generates a valid looking UUID', () {
    var uuid1 = Uuid.toCanonical(Uuid.generateV1b());
    expect(uuid1.length, equals('xxxxxxxx-xxxx-xxxx-yxxx-xxxxxxxxxxxx'.length));
    var uuid4 = Uuid.toCanonical(Uuid.generateV4b());
    expect(uuid4.length, equals('xxxxxxxx-xxxx-xxxx-yxxx-xxxxxxxxxxxx'.length));
    expect(uuid4[14], equals('4'));
  });
}
