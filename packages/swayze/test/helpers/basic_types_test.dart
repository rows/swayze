import 'package:swayze/src/helpers/basic_types.dart';
import 'package:test/test.dart';

void main() {
  group('Corner opposite', () {
    test('should be able to get the oposite of all corners', () {
      expect(Corner.leftBottom.opposite, Corner.rightTop);
      expect(Corner.rightTop.opposite, Corner.leftBottom);
      expect(Corner.leftTop.opposite, Corner.rightBottom);
      expect(Corner.rightBottom.opposite, Corner.leftTop);
    });
  });

  group('RangeEdge opposite', () {
    test('should be able to get the oposite of all corners', () {
      expect(RangeEdge.trailing.opposite, RangeEdge.leading);
      expect(RangeEdge.leading.opposite, RangeEdge.trailing);
    });
  });
}
