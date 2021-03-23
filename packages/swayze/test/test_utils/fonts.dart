import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';

Future<void> loadFont(
  String familyName,
  String fontName,
  List<String> variants,
) async {
  final fontLoader = FontLoader(fontName);
  for (final variant in variants) {
    final font = File('test/test_utils/assets/fonts/$familyName-$variant.ttf')
        .readAsBytes()
        .then((bytes) => ByteData.view(Uint8List.fromList(bytes).buffer));

    fontLoader.addFont(font);
  }

  await fontLoader.load();
}

Future<void> loadFonts() async {
  await loadFont(
    'Inconsolata',
    'normal',
    ['Regular', 'Bold'],
  );
}
