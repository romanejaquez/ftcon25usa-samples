import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:rive_native/rive_native.dart';

void main() {
  test('can hit test a path', () {
    var path = Factory.flutter.makePath();
    path.addRect(const Offset(0, 0) & const Size(100, 100));
    expect(path.hitTest(Vec2D.fromValues(20, 20)), true);
  });

  test('can hit test a transformed path', () {
    var path = Factory.flutter.makePath();
    path.addRect(const Offset(0, 0) & const Size(100, 100));

    var transform = Mat2D.fromTranslate(200, 0);
    expect(
        path.hitTest(
          Vec2D.fromValues(20, 20),
          transform: transform,
        ),
        false);

    expect(
        path.hitTest(
          Vec2D.fromValues(220, 20),
          transform: transform,
        ),
        true);
  });

  test('dash path returns length', () {
    var path = Factory.flutter.makePath();
    path.addRect(const Offset(0, 0) & const Size(100, 100));
    final dash = Renderer.makeDashPath();
    final _ = dash.effectPath(path);
    expect(dash.pathLength, 400);
  });

  test('can iterate commands in a render path', () {
    var path = Factory.flutter.makePath();
    path.addOval(const Offset(0, 0) & const Size(100, 100));

    int index = 0;
    for (final command in path.commands) {
      switch (index) {
        case 0:
          expect(command.verb, PathVerb.move);
          expect(command.points[0], Vec2D.fromValues(100, 50));
          break;
        case 1:
          expect(command.verb, PathVerb.cubic);
          expect(command.points[0], Vec2D.fromValues(100, 50));
          expect(command.points[1], Vec2D.fromValues(100, 77.59574890136719));
          expect(command.points[2], Vec2D.fromValues(77.59574890136719, 100.0));
          expect(command.points[3], Vec2D.fromValues(50, 100));
          break;
        case 2:
          expect(command.verb, PathVerb.cubic);
          expect(command.points[0], Vec2D.fromValues(50.0, 100.0));
          expect(command.points[1], Vec2D.fromValues(22.40424919128418, 100.0));
          expect(command.points[2], Vec2D.fromValues(0.0, 77.59574890136719));
          expect(command.points[3], Vec2D.fromValues(0.0, 50.0));
          break;
        case 3:
          expect(command.verb, PathVerb.cubic);
          expect(command.points[0], Vec2D.fromValues(0.0, 50.0));
          expect(command.points[1], Vec2D.fromValues(0.0, 22.40424919128418));
          expect(command.points[2], Vec2D.fromValues(22.40424919128418, 0.0));
          expect(command.points[3], Vec2D.fromValues(50.0, 0.0));
          break;
        case 4:
          expect(command.verb, PathVerb.cubic);
          expect(command.points[0], Vec2D.fromValues(50.0, 0.0));
          expect(command.points[1], Vec2D.fromValues(77.59574890136719, 0.0));
          expect(command.points[2], Vec2D.fromValues(100.0, 22.40424919128418));
          expect(command.points[3], Vec2D.fromValues(100.0, 50.0));
          break;
        case 5:
          expect(command.verb, PathVerb.close);
          break;
      }
      index++;
    }
  });
}
