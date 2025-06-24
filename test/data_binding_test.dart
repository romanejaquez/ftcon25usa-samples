// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'dart:ffi';
import 'dart:io';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:rive_native/rive_native.dart' as rive;
import 'package:rive_native/src/ffi/dynamic_library_helper.dart';

final DynamicLibrary nativeLib = DynamicLibraryHelper.nativeLib;

final List<rive.ViewModelProperty> _viewModelPropertiesToCompare = [
  const rive.ViewModelProperty('pet', rive.DataType.viewModel),
  const rive.ViewModelProperty('jump', rive.DataType.trigger),
  const rive.ViewModelProperty('likes_popcorn', rive.DataType.boolean),
  const rive.ViewModelProperty('favourite_pet', rive.DataType.enumType),
  const rive.ViewModelProperty('favourite_color', rive.DataType.color),
  const rive.ViewModelProperty('age', rive.DataType.number),
  const rive.ViewModelProperty('website', rive.DataType.string),
  const rive.ViewModelProperty('name', rive.DataType.string),
];
final List<rive.DataEnum> _dataEnumsToCompare = [
  const rive.DataEnum('Pets', ['chipmunk', 'rat', 'frog', 'owl', 'cat', 'dog']),
];

void main() {
  late rive.File riveFile;

  setUpAll(() {
    return Future(() async {
      final file = File('test/assets/databinding.riv');
      final bytes = await file.readAsBytes();
      riveFile =
          await rive.File.decode(bytes, riveFactory: rive.Factory.flutter)
              as rive.File;
    });
  });

  test('view model count', () async {
    expect(riveFile.viewModelCount, 2);
  });

  test('view model file enums', () async {
    expect(riveFile.enums, _dataEnumsToCompare);
  });

  test('view model by index exists', () async {
    var viewModel = riveFile.viewModelByIndex(0);
    expect(viewModel, isNotNull);
    viewModel!.dispose();

    viewModel = riveFile.viewModelByIndex(-1);
    expect(viewModel, isNull);
  });

  test('view model by name exists', () async {
    var viewModel = riveFile.viewModelByName("Person");
    expect(viewModel, isNotNull);
    viewModel!.dispose();

    viewModel = riveFile.viewModelByName("DoesNotExist");
    expect(viewModel, isNull);
  });

  test('null on non existing items', () async {
    // View Models that do not exist should return null.
    var viewModel = riveFile.viewModelByIndex(100); // out of range
    expect(viewModel, isNull);
    viewModel = riveFile.viewModelByName("DoesNotExist"); // out of range
    expect(viewModel, isNull);

    // This exists, and is used in the rest of the tests.
    viewModel = riveFile.viewModelByName("Person");
    expect(viewModel, isNotNull);

    // Instances that do not exist should return null.
    var viewModelInstance = viewModel!.createInstanceByIndex(100);
    expect(viewModelInstance, isNull);
    viewModelInstance = viewModel.createInstanceByName("DoesNotExist");
    expect(viewModelInstance, isNull);

    // This exists, and is used in the rest of the tests.
    viewModelInstance = viewModel.createInstanceByName('Gordon');
    expect(viewModelInstance, isNotNull);

    // Properties that do not exist should return null.
    var numberProperty = viewModelInstance!.number('numberDoesNotExist');
    var stringProperty = viewModelInstance.string('stringDoesNotExist');
    var colorProperty = viewModelInstance.color('colorDoesNotExist');
    var booleanProperty = viewModelInstance.boolean('booleanDoesNotExist');
    var enumProperty = viewModelInstance.enumerator('enumDoesNotExist');
    var triggerProperty = viewModelInstance.trigger('triggerDoesNotExist');
    var viewModelProperty =
        viewModelInstance.viewModel('viewModelDoesNotExist');
    expect(numberProperty, isNull);
    expect(stringProperty, isNull);
    expect(colorProperty, isNull);
    expect(booleanProperty, isNull);
    expect(enumProperty, isNull);
    expect(triggerProperty, isNull);
    expect(viewModelProperty, isNull);
  });

  test('view model by artboard default exists', () async {
    var artboard = riveFile.defaultArtboard();
    expect(artboard, isNotNull);

    var viewModel = riveFile.defaultArtboardViewModel(artboard!);
    expect(viewModel, isNotNull);
    artboard.dispose();
    viewModel!.dispose();
  });

  test('can bind view model instances', () async {
    var artboard = riveFile.defaultArtboard();
    expect(artboard, isNotNull);
    var stateMachine = artboard!.defaultStateMachine();
    expect(stateMachine, isNotNull);
    var viewModel = riveFile.viewModelByName('Person');
    expect(viewModel, isNotNull);
    var viewModelInstance = viewModel!.createInstanceByName('Gordon');
    expect(() => artboard.bindViewModelInstance(viewModelInstance!),
        returnsNormally);
    expect(() => stateMachine!.bindViewModelInstance(viewModelInstance!),
        returnsNormally);
  });

  test('view model properties are correct', () async {
    var viewModel = riveFile.viewModelByName('Person');
    expect(viewModel, isNotNull);
    expect(viewModel!.name, "Person");
    expect(viewModel.propertyCount, 8);
    expect(viewModel.instanceCount, 2);

    final properties = viewModel.properties;
    expect(properties, _viewModelPropertiesToCompare);
    viewModel.dispose();
  });

  test('view model instance create from index', () async {
    var viewModel = riveFile.viewModelByIndex(0);
    expect(viewModel, isNotNull);
    var viewModelInstance = viewModel!.createInstanceByIndex(0);
    expect(viewModelInstance, isNotNull);
    viewModelInstance!.dispose();
  });

  test('view model instance create from name', () async {
    var viewModel = riveFile.viewModelByName('Person');
    expect(viewModel, isNotNull);
    var viewModelInstance = viewModel!.createInstanceByName('Gordon');
    expect(viewModelInstance, isNotNull);
    viewModelInstance!.dispose();
  });

  test('view model instance create default', () async {
    var viewModel = riveFile.viewModelByName('Person');
    expect(viewModel, isNotNull);
    var viewModelInstance = viewModel!.createDefaultInstance();
    expect(viewModelInstance, isNotNull);
    viewModelInstance!.dispose();
  });

  test('view model instance create empty', () async {
    var viewModel = riveFile.viewModelByName('Person');
    expect(viewModel, isNotNull);
    var viewModelInstance = viewModel!.createInstance();
    expect(viewModelInstance, isNotNull);
    viewModelInstance!.dispose();
  });

  test('view model instance property values', () async {
    var viewModel = riveFile.viewModelByName('Person');
    expect(viewModel, isNotNull);
    var viewModelInstance = viewModel!.createInstanceByName('Gordon');
    expect(viewModelInstance, isNotNull);

    // view model instance name
    expect(viewModelInstance!.name, "Gordon");

    // properties
    final properties = viewModel.properties;
    expect(properties, _viewModelPropertiesToCompare);

    // number
    var numberProperty = viewModelInstance.number('age');
    expect(numberProperty, isNotNull);
    expect(numberProperty!.value, 30);
    numberProperty.value = 33;
    expect(numberProperty.value, 33);

    // string
    var stringProperty = viewModelInstance.string('name');
    expect(stringProperty, isNotNull);
    expect(stringProperty!.value, "Gordon");
    stringProperty.value = "Peter";
    expect(stringProperty.value, "Peter");

    // color
    var colorProperty = viewModelInstance.color('favourite_color');
    expect(colorProperty, isNotNull);
    var color = colorProperty!.value;
    expect(color.red, 255);
    expect(color.green, 0);
    expect(color.blue, 0);
    colorProperty.value = const Color.fromARGB(143, 0, 255, 0);
    color = colorProperty.value;
    expect(color.alpha, 143);
    expect(color.red, 0);
    expect(color.green, 255);
    expect(color.blue, 0);
    colorProperty.value = colorProperty.value.withAlpha(0);
    color = colorProperty.value;
    expect(color.alpha, 0);
    const originalColor = Color.fromRGBO(255, 23, 79, 0.5123);
    colorProperty.value = originalColor;
    expect(colorProperty.value.value, originalColor.value);
    expect(colorProperty.value.red, originalColor.red);
    expect(colorProperty.value.green, originalColor.green);
    expect(colorProperty.value.blue, originalColor.blue);
    expect(colorProperty.value.opacity, originalColor.opacity);

    // boolean
    var booleanProperty = viewModelInstance.boolean('likes_popcorn');
    expect(booleanProperty, isNotNull);
    expect(booleanProperty!.value, false);
    booleanProperty.value = true;
    expect(booleanProperty.value, true);

    // enum
    var enumProperty = viewModelInstance.enumerator('favourite_pet');
    expect(enumProperty, isNotNull);
    expect(enumProperty!.value, "dog");
    enumProperty.value = "cat";
    expect(enumProperty.value, "cat");
    enumProperty.value = "snakeLizard"; // does not exist as a valid enum
    expect(enumProperty.value, "cat",
        reason: 'should not change to invalid enum');

    // trigger
    var triggerProperty = viewModelInstance.trigger('jump');
    expect(triggerProperty, isNotNull);
    triggerProperty!.trigger(); // expect this to not throw

    // view model instance
    var viewModelProperty = viewModelInstance.viewModel('pet');
    expect(viewModelProperty, isNotNull);
    var petName = viewModelProperty!.string('name');
    expect(petName, isNotNull);
    expect(petName!.value, "Jameson");

    var petType = viewModelProperty.enumerator('type')!;
    expect(petType.value, "frog");
    petType.value = "chipmunk";
    expect(petType.value, "chipmunk");
  });

  test('view model instance value has changed and clear changes work',
      () async {
    var viewModel = riveFile.viewModelByName('Person');
    expect(viewModel, isNotNull);
    var viewModelInstance = viewModel!.createInstanceByName('Gordon');
    expect(viewModelInstance, isNotNull);

    var numberProperty = viewModelInstance!.number('age');
    expect(numberProperty!.hasChanged, false);
    numberProperty.value = 100;
    expect(numberProperty.hasChanged, true);
    numberProperty.clearChanges();
    expect(numberProperty.hasChanged, false);
  });

  test('view model instance value callbacks', () async {
    var viewModel = riveFile.viewModelByName('Person');
    expect(viewModel, isNotNull);
    var viewModelInstance = viewModel!.createInstanceByName('Gordon')!;
    expect(viewModelInstance, isNotNull);

    // number
    var numberProperty = viewModelInstance.number('age')!;
    Completer<void> numberCompleter = Completer();
    numberCallback(value) {
      expect(value, 100);
      numberCompleter.complete();
    }

    // string
    var stringProperty = viewModelInstance.string('name')!;
    Completer<void> stringCompleter = Completer();
    stringCallback(value) {
      expect(value, "Peter Parker");
      stringCompleter.complete();
    }

    // color
    var colorProperty = viewModelInstance.color('favourite_color')!;
    Completer<void> colorCompleter = Completer();
    Completer<void> colorCompleter2 = Completer();
    colorCallback(value) {
      expect(value, const Color(0xFF00FF00));
      colorCompleter.complete();
    }

    colorCallback2(value) {
      expect(value, const Color(0xFF00FF00));
      colorCompleter2.complete();
    }

    // enumerator
    var enumProperty = viewModelInstance.enumerator('favourite_pet')!;
    Completer<void> enumCompleter = Completer();
    enumCallback(value) {
      expect(value, "cat");
      enumCompleter.complete();
    }

    // boolean
    var booleanProperty = viewModelInstance.boolean('likes_popcorn')!;
    Completer<void> booleanCompleter = Completer();
    booleanCallback(value) {
      expect(value, true);
      booleanCompleter.complete();
    }

    // trigger
    var triggerProperty = viewModelInstance.trigger('jump')!;
    Completer<void> triggerCompleter = Completer();
    triggerCallback(bool value) {
      triggerCompleter.complete();
    }

    // view model instance property
    var viewModelProperty = viewModelInstance.viewModel('pet')!;

    // Nested enum property
    var petTypeProperty = viewModelProperty.enumerator('type')!;
    Completer<void> petTypeCompleter = Completer();
    petTypeCallback(value) {
      expect(value, "chipmunk");
      petTypeCompleter.complete();
    }

    // ADD LISTENERS
    numberProperty.addListener(numberCallback);
    numberProperty.addListener(
        numberCallback); // this should not do anything as this callback is already added
    expect(numberProperty.numberOfListeners, 1,
        reason: "should only have one listener");

    stringProperty.addListener(stringCallback);
    expect(numberProperty.numberOfListeners, 1);

    colorProperty.addListener(colorCallback);
    colorProperty.addListener(colorCallback2);
    expect(colorProperty.numberOfListeners, 2);

    enumProperty.addListener(enumCallback);
    expect(enumProperty.numberOfListeners, 1);

    booleanProperty.addListener(booleanCallback);
    expect(booleanProperty.numberOfListeners, 1);

    triggerProperty.addListener(triggerCallback);
    expect(triggerProperty.numberOfListeners, 1);

    petTypeProperty.addListener(petTypeCallback);
    expect(petTypeProperty.numberOfListeners, 1);

    // CHANGE VALUES
    numberProperty.value = 100;
    stringProperty.value = "Peter Parker";
    colorProperty.value = const Color.fromARGB(255, 0, 255, 0);
    enumProperty.value = "cat";
    booleanProperty.value = true;
    expect(booleanProperty.hasChanged, true);
    triggerProperty.trigger();
    petTypeProperty.value = "chipmunk";

    viewModelInstance.handleCallbacks(); // Simulate a frame advance.

    // VERIFY CALLBACKS
    expect(viewModelInstance.numberOfCallbacks, 7,
        reason: "should be incremented for each value property");

    numberProperty.removeListener(numberCallback);
    expect(numberProperty.numberOfListeners, 0);

    stringProperty.clearListeners();
    expect(stringProperty.numberOfListeners, 0);

    triggerProperty.clearListeners();
    expect(triggerProperty.numberOfListeners, 0);

    expect(viewModelInstance.numberOfCallbacks, 4,
        reason: "not all callbacks should be removed yet");

    colorProperty.clearListeners();
    expect(colorProperty.numberOfListeners, 0);

    expect(viewModelInstance.numberOfCallbacks, 3,
        reason: "callbacks should be less but not 0");

    await Future.wait([
      numberCompleter.future,
      stringCompleter.future,
      colorCompleter.future,
      colorCompleter2.future,
      booleanCompleter.future,
      enumCompleter.future,
      triggerCompleter.future,
      petTypeCompleter.future
    ]);

    viewModelInstance.dispose();

    expect(viewModelInstance.numberOfCallbacks, 0,
        reason: "callbacks should be 0");

    expect(enumProperty.numberOfListeners, 0);
    expect(booleanProperty.numberOfListeners, 0);
    expect(petTypeProperty.numberOfListeners, 0);
  });

  test('view model properties by nested path', () async {
    var viewModel = riveFile.viewModelByName('Person');
    expect(viewModel, isNotNull);
    var viewModelInstance = viewModel!.createInstanceByName('Gordon');
    expect(viewModelInstance, isNotNull);

    var nestedStringProperty = viewModelInstance!.string('pet/name');
    var nestedEnumProperty = viewModelInstance.enumerator('pet/type');
    expect(nestedStringProperty, isNotNull);
    expect(nestedEnumProperty, isNotNull);

    expect(nestedStringProperty!.value, "Jameson");
    expect(nestedEnumProperty!.value, "frog");

    Completer<void> stringCompleter = Completer();
    stringCallback(value) {
      expect(nestedStringProperty.value, "Peter Parker");
      stringCompleter.complete();
    }

    Completer<void> enumCompleter = Completer();
    enumCallback(value) {
      expect(nestedEnumProperty.value, "chipmunk");
      enumCompleter.complete();
    }

    nestedStringProperty.addListener(stringCallback);
    expect(nestedStringProperty.numberOfListeners, 1);
    expect(viewModelInstance.numberOfCallbacks, 1);

    nestedEnumProperty.addListener(enumCallback);
    expect(nestedEnumProperty.numberOfListeners, 1);
    expect(viewModelInstance.numberOfCallbacks, 2);

    nestedStringProperty.value = "Peter Parker";
    nestedEnumProperty.value = "chipmunk";

    viewModelInstance.handleCallbacks(); // Simulate a frame advance.

    await Future.wait([
      stringCompleter.future,
      enumCompleter.future,
    ]);

    nestedStringProperty.clearListeners();
    expect(nestedStringProperty.numberOfListeners, 0);
    expect(viewModelInstance.numberOfCallbacks, 1);
    nestedEnumProperty.clearListeners();
    expect(nestedEnumProperty.numberOfListeners, 0);
    expect(viewModelInstance.numberOfCallbacks, 0);
  });
}
