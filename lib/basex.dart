import 'dart:typed_data';

// Adapted from https://github.com/cryptocoinjs/base-x
// Originally written by Mike Hearn for BitcoinJ
// Copyright (c) 2011 Google Inc
// Ported to JavaScript by Stefan Thomas
// Merged Buffer refactorings from base58-native by Stephen Pair
// Copyright (c) 2013 BitPay Inc

/// Encodes and decodes data in a given base (i.e. base64).
class Coder {
  final int BASE;
  final String LEADER;
  final String alphabet;
  final alphaMap = new Map<String,int>();

  /// Creates a base-X encoder/decoder using the supplied `alphabet` string.
  /// @param alphabet the characters to use for encoding numeric values. The length of the string
  /// defines the base.
  Coder(this.alphabet) : BASE = alphabet.length, LEADER = alphabet[0] {
    // pre-compute lookup table
    for (var ii = 0; ii < alphabet.length; ii += 1) {
      final x = alphabet[ii];
      if (alphaMap[x] != null) throw new Exception("$x is ambiguous");
      alphaMap[x] = ii;
    }
  }

  /// Encodes `data` into the target base.
  String encode (Uint8List source) {
    if (source.length == 0) return "";

    var digits = [0];
    for (var ii = 0; ii < source.length; ii += 1) {
      var carry = source[ii];
      for (var jj = 0; jj < digits.length; jj += 1) {
        carry += digits[jj] << 8;
        digits[jj] = carry % BASE;
        carry = (carry ~/ BASE) | 0;
      }
      while (carry > 0) {
        digits.add(carry % BASE);
        carry = (carry ~/ BASE) | 0;
      }
    }

    var encoded = "";
    // deal with leading zeros
    for (var kk = 0; source[kk] == 0 && kk < source.length-1; kk += 1) encoded += LEADER;
    // convert digits to a string
    for (var qq = digits.length-1; qq >= 0; qq -= 1) encoded += alphabet[digits[qq]];
    return encoded;
  }

  /// Decodes `encoded` from the target base.
  /// @param into an optional list into which the data will be decoded. If one is not supplied a
  /// new list will be created.
  /// @param offset an optional offset into the `into` array at which to write the decoded data.
  /// @return the array into which the data was decoded.
  /// @throw Error if the encoded string contained invalid characters. */
  Uint8List decode (String encoded, [Uint8List into = null, int offset = 0]) {
    if (encoded.length == 0) return new Uint8List(0);

    var bytes = [0];
    for (var ii = 0, ll = encoded.length; ii < ll; ii += 1) {
      var value = alphaMap[encoded[ii]];
      if (value == null) throw new Exception("Invalid character at $ii in '$encoded'");

      var carry = value;
      for (var jj = 0, ll = bytes.length; jj < ll; jj += 1) {
        carry += bytes[jj] * BASE;
        bytes[jj] = carry & 0xFF;
        carry >>= 8;
      }
      while (carry > 0) {
        bytes.add(carry & 0xff);
        carry >>= 8;
      }
    }

    // deal with leading zeros
    for (var kk = 0; encoded[kk] == LEADER && kk < encoded.length-1; kk += 1) bytes.add(0);

    if (into == null) into = new Uint8List(bytes.length);
    into.setAll(offset, bytes.reversed);
    return into;
  }
}

/** An encoder/decoder created for base62 strings, using the 'standard' alphabet. */
final Base62 = Coder('0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ');
