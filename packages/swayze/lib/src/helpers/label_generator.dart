import 'package:flutter/rendering.dart';
import 'package:swayze_math/swayze_math.dart';

/// Generates a numeric [String] header label given a header [index].
///
/// This is used for row labels.
String _numericLabelGenerator(int index) {
  if (index < 0) {
    throw UnsupportedError('Cant get label for negative headers');
  }
  return '${index + 1}';
}

/// Generates a alphabetic [String] header label given a header [index].
///
/// The result is from A to Z, then AA to AZ and there we go.
///
/// This is used for column labels.
String _alphabetLabelGenerator(int index) {
  if (index < 0) {
    throw UnsupportedError('Cant get label for negative headers');
  }

  if (index < 26) {
    return String.fromCharCode(65 + index);
  }

  final buffer = <int>[];
  var evaluationIndex = index;
  while (evaluationIndex >= 26) {
    buffer.add(65 + evaluationIndex % 26);
    evaluationIndex = (evaluationIndex / 26 - 1).floor();
  }

  buffer.add(65 + evaluationIndex);
  return buffer.reversed.map((int index) => String.fromCharCode(index)).join();
}

/// Generates a header label given an [axis] and a header [index].
///
/// See also:
/// * [numericLabelGenerator] and [alphabetLabelGenerator] that are celled here
///   for vertical and horizontal axis, respectively
String generateLabelForIndex(Axis axis, int index) {
  final generator = axis == Axis.horizontal
      ? _alphabetLabelGenerator
      : _numericLabelGenerator;
  return generator(index);
}

/// Generates a label that represents a [coordinate] composed by the results of
/// [generateLabelForIndex] for each axis concatenated.
///
/// Ex: IntVector2(0,0) will be A1.
///
/// See also:
/// - [generateLabelForIndex] in which is callend for the value
///   os each axis of [coordinate].
String generateLabelForCoordinate(IntVector2 coordinate) {
  final letter = generateLabelForIndex(Axis.horizontal, coordinate.dx);
  final number = generateLabelForIndex(Axis.vertical, coordinate.dy);
  return '$letter$number';
}
