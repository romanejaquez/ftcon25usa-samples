import 'package:flutter_test/flutter_test.dart';
import 'package:rive_native/rive_native.dart' as rive;

import 'src/utils.dart';

void main() {
  late rive.File riveFile;

  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final riveBytes = loadFile('assets/runtime_nested_inputs.riv');
    riveFile =
        await rive.File.decode(riveBytes, riveFactory: rive.Factory.flutter)
            as rive.File;
  });

  test('Nested boolean input can be get/set', () async {
    final artboard = riveFile.defaultArtboard();
    expect(artboard, isNotNull);
    final stateMachine = artboard!.defaultStateMachine();
    expect(stateMachine, isNotNull);
    final boolean =
        stateMachine!.boolean("CircleOuterState", path: "CircleOuter");
    expect(boolean, isNotNull);
    expect(boolean!.value, false);
    boolean.value = true;
    expect(boolean.value, true);
  });

  test('Nested number input can be get/set', () async {
    final artboard = riveFile.defaultArtboard();
    expect(artboard, isNotNull);
    final stateMachine = artboard!.defaultStateMachine();
    expect(stateMachine, isNotNull);
    final num = stateMachine!.number("CircleOuterNumber", path: "CircleOuter");
    expect(num, isNotNull);
    expect(num!.value, 0);
    num.value = 99;
    expect(num.value, 99);
  });

  test('Nested trigger can be get/fired', () async {
    final artboard = riveFile.defaultArtboard();
    expect(artboard, isNotNull);
    final stateMachine = artboard!.defaultStateMachine();
    expect(stateMachine, isNotNull);
    final trigger =
        stateMachine!.trigger("CircleOuterTrigger", path: "CircleOuter");
    expect(trigger, isNotNull);
    expect(() => trigger!.fire(), returnsNormally);
  });

  test('Nested boolean input can be get/set multiple levels deep', () async {
    final artboard = riveFile.defaultArtboard();
    expect(artboard, isNotNull);
    final stateMachine = artboard!.defaultStateMachine();
    expect(stateMachine, isNotNull);
    final boolean = stateMachine!
        .boolean("CircleInnerState", path: "CircleOuter/CircleInner");
    expect(boolean, isNotNull);
    expect(boolean!.value, false);
    boolean.value = true;
    expect(boolean.value, true);
  });
}
