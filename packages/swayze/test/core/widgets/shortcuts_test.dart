import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:swayze/src/widgets/shortcuts/shortcuts.dart';

class _MockRawKeyboard extends Mock implements RawKeyboard {}

void main() {
  group('AnyCharacterActivator', () {
    test('should reject any RawKeyUpEvent', () {
      const activator = AnyCharacterActivator();

      final rawKeyboard = _MockRawKeyboard();
      when(() => rawKeyboard.keysPressed).thenReturn({LogicalKeyboardKey.keyA});

      expect(
        activator.accepts(
          const RawKeyUpEvent(data: RawKeyEventDataMacOs(), character: 'a'),
          rawKeyboard,
        ),
        isFalse,
      );
    });

    test('should reject if character is null or empty', () {
      const activator = AnyCharacterActivator();

      final rawKeyboard = _MockRawKeyboard();
      when(() => rawKeyboard.keysPressed)
          .thenReturn({LogicalKeyboardKey.shift});

      expect(
        activator.accepts(
          const RawKeyDownEvent(data: RawKeyEventDataMacOs(), character: ''),
          rawKeyboard,
        ),
        isFalse,
      );
      expect(
        activator.accepts(
          const RawKeyDownEvent(data: RawKeyEventDataMacOs()),
          rawKeyboard,
        ),
        isFalse,
      );
    });

    test('should reject any arrow key', () {
      const activator = AnyCharacterActivator();
      final rawKeyboard = _MockRawKeyboard();
      const keyDownEvent = RawKeyDownEvent(
        data: RawKeyEventDataMacOs(),
        character: '∂',
      );

      when(() => rawKeyboard.keysPressed).thenReturn(
        {LogicalKeyboardKey.arrowDown},
      );
      expect(activator.accepts(keyDownEvent, rawKeyboard), isFalse);

      when(() => rawKeyboard.keysPressed).thenReturn(
        {LogicalKeyboardKey.arrowUp},
      );
      expect(activator.accepts(keyDownEvent, rawKeyboard), isFalse);

      when(() => rawKeyboard.keysPressed).thenReturn(
        {LogicalKeyboardKey.arrowLeft},
      );
      expect(activator.accepts(keyDownEvent, rawKeyboard), isFalse);

      when(() => rawKeyboard.keysPressed).thenReturn(
        {LogicalKeyboardKey.arrowRight},
      );
      expect(activator.accepts(keyDownEvent, rawKeyboard), isFalse);
    });

    test('should reject any control key', () {
      const activator = AnyCharacterActivator();
      final rawKeyboard = _MockRawKeyboard();
      const keyDownEvent = RawKeyDownEvent(
        data: RawKeyEventDataMacOs(),
        character: '∂',
      );

      when(() => rawKeyboard.keysPressed).thenReturn(
        {LogicalKeyboardKey.controlLeft},
      );
      expect(activator.accepts(keyDownEvent, rawKeyboard), isFalse);

      when(() => rawKeyboard.keysPressed).thenReturn(
        {LogicalKeyboardKey.controlRight},
      );
      expect(activator.accepts(keyDownEvent, rawKeyboard), isFalse);

      when(() => rawKeyboard.keysPressed).thenReturn(
        {LogicalKeyboardKey.metaLeft},
      );
      expect(activator.accepts(keyDownEvent, rawKeyboard), isFalse);

      when(() => rawKeyboard.keysPressed).thenReturn(
        {LogicalKeyboardKey.metaRight},
      );
      expect(activator.accepts(keyDownEvent, rawKeyboard), isFalse);
    });

    test('should reject delete and fn+backspace', () {
      const activator = AnyCharacterActivator();
      final rawKeyboard = _MockRawKeyboard();
      final backspaceEvent = RawKeyDownEvent(
        data: const RawKeyEventDataMacOs(),
        character: String.fromCharCode(0x7F),
      );
      final deleteEvent = RawKeyDownEvent(
        data: const RawKeyEventDataMacOs(),
        character: String.fromCharCode(0xF728),
      );

      when(() => rawKeyboard.keysPressed).thenReturn(
        {LogicalKeyboardKey.backspace},
      );
      expect(activator.accepts(backspaceEvent, rawKeyboard), isFalse);

      when(() => rawKeyboard.keysPressed).thenReturn(
        {LogicalKeyboardKey.fn, LogicalKeyboardKey.delete},
      );
      expect(activator.accepts(deleteEvent, rawKeyboard), isFalse);
    });

    test('should accept if its a valid character', () {
      const activator = AnyCharacterActivator();
      final rawKeyboard = _MockRawKeyboard();
      when(() => rawKeyboard.keysPressed).thenReturn({LogicalKeyboardKey.keyA});

      const keyEvent = RawKeyDownEvent(
        data: RawKeyEventDataMacOs(),
        character: 'A',
      );
      expect(activator.accepts(keyEvent, rawKeyboard), isTrue);
    });
  });
}
