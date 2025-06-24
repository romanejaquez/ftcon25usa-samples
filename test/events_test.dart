import 'package:flutter_test/flutter_test.dart';
import 'package:rive_native/rive_native.dart' as rive;
import 'package:rive_native/src/rive.dart';

import 'src/utils.dart';

void main() {
  late rive.File riveFile;

  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final riveBytes = loadFile('assets/events_test.riv');
    riveFile =
        await rive.File.decode(riveBytes, riveFactory: rive.Factory.flutter)
            as rive.File;
  });

  test('Event listeners can be added and cleared', () async {
    final artboard = riveFile.defaultArtboard();
    expect(artboard, isNotNull);
    final stateMachine = artboard!.defaultStateMachine();
    expect(stateMachine, isNotNull);
    expect(stateMachine!.eventListenerCount, 0);
    eventCallback(rive.Event event) {}
    eventCallbackAnother(rive.Event event) {}

    // Adding and removing a listener should update count
    stateMachine.addEventListener(eventCallback);
    expect(stateMachine.eventListenerCount, 1);
    stateMachine.removeEventListener(eventCallback);
    expect(stateMachine.eventListenerCount, 0);

    // Adding the same event listener twice should only add it once
    stateMachine.addEventListener(eventCallback);
    stateMachine.addEventListener(eventCallback);
    expect(stateMachine.eventListenerCount, 1);
    // Adding a different listerer should increment the count
    stateMachine.addEventListener(eventCallbackAnother);
    expect(stateMachine.eventListenerCount, 2);

    // Removing all event listeners should set count to 0
    stateMachine.removeAllEventListeners();
    expect(stateMachine.eventListenerCount, 0);

    // Disposing the state machine should remove all event listeners
    stateMachine.addEventListener(eventCallback);
    expect(stateMachine.eventListenerCount, 1);
    stateMachine.dispose();
    expect(stateMachine.eventListenerCount, 0);
  });

  test('Fire a single general event', () async {
    final artboard = riveFile.defaultArtboard();
    expect(artboard, isNotNull);
    final stateMachine = artboard!.defaultStateMachine();
    expect(stateMachine, isNotNull);
    final trigger = stateMachine!.trigger('FireGeneralEvent');
    trigger!.fire();
    List<rive.Event> observedEvents = [];
    eventCallback(rive.Event event) {
      observedEvents.add(event);
    }

    stateMachine.addEventListener(eventCallback);
    // This advance processes the fire but because we internally grab the latest events
    // before advancing the artboard, we don't catch "this frame's" events until the next
    // advance, which is why we advance twice here.
    stateMachine.advanceAndApply(0.016);

    // No events yet.
    expect(observedEvents.length, 0);
    stateMachine.advanceAndApply(0.016);

    // Second advance reports the event triggered by fireState.
    expect(observedEvents.length, 1);

    var event = observedEvents[0];
    expect(event, isA<rive.GeneralEvent>());
    expect(event.name, 'SomeGeneralEvent');
    expect(event.type, rive.EventType.general);
    var properties = event.properties;
    expect(properties.length, 3);
    expect(properties['SomeNumber'], isA<rive.CustomNumberProperty>());
    expect(properties['SomeString'], isA<rive.CustomStringProperty>());
    expect(properties['SomeBoolean'], isA<rive.CustomBooleanProperty>());
    expect(properties['SomeNumber']!.value, 11.0);
    expect(properties['SomeString']!.value, 'Something');
    expect(properties['SomeBoolean']!.value, true);
    expect(event.stringProperty('SomeString')!.value, 'Something');
    expect(event.stringProperty('SomeString')!.type, CustomPropertyType.string);
    expect(event.numberProperty('SomeNumber')!.value, 11.0);
    expect(event.numberProperty('SomeNumber')!.type, CustomPropertyType.number);
    expect(event.booleanProperty('SomeBoolean')!.value, true);
    expect(
        event.booleanProperty('SomeBoolean')!.type, CustomPropertyType.boolean);
  });

  test('Fire a single open url event', () async {
    final artboard = riveFile.defaultArtboard();
    expect(artboard, isNotNull);
    final stateMachine = artboard!.defaultStateMachine();
    expect(stateMachine, isNotNull);
    final trigger = stateMachine!.trigger('FireOpenUrlEvent');
    trigger!.fire();
    List<rive.Event> observedEvents = [];
    eventCallback(rive.Event event) {
      observedEvents.add(event);
    }

    stateMachine.addEventListener(eventCallback);
    stateMachine.advanceAndApply(0.016);
    // No events yet.
    expect(observedEvents.length, 0);
    stateMachine.advanceAndApply(0.016);
    expect(observedEvents.length, 1);

    var event = observedEvents[0];
    expect(event, isA<rive.OpenUrlEvent>());
    expect(event.name, 'SomeOpenUrlEvent');
    expect(event.type, rive.EventType.openURL);
    var properties = event.properties;
    expect(properties.length, 0);
    var openUrlEvent = event as rive.OpenUrlEvent;
    expect(openUrlEvent.url, 'https://rive.app');
    expect(openUrlEvent.target, OpenUrlTarget.parent);
  });

  test('Fire both events', () async {
    final artboard = riveFile.defaultArtboard();
    expect(artboard, isNotNull);
    final stateMachine = artboard!.defaultStateMachine();
    expect(stateMachine, isNotNull);
    final trigger = stateMachine!.trigger('FireBothEvents');
    trigger!.fire();
    List<rive.Event> observedEvents = [];
    eventCallback(rive.Event event) {
      observedEvents.add(event);
    }

    stateMachine.addEventListener(eventCallback);
    stateMachine.advanceAndApply(0.016);
    // No events yet.
    expect(observedEvents.length, 0);
    stateMachine.advanceAndApply(0.016);
    expect(observedEvents.length, 2);
  });
}
