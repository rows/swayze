import 'package:flutter/painting.dart';

/// Return a [Color] from a Hex string.
Color createColorFromHEX(String hexString) {
  final buffer = StringBuffer();
  final hexWithoutHash = hexString.replaceFirst('#', '');

  if (hexWithoutHash.length == 6) {
    buffer.write('ff');
  }

  if (hexWithoutHash.length == 3) {
    buffer.write('ff');
    buffer.write(hexWithoutHash.splitMapJoin('', onNonMatch: (m) => m * 2));
  } else {
    buffer.write(hexWithoutHash);
  }

  return Color(int.parse(buffer.toString(), radix: 16));
}

/// Returns a string HEX color prefixed with "#".
String createHexStringFromColor(Color color) {
  final value =
      (color.value & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase();

  return '#$value';
}
