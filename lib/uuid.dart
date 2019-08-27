import "dart:math";

/// A UUID generator. Shamelessly extracted from the Flutter source code.
class Uuid {
  static final Random _random = new Random();

  /// Generate a version 4 (random) uuid. This is a uuid scheme that only uses
  /// random numbers as the source of the generated uuid.
  static String generateV4() {
    // Generate xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx / 8-4-4-4-12.
    final int special = 8 + _random.nextInt(4);

    return "${_bitsDigits(16, 4)}${_bitsDigits(16, 4)}-"
        "${_bitsDigits(16, 4)}-"
        "4${_bitsDigits(12, 3)}-"
        "${_printDigits(special, 1)}${_bitsDigits(12, 3)}-"
        "${_bitsDigits(16, 4)}${_bitsDigits(16, 4)}${_bitsDigits(16, 4)}";
  }

  static String _bitsDigits(int bitCount, int digitCount) =>
      _printDigits(_generateBits(bitCount), digitCount);

  static int _generateBits(int bitCount) => _random.nextInt(1 << bitCount);

  static String _printDigits(int value, int count) =>
      value.toRadixString(16).padLeft(count, "0");
}
