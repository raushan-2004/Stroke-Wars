import 'dart:math';

/// A shared utility for generating RFC 4122 v4 UUIDs without external packages.
String generateV4Uuid() {
  final random = Random.secure();
  String hex(int n) => n.toRadixString(16);
  final buf = StringBuffer();
  for (var i = 0; i < 32; i++) {
    if (i == 8 || i == 12 || i == 16 || i == 20) buf.write('-');
    if (i == 12) {
      buf.write('4');
    } else if (i == 16) {
      buf.write(hex(random.nextInt(4) + 8));
    } else {
      buf.write(hex(random.nextInt(16)));
    }
  }
  return buf.toString();
}
