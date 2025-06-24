import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:rive_native/rive_native.dart';
import 'package:rive_native/rive_text.dart';

import '../../../src/utils.dart';
import '../../src/rive_golden.dart';

void main() {
  group('Golden - render text test', () {
    late Font? font;
    setUp(() {
      final bytes = loadFile('assets/fonts/iosevka-rive-light.ttf');
      font = Font.decode(bytes);
      expect(font, isNotNull);
    });

    testWidgets('Test simple text', (WidgetTester tester) async {
      await riveProceduralGolden(
        name: 'simple_text',
        widgetTester: tester,
        paint: (renderer, size, paintPixelRatio) {
          final text = renderer.riveFactory.makeText()
            ..append(
              'hello world',
              font: font!,
              size: 72,
            );
          renderer.drawText(
            text,
            renderer.riveFactory.makePaint()..color = const Color(0xFFFFFFFF),
          );
          expect(
            AABB.areEqual(text.bounds, AABB.fromLTWH(0, 0, 396.0, 90.0)),
            isTrue,
          );
        },
      );
    });

    testWidgets('Test simple text with ellipsis', (WidgetTester tester) async {
      await riveProceduralGolden(
        name: 'simple_text_ellipsis',
        widgetTester: tester,
        paint: (renderer, size, paintPixelRatio) {
          final text = renderer.riveFactory.makeText()
            ..append(
              'hello world',
              font: font!,
              size: 72,
            )
            ..overflow = TextOverflow.ellipsis
            ..sizing = TextSizing.fixed
            ..maxWidth = 350
            ..maxHeight = 72;
          renderer.drawText(
            text,
            renderer.riveFactory.makePaint()..color = const Color(0xFFFFFFFF),
          );
        },
      );
    });

    testWidgets('text with different styling', (WidgetTester tester) async {
      await riveProceduralGolden(
        name: 'styled_text',
        widgetTester: tester,
        paint: (renderer, size, paintPixelRatio) {
          final text = renderer.riveFactory.makeText()
            ..append(
              'hello ',
              font: font!,
              size: 52,
              paint: renderer.riveFactory.makePaint()
                ..color = const Color(0xFFFFFFFF),
            )
            ..append(
              'world',
              font: font!,
              size: 82,
              paint: renderer.riveFactory.makePaint()
                ..color = const Color(0xFF00FF00),
            );
          renderer.drawText(
            text,
          );
        },
      );
    });
  });
}
