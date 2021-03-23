import 'package:swayze/controller.dart';
import 'package:test/test.dart';

void main() {
  group('header state', () {
    test('customSizedHeaders', () {
      final state = SwayzeHeaderState(
        count: 4,
        frozenCount: 2,
        defaultHeaderExtent: 10,
        headerData: const [
          SwayzeHeaderData(
            index: 3,
            extent: 33,
            hidden: false,
          ),
          SwayzeHeaderData(
            index: 2,
            extent: 44,
            hidden: false,
          ),
        ],
      );

      expect(state.customSizedHeaders, <int, SwayzeHeaderData>{
        2: const SwayzeHeaderData(
          index: 2,
          extent: 44,
          hidden: false,
        ),
        3: const SwayzeHeaderData(
          index: 3,
          extent: 33,
          hidden: false,
        ),
      });
    });

    test('frozenCount bigger than count', () {
      final state = SwayzeHeaderState(
        count: 4,
        frozenCount: 12,
        defaultHeaderExtent: 10,
        headerData: const [
          SwayzeHeaderData(
            index: 3,
            extent: 33,
            hidden: false,
          ),
          SwayzeHeaderData(
            index: 2,
            extent: 44,
            hidden: false,
          ),
        ],
      );

      expect(state.frozenCount, 4);
    });

    test('hasCustomSizes', () {
      final state = SwayzeHeaderState(
        count: 4,
        frozenCount: 2,
        defaultHeaderExtent: 10,
        headerData: const [],
      );

      expect(state.hasCustomSizes, false);

      final state2 = SwayzeHeaderState(
        count: 4,
        frozenCount: 2,
        defaultHeaderExtent: 10,
        headerData: const [
          SwayzeHeaderData(
            index: 3,
            extent: 33,
            hidden: false,
          ),
          SwayzeHeaderData(
            index: 2,
            extent: 44,
            hidden: false,
          ),
        ],
      );

      expect(state2.hasCustomSizes, true);
    });

    test('orderedCustomSizedIndices', () {
      final state = SwayzeHeaderState(
        count: 4,
        frozenCount: 2,
        defaultHeaderExtent: 10,
        headerData: const [
          SwayzeHeaderData(
            index: 3,
            extent: 33,
            hidden: false,
          ),
          SwayzeHeaderData(
            index: 2,
            extent: 44,
            hidden: false,
          ),
        ],
      );
      expect(state.orderedCustomSizedIndices.toList(), [2, 3]);
    });

    group('extent', () {
      test('should calculate extent within table real size', () {
        final state = SwayzeHeaderState(
          count: 4,
          frozenCount: 2,
          defaultHeaderExtent: 10,
          headerData: const [
            SwayzeHeaderData(
              index: 3,
              extent: 33,
              hidden: false,
            ),
            SwayzeHeaderData(
              index: 2,
              extent: 44,
              hidden: false,
            ),
            // This should be ignored since it is beyond the tables size
            SwayzeHeaderData(
              index: 22,
              extent: 44,
              hidden: false,
            ),
          ],
        );
        expect(state.extent, 97.0);
      });

      test('should be able to calculate extent with elasticCount', () {
        final state = SwayzeHeaderState(
          count: 4,
          frozenCount: 2,
          elasticCount: 10,
          defaultHeaderExtent: 10,
          headerData: const [
            SwayzeHeaderData(
              index: 3,
              extent: 33,
              hidden: false,
            ),
            SwayzeHeaderData(
              index: 6,
              extent: 44,
              hidden: false,
            ),
            // This should be ignored since it is beyond the tables size
            SwayzeHeaderData(
              index: 22,
              extent: 44,
              hidden: false,
            ),
          ],
        );

        expect(state.extent, 157.0);
      });
    });

    test('frozenExtent', () {
      final state = SwayzeHeaderState(
        count: 4,
        frozenCount: 3,
        defaultHeaderExtent: 10,
        headerData: const [
          SwayzeHeaderData(
            index: 3,
            extent: 33,
            hidden: false,
          ),
          SwayzeHeaderData(
            index: 2,
            extent: 44,
            hidden: false,
          ),
        ],
      );
      expect(state.frozenExtent, 64.0);
    });

    test('copyWith count', () {
      final state = SwayzeHeaderState(
        count: 4,
        frozenCount: 2,
        defaultHeaderExtent: 10,
        headerData: const [
          SwayzeHeaderData(
            index: 3,
            extent: 33,
            hidden: false,
          ),
          SwayzeHeaderData(
            index: 2,
            extent: 44,
            hidden: false,
          ),
        ],
      );

      final copiedState = state.copyWith(count: 550);
      expect(copiedState.count, 550);
      expect(copiedState.customSizedHeaders, <int, SwayzeHeaderData>{
        2: const SwayzeHeaderData(
          index: 2,
          extent: 44,
          hidden: false,
        ),
        3: const SwayzeHeaderData(
          index: 3,
          extent: 33,
          hidden: false,
        ),
      });
    });

    test('copyWith header data', () {
      final state = SwayzeHeaderState(
        count: 4,
        frozenCount: 2,
        defaultHeaderExtent: 10,
        headerData: const [
          SwayzeHeaderData(
            index: 3,
            extent: 33,
            hidden: false,
          ),
          SwayzeHeaderData(
            index: 2,
            extent: 44,
            hidden: false,
          ),
        ],
      );

      final copiedState = state.copyWith(
        headerData: const [
          SwayzeHeaderData(
            index: 3,
            extent: 12,
            hidden: false,
          ),
          SwayzeHeaderData(
            index: 0,
            extent: 11,
            hidden: false,
          ),
        ],
      );
      expect(copiedState.count, 4);
      expect(copiedState.customSizedHeaders, <int, SwayzeHeaderData>{
        0: const SwayzeHeaderData(
          index: 0,
          extent: 11,
          hidden: false,
        ),
        3: const SwayzeHeaderData(
          index: 3,
          extent: 12,
          hidden: false,
        ),
      });
    });

    test('setHeaderExtent', () {
      final state = SwayzeHeaderState(
        count: 4,
        frozenCount: 2,
        defaultHeaderExtent: 10,
        headerData: const [
          SwayzeHeaderData(
            index: 3,
            extent: 33,
            hidden: false,
          ),
          SwayzeHeaderData(
            index: 2,
            extent: 44,
            hidden: false,
          ),
        ],
      );

      final updatedState = state.setHeaderExtent(0, 11);

      expect(updatedState.customSizedHeaders, <int, SwayzeHeaderData>{
        0: const SwayzeHeaderData(
          index: 0,
          extent: 11,
          hidden: false,
        ),
        2: const SwayzeHeaderData(
          index: 2,
          extent: 44,
          hidden: false,
        ),
        3: const SwayzeHeaderData(
          index: 3,
          extent: 33,
          hidden: false,
        ),
      });
    });

    test('getHeaderExtentFor', () {
      final state = SwayzeHeaderState(
        count: 4,
        frozenCount: 2,
        defaultHeaderExtent: 10,
        headerData: const [
          SwayzeHeaderData(
            index: 3,
            extent: 33,
            hidden: false,
          ),
          SwayzeHeaderData(
            index: 2,
            extent: 44,
            hidden: false,
          ),
        ],
      );

      expect(state.getHeaderExtentFor(index: 0), 10);
      expect(state.getHeaderExtentFor(index: 3), 33);
    });

    test('equality', () {
      expect(
        SwayzeHeaderState(
          count: 4,
          frozenCount: 2,
          defaultHeaderExtent: 10,
          headerData: const [
            SwayzeHeaderData(
              index: 3,
              extent: 33,
              hidden: false,
            ),
            SwayzeHeaderData(
              index: 2,
              extent: 44,
              hidden: false,
            ),
          ],
        ),
        SwayzeHeaderState(
          count: 4,
          frozenCount: 2,
          defaultHeaderExtent: 10,
          headerData: const [
            SwayzeHeaderData(
              index: 3,
              extent: 33,
              hidden: false,
            ),
            SwayzeHeaderData(
              index: 2,
              extent: 44,
              hidden: false,
            ),
          ],
        ),
      );
    });
  });
}
