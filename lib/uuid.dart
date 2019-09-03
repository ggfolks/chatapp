import "package:collection/collection.dart";
import 'dart:math';
import 'dart:typed_data';
import './basex.dart';

/// A UUID generator. V4 code extracted from the Flutter source code. V1 code adapted from
/// https://github.com/kelektiv/node-uuid which is itself adapted from
/// https://github.com/LiosK/UUID.js and http://docs.python.org/library/uuid.html
class Uuid {
  static final Random _random = new Random();
  static int _lastMSecs = 0, _lastNSecs = 0;

  static Uint8List _createNodeId () {
    // Per 4.5, create and 48-bit node id, (47 random bits + multicast bit = 1)
    var nodeId = new Uint8List(6);
    nodeId[0] = _random.nextInt(1 << 8) | 0x01;
    nodeId[1] = _random.nextInt(1 << 8);
    nodeId[2] = _random.nextInt(1 << 8);
    nodeId[3] = _random.nextInt(1 << 8);
    nodeId[4] = _random.nextInt(1 << 8);
    nodeId[5] = _random.nextInt(1 << 8);
    return nodeId;
  }
  static var _nodeId = _createNodeId();

  // Per 4.2.2, randomize (14 bit) clockseq
  static int _clockseq = _random.nextInt(1 << 16) & 0x3fff;

  /// A uuid that's all zeroes.
  static Uuid zero = Uuid._(Uint8List(16));

  /// Generates a version 1 (date-time + node-id) uuid.
  static Uuid makeV1 () {
    // UUID timestamps are 100 nano-second units since the Gregorian epoch, (1582-10-15 00:00).
    // Time is stored as 'msecs' (integer milliseconds) since unix epoch (1970-01-01 00:00) and
    // 'nsecs' (100-nanoseconds offset from msecs)
    final msecs = DateTime.now().millisecondsSinceEpoch;
    // Per 4.2.1.2, use count of UUIDs generated during the current clock cycle to simulate higher
    // resolution clock
    var nsecs = _lastNSecs + 1;
    // Time since last UUID creation (in msecs)
    final dt = (msecs - _lastMSecs) + (nsecs - _lastNSecs)/10000;
    // Per 4.2.1.2, Bump clockseq on clock regression
    if (dt < 0) _clockseq = (_clockseq + 1) & 0x3fff;
    // Reset nsecs if clock regresses (new clockseq) or we've moved onto a new time interval
    if ((dt < 0 || msecs > _lastMSecs)) nsecs = 0;
    // Per 4.2.1.2 Throw error if too many UUIDs are requested
    if (nsecs >= 10000) throw new Exception("Can't create more than 10M uuids/sec");

    _lastMSecs = msecs;
    _lastNSecs = nsecs;

    // Per 4.1.4 - Convert from unix epoch to Gregorian epoch
    final gmsecs = msecs + 12219292800000;
    final tl = ((gmsecs & 0xfffffff) * 10000 + nsecs) % 0x100000000;
    final tmh = (gmsecs ~/ 0x100000000 * 10000) & 0xfffffff;

    var data = new Uint8List(16);
    // `time_low`
    data[0] = tl >> 24 & 0xff;
    data[1] = tl >> 16 & 0xff;
    data[2] = tl >> 8 & 0xff;
    data[3] = tl & 0xff;
    // `time_mid`
    data[4] = tmh >> 8 & 0xff;
    data[5] = tmh & 0xff;
    // `time_high_and_version`
    data[6] = tmh >> 24 & 0xf | 0x10; // include version
    data[7] = tmh >> 16 & 0xff;
    // `clock_seq_hi_and_reserved` (Per 4.2.2 - include variant)
    data[8] = _clockseq >> 8 | 0x80;
    // `clock_seq_low`
    data[9] = _clockseq & 0xff;
    // `node`
    data[10] = _nodeId[0];
    data[11] = _nodeId[1];
    data[12] = _nodeId[2];
    data[13] = _nodeId[3];
    data[14] = _nodeId[4];
    data[15] = _nodeId[5];
    return new Uuid._(data);
  }

  /// Generates a version 4 (random) uuid.
  static Uuid makeV4 () {
    // Generate xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx.
    var data = new Uint8List(16);
    for (var ii = 0; ii < 16; ii += 1) data[ii] = _random.nextInt(1 << 8);
    data[6] = 0x40 | (data[6] & 0xF);
    return new Uuid._(data);
  }

  /// Converts a base-62 encoded string into a uuid.
  static Uuid fromBase62 (String encoded) {
    return new Uuid._(Base62.decode(encoded));
  }

  /// The 16 bytes of uuid data.
  final Uint8List data;

  /// Creates a UUID from a 16-byte list of data.
  Uuid._ (this.data);

  /// Returns the canonical string form: xxxxxxxx-xxxx-xxxx-yxxx-xxxxxxxxxxxx.
  String toCanonical () {
    var str = '';
    for (var ii =  0; ii <  4; ii += 1) str += data[ii].toRadixString(16).padLeft(2, '0');
    str += '-';
    for (var ii =  4; ii <  6; ii += 1) str += data[ii].toRadixString(16).padLeft(2, '0');
    str += '-';
    for (var ii =  6; ii <  8; ii += 1) str += data[ii].toRadixString(16).padLeft(2, '0');
    str += '-';
    for (var ii =  8; ii < 10; ii += 1) str += data[ii].toRadixString(16).padLeft(2, '0');
    str += '-';
    for (var ii = 10; ii < 16; ii += 1) str += data[ii].toRadixString(16).padLeft(2, '0');
    return str;
  }

  /// Returns this uuid as a base-62 encoded string, the format used by tfw.
  String toBase62 () => Base62.encode(data);

  static final _equality = ListEquality<int>();

  @override String toString () => toBase62();
  @override int get hashCode => _equality.hash(data);
  @override bool operator== (dynamic other) => other is Uuid && _equality.equals(data, other.data);
}
