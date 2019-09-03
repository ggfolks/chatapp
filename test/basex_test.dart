import 'dart:math';
import 'dart:typed_data';
import 'package:test/test.dart';
import '../lib/basex.dart';

final Random _random = new Random();

Uint8List mkRandomData () {
  final length = 1 + _random.nextInt(500);
  final data = Uint8List(length);
  for (var ii = 0; ii < length; ii += 1) data[ii] = _random.nextInt(256);
  return data;
}

void main () {
  test('BaseX decodes what it encodes & vice versa', () {
    for (var ii = 0; ii < 500; ii += 1) {
      final data = mkRandomData();
      expect(Base62.decode(Base62.encode(data)), equals(data));
    }

    final buffer = Uint8List(16);
    for (var ii = 0; ii < 128; ii += 1) {
      for (var pp = 0; pp < 16; pp += 1) {
        buffer[pp] = ii;
        expect(Base62.decode(Base62.encode(buffer)), equals(buffer));
        buffer[pp] = 0;
      }
    }
  });
}
