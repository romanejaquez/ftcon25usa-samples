import 'dart:typed_data';
import 'dart:ui' show Color;

import 'package:flutter/services.dart' show AssetBundle, rootBundle;
import 'package:rive_native/math.dart';
import 'package:rive_native/rive_audio.dart';
import 'package:rive_native/rive_text.dart';
import 'package:rive_native/src/callback_handler.dart';
import 'ffi/rive_ffi.dart' if (dart.library.js_interop) 'web/rive_web.dart';
import 'package:rive_native/src/rive_renderer.dart';
import 'package:meta/meta.dart';
import 'package:http/http.dart' as http;

export 'package:rive_native/src/callback_handler.dart';

class Rive {
  static void batchAdvance(
          Iterable<StateMachine> stateMachines, double elapsedSeconds) =>
      batchAdvanceStateMachines(stateMachines, elapsedSeconds);
  static void batchAdvanceAndRender(Iterable<StateMachine> stateMachines,
          double elapsedSeconds, Renderer renderer) =>
      batchAdvanceAndRenderStateMachines(
          stateMachines, elapsedSeconds, renderer);
}

abstract class Factory {
  Future<void> completedDecodingFile(bool success);

  RenderPath makePath([bool initEmpty = false]);
  RenderPaint makePaint();
  RenderText makeText();

  VertexRenderBuffer? makeVertexBuffer(int elementCount);
  IndexRenderBuffer? makeIndexBuffer(int elementCount);
  Future<RenderImage?> decodeImage(Uint8List bytes);
  Future<Font?> decodeFont(Uint8List bytes);
  Future<AudioSource?> decodeAudio(Uint8List bytes);

  static Factory get flutter => getFlutterFactory();
  static Factory get rive => getRiveFactory();

  bool isValidRenderer(Renderer renderer);
}

extension FileAssetExtension on FileAsset {
  String get uniqueFilename {
    return '$assetUniqueName.$fileExtension';
  }

  String get assetUniqueName => '$name-$assetId';

  String get url => '$cdnBaseUrl/$cdnUuid';
}

typedef AssetLoaderCallback = bool Function(
    FileAsset fileAsset, Uint8List? bytes);

abstract interface class FileAssetInterface {
  int get assetId;
  String get name;
  String get fileExtension;
  String get cdnBaseUrl;
  String get cdnUuid;
  @internal
  Factory get riveFactory;
}

sealed class FileAsset implements FileAssetInterface {
  Future<bool> decode(Uint8List bytes);
}

abstract class ImageAsset extends FileAsset {
  bool renderImage(RenderImage renderImage);
  static const int coreType = 105;
}

abstract class FontAsset extends FileAsset {
  bool font(Font font);
  static const int coreType = 141;
}

abstract class AudioAsset extends FileAsset {
  bool audio(AudioSource audioSource);
  static const int coreType = 406;
}

abstract class UnknownAsset extends FileAsset {}

abstract class File {
  void dispose();
  Artboard? defaultArtboard({bool frameOrigin = true});
  Artboard? artboard(String name, {bool frameOrigin = true});
  Artboard? artboardAt(int index, {bool frameOrigin = true});

  /// This method is used internally and should not be called directly.
  @internal
  InternalDataContext? internalDataContext(
      int viewModelIndex, int instanceIndex);

  /// The number of view models in the Rive file
  int get viewModelCount;

  /// Returns a view model by the index in which it is located in the file
  ViewModel? viewModelByIndex(int index);

  /// Returns a view model by name
  ViewModel? viewModelByName(String name);

  /// Returns the default view model for the provided [artboard]
  ViewModel? defaultArtboardViewModel(Artboard artboard);
  static Future<File?> decode(
    Uint8List bytes, {
    required Factory riveFactory,
    AssetLoaderCallback? assetLoader,
  }) =>
      decodeRiveFile(bytes, riveFactory, assetLoader: assetLoader);

  /// Imports a Rive file from an asset bundle.
  static Future<File?> asset(
    String bundleKey, {
    required Factory riveFactory,
    AssetBundle? bundle,
    AssetLoaderCallback? assetLoader,
  }) async {
    final bytes = await (bundle ?? rootBundle).load(
      bundleKey,
    );

    final file = await decode(
      bytes.buffer.asUint8List(),
      riveFactory: riveFactory,
      assetLoader: assetLoader,
    );
    return file;
  }

  static Future<File?> path(
    String path, {
    required Factory riveFactory,
    AssetLoaderCallback? assetLoader,
  }) async {
    final bytes = await localFileBytes(path);
    if (bytes == null) {
      return null;
    }
    return decode(
      bytes,
      riveFactory: riveFactory,
      assetLoader: assetLoader,
    );
  }

  static Future<File?> url(
    String url, {
    required Factory riveFactory,
    Map<String, String>? headers,
    AssetLoaderCallback? assetLoader,
  }) async {
    final res = await http.get(Uri.parse(url), headers: headers);

    return decode(
      res.bodyBytes,
      riveFactory: riveFactory,
      assetLoader: assetLoader,
    );
  }

  /// Returns a list of [DataEnum]s contained in the file.
  List<DataEnum> get enums;
}

/// A view model enum that represents a list of values.
///
/// - [name] is the name of the enum.
/// - [values] is a string list of possible enum values.
class DataEnum {
  final String name;
  final List<String> values;

  const DataEnum(this.name, this.values);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! DataEnum) return false;
    return name == other.name && _listEquals(values, other.values);
  }

  @override
  int get hashCode => Object.hash(name, Object.hashAll(values));

  bool _listEquals(List<String> list1, List<String> list2) {
    if (list1.length != list2.length) return false;
    for (int i = 0; i < list1.length; i++) {
      if (list1[i] != list2[i]) return false;
    }
    return true;
  }

  @override
  String toString() {
    return 'DataEnum{name: $name, values: $values}';
  }
}

/// The type of data that a view model property can hold.
enum DataType {
  none,
  string,
  number,
  boolean,
  color,
  list,
  enumType,
  trigger,
  viewModel,
}

/// A representation of a property in a Rive view model.
///
/// - [name] is the name of the property.
/// - [type] is the [DataType] of the property.
class ViewModelProperty {
  final String name;
  final DataType type;

  const ViewModelProperty(this.name, this.type);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! ViewModelProperty) return false;
    return name == other.name && type == other.type;
  }

  @override
  int get hashCode => Object.hash(name, type);

  @override
  String toString() {
    return 'ViewModelProperty{name: $name, type: $type}';
  }
}

/// A Rive View Model as created in the Rive editor.
///
/// Docs: https://rive.app/docs/runtimes/data-binding
abstract interface class ViewModel {
  /// The number of properties in the view model
  int get propertyCount;

  /// The number of view model instances in the view model
  int get instanceCount;

  /// The name of the view model
  String get name;

  /// A list of [ViewModelProperty] that makes up the view model
  List<ViewModelProperty> get properties;

  /// Returns a view model instance by the given [index]
  ViewModelInstance? createInstanceByIndex(int index);

  /// Returns a view model instance by the given [name]
  ViewModelInstance? createInstanceByName(String name);

  /// Return the default view model instance
  ViewModelInstance? createDefaultInstance();

  /// Returns an empty/new view model instance
  ViewModelInstance? createInstance();

  /// Disposes of the view model and cleans up underlying native resources
  void dispose();
}

/// An instance of a Rive [ViewModel] that can be used to access and modify
/// properties in the view model.
///
/// Docs: https://rive.app/docs/runtimes/data-binding
abstract interface class ViewModelInstance
    implements ViewModelInstanceCallbacks {
  /// The name of the view model instance
  String get name;

  /// A list of [ViewModelProperty] that makes up the view model instance
  List<ViewModelProperty> get properties;

  /// Access a property instance of type [ViewModelInstance]
  /// belonging to the view model instance or to a nested view model instance.
  ///
  /// {@template property_path}
  /// The [path] is a forward-slash-separated "/" string representing the path
  /// to the property instance.
  /// {@endtemplate}
  ViewModelInstance? viewModel(String path);

  /// Access a property instance of type [ViewModelInstanceNumber]
  /// belonging to the view model instance or to a nested view model instance.
  ///
  /// {@macro property_path}
  ViewModelInstanceNumber? number(String path);

  /// Access a property instance of type [ViewModelInstanceBoolean]
  /// belonging to the view model instance or to a nested view model instance.
  ///
  /// {@macro property_path}
  ViewModelInstanceBoolean? boolean(String path);

  /// Access a property instance of type [ViewModelInstanceColor]
  /// belonging to the view model instance or to a nested view model instance.
  ///
  /// {@macro property_path}
  ///
  ViewModelInstanceColor? color(String path);

  /// Access a property instance of type [ViewModelInstanceString]
  /// belonging to the view model instance or to a nested view model instance.
  ///
  /// {@macro property_path}
  ViewModelInstanceString? string(String path);

  /// Access a property instance of type [ViewModelInstanceTrigger]
  /// belonging to the view model instance or to a nested view model instance.
  ///
  /// {@macro property_path}
  ViewModelInstanceTrigger? trigger(String path);

  /// Access a property instance of type [ViewModelInstanceEnum]
  /// belonging to the view model instance or to a nested view model instance.
  ///
  /// {@macro property_path}
  ViewModelInstanceEnum? enumerator(String path);

  /// Disposes of the view model instance. This removes all listeners/callbacks
  /// and cleans up all underlying resources.
  ///
  /// Do not call this method if you have active view model property listeners,
  /// as these will be removed when the view model instance is disposed.
  void dispose();

  /// Indicates whether the view model instance has been disposed.
  ///
  /// After disposal, the view model instance and its associated properties
  /// become unusable.
  bool get isDisposed;
}

@protected
abstract interface class ViewModelInstanceCallbacks {
  /// Processes all callbacks for properties with attached listeners.
  ///
  /// Listeners can be attached to a [ViewModelInstanceObservableValue]
  /// property using the [addListener] method.
  ///
  /// This method should be invoked once per advance of the underlying
  /// state machine and artboard where the view model instance is bound.
  ///
  /// Typically, this method is called automatically within certain
  /// painters/widgets and should not be manually invoked in most cases.
  /// However, if you are constructing your own render loop or overriding the
  /// default behavior, ensure this is called to trigger the view model
  /// properties' listeners.
  ///
  /// To simulate certain test scenarios, you may also
  /// want to manually invoke this method in testing environments.
  void handleCallbacks();

  /// This method is used internally to add a property instance to the list of
  /// properties that have listeners attached to them.
  ///
  /// This method should not be called directly, but rather through the
  /// [addListener] method of the [ViewModelInstanceObservableValue].
  @internal
  void addCallback(ViewModelInstanceObservableValue instance);

  /// This method is used internally to remove a property instance from the list
  /// of properties that have listeners attached to them.
  ///
  /// This method should not be called directly, but rather through the
  /// [removeListener] method of the [ViewModelInstanceObservableValue].
  @internal
  void removeCallback(ViewModelInstanceObservableValue instance);

  /// This method is used internally to clear all properties that have listeners
  /// attached to them.
  ///
  /// This method should not be called directly.
  @internal
  void clearCallbacks();

  /// The number of properties that have listeners attached to them.
  /// This is useful for testing purposes.
  @visibleForTesting
  int get numberOfCallbacks;
}

@protected
mixin ViewModelInstanceCallbackMixin implements ViewModelInstanceCallbacks {
  final List<ViewModelInstanceObservableValue> _propertiesWithCallbacks = [];

  @override
  void handleCallbacks() {
    for (var property in _propertiesWithCallbacks) {
      property.handleListeners();
    }
  }

  @override
  void addCallback(ViewModelInstanceObservableValue instance) {
    _propertiesWithCallbacks.add(instance);
  }

  @override
  void removeCallback(ViewModelInstanceObservableValue instance) {
    _propertiesWithCallbacks.remove(instance);
  }

  @override
  void clearCallbacks() {
    final callbacksCopy = List.of(_propertiesWithCallbacks);
    _propertiesWithCallbacks.clear();
    for (final element in callbacksCopy) {
      element.clearListeners();
    }
  }

  @override
  int get numberOfCallbacks => _propertiesWithCallbacks.length;
}

@protected
abstract interface class ViewModelInstanceValue {
  @protected
  ViewModelInstance get rootViewModelInstance;
  void dispose();
}

@protected
abstract interface class ViewModelInstanceObservableValue<T>
    implements ViewModelInstanceValue {
  /// Gets the value of the property
  T get value;

  /// Gets the native value of the property
  ///
  /// This method is used internally and should not be called directly.
  /// Use get [value] instead.
  @internal
  T get nativeValue;

  /// Sets the value of the property
  set value(T value);

  /// Sets the native value of the property
  ///
  /// This method is used internally and should not be called directly.
  /// Use set [value] instead.
  @internal
  set nativeValue(T value);

  /// Adds a listener/callback that will be called when the  property value
  /// changes
  void addListener(void Function(T value) callback);

  /// Removes a listener/callback from the property
  void removeListener(void Function(T value) callback);

  /// Handles all listeners attached to the property.
  ///
  /// This method should be called once per frame to ensure that the listeners
  /// are called when the property value changes.
  ///
  /// This method is used internally and should not be called directly.
  @internal
  void handleListeners();

  /// Clears all listeners from the property
  void clearListeners();

  /// Returns whether the property value has changed since the last time the
  /// [clearChanges] method was called
  ///
  /// This method is used internally to determine whether to call the listeners
  /// attached to the property.
  @internal
  get hasChanged;

  /// Clears the changed flag for the property. This method should be called
  /// after the listeners have been called to ensure that the listeners are
  /// only called once per change.
  ///
  /// This method is used internally and should not be called directly.
  @internal
  void clearChanges();

  /// The number of listeners attached to the property.
  /// This is useful for testing purposes.
  @visibleForTesting
  int get numberOfListeners;

  /// Disposes of the property. This removes all listeners and cleans up all
  /// underlying resources.
  @override
  void dispose();
}

/// A mixin that implements the [ViewModelInstanceObservableValue] interface
/// and provides the basic functionality for handling listeners (observables)
/// and notifying them of changes. This allows users to observe changes to the
/// underlying Rive property value.
@protected
mixin ViewModelInstanceObservableValueMixin<T>
    implements ViewModelInstanceObservableValue<T> {
  List<void Function(T value)> listeners = [];

  @override
  @mustCallSuper
  set value(T value) {
    nativeValue = value;
  }

  @override
  @mustCallSuper
  T get value {
    return nativeValue;
  }

  @override
  void addListener(void Function(T value) callback) {
    if (listeners.contains(callback)) {
      return;
    }
    if (listeners.isEmpty) {
      // Since we don't clean the changed flag for properties that don't have
      // listeners, we clean it the first time we add a listener to it
      clearChanges();
      rootViewModelInstance.addCallback(this);
    }
    listeners.add(callback);
  }

  @override
  void removeListener(void Function(T value) callback) {
    listeners.remove(callback);
    if (listeners.isEmpty) {
      rootViewModelInstance.removeCallback(this);
    }
  }

  @override
  void handleListeners() {
    if (hasChanged) {
      clearChanges();
      for (var callback in listeners) {
        callback(value);
      }
    }
  }

  @override
  void clearListeners() {
    listeners.clear();
    rootViewModelInstance.removeCallback(this);
  }

  @override
  int get numberOfListeners => listeners.length;
}

/// A Rive view model property of type [double] that represents a number value.
abstract interface class ViewModelInstanceNumber
    implements ViewModelInstanceObservableValue<double> {}

/// A Rive view model property of type [String] that represents a string value.
abstract interface class ViewModelInstanceString
    implements ViewModelInstanceObservableValue<String> {}

/// A Rive view model property of type [bool] that represents a boolean value.
abstract interface class ViewModelInstanceBoolean
    implements ViewModelInstanceObservableValue<bool> {}

/// A Rive view model property of type [Color] that represents a color value.
abstract interface class ViewModelInstanceColor
    implements ViewModelInstanceObservableValue<Color> {}

/// A Rive view model property of type [String] that represents an enumerator
/// value.
abstract interface class ViewModelInstanceEnum
    implements ViewModelInstanceObservableValue<String> {}

/// A Rive view model property of type [bool] that represents a trigger value.
///
/// Note the `bool` value will always be false, and is only used to represent
/// the underlying type. The poperty is fired by calling the [trigger] method,
/// or by setting the [value] to `true`, which will call [trigger] and
/// immendiately set back to `false`.
abstract interface class ViewModelInstanceTrigger
    implements ViewModelInstanceObservableValue<bool> {
  /// Invokes the trigger for the property
  void trigger();
}

abstract class Artboard {
  AABB get bounds;
  AABB get layoutBounds;
  void draw(Renderer renderer);
  void addToRenderPath(RenderPath renderPath, Mat2D transform);
  StateMachine? defaultStateMachine();
  StateMachine? stateMachine(String name);
  StateMachine? stateMachineAt(int index);
  Component? component(String name);
  int animationCount();
  int stateMachineCount();
  bool get frameOrigin;
  set frameOrigin(bool value);
  Animation animationAt(int index);
  Animation? animationNamed(String name);
  void dispose();

  /// Get a text run value with [runName] at optional [path].
  String getText(String runName, {String? path});

  /// Set a text run value with [runName] at optional [path] to [value].
  bool setText(String runName, String value, {String? path});

  Mat2D get renderTransform;
  set renderTransform(Mat2D value);

  // Flags AdvanceFlags.advanceNested and AdvanceFlags.newFrame set to true
  // by default
  bool advance(double seconds, {int flags = 9});

  double get opacity;
  set opacity(double value);

  double get widthBounds => bounds.width;
  double get heightBounds => bounds.height;

  double get width;
  double get height;
  double get widthOriginal;
  double get heightOriginal;

  set width(double value);
  set height(double value);

  void resetArtboardSize();

  void widthOverride(double width, int widthUnitValue, bool isRow);
  void heightOverride(double height, int heightUnitValue, bool isRow);
  void widthIntrinsicallySizeOverride(bool intrinsic);
  void heightIntrinsicallySizeOverride(bool intrinsic);
  void updateLayoutBounds(bool animate);
  void cascadeLayoutStyle(int direction);
  bool updatePass();
  bool hasComponentDirt();

  @useResult
  CallbackHandler onLayoutChanged(void Function() callback);

  @useResult
  CallbackHandler onEvent(void Function(int) callback);

  /// Callback for when a layout style of a nested artboard has changed.
  @useResult
  CallbackHandler onLayoutDirty(void Function() callback);

  dynamic takeLayoutNode();
  void syncStyleChanges();

  /// This method is used internally and should not be called directly.
  /// Instead, use the [bindViewModelInstance] method.
  @internal
  void internalBindViewModelInstance(
      InternalViewModelInstance instance, InternalDataContext dataContext);

  /// Binds the provided [viewModelInstance] to the artboard
  ///
  /// Docs: https://rive.app/docs/runtimes/data-binding
  void bindViewModelInstance(ViewModelInstance viewModelInstance);

  /// This method is used internally and should not be called directly.
  /// Instead, use the [bindViewModelInstance] method.
  @internal
  void internalSetDataContext(InternalDataContext dataContext);

  /// This method is used internally and should not be called directly.
  @internal
  InternalDataContext? get internalGetDataContext;

  /// This method is used internally and should not be called directly.
  @internal
  void internalClearDataContext();

  /// This method is used internally and should not be called directly.
  @internal
  List<InternalDataBind> internalPopulateDataBinds();

  /// The factory that was used to load this artboard.
  Factory? get riveFactory;
}

/// This class is used internally and should not be used directly.
@internal
abstract class InternalDataBind {
  void update(int dirt);
  void updateSourceBinding();
  int get dirt;
  set dirt(int value);
  int get flags;
  void dispose();
}

/// This class is used internally and should not be used directly.
@internal
abstract class InternalDataContext {
  InternalViewModelInstance get viewModelInstance;
  void dispose();
}

/// This class is used internally and should not be used directly.
///
/// Use [ViewModelInstanceValue] instead.
@internal
abstract class InternalViewModelInstanceValue {
  int instancePointerAddress = 0;
  bool suppressCallback = false;
  void dispose();
}

/// This class is used internally and should not be used directly.
///
/// Use [ViewModelInstanceNumber] instead.
@internal
abstract class InternalViewModelInstanceNumber
    extends InternalViewModelInstanceValue {
  void onChanged(Function(double value) callback);
  set value(double val);
  set nativeValue(double val);
}

/// This class is used internally and should not be used directly.
///
/// Use [ViewModelInstanceBoolean] instead.
@internal
abstract class InternalViewModelInstanceBoolean
    extends InternalViewModelInstanceValue {
  void onChanged(Function(bool value) callback);
  set value(bool val);
  set nativeValue(bool val);
}

/// This class is used internally and should not be used directly.
///
/// Use [ViewModelInstanceColor] instead.
@internal
abstract class InternalViewModelInstanceColor
    extends InternalViewModelInstanceValue {
  void onChanged(Function(int value) callback);
  set value(int val);
  set nativeValue(int val);
}

/// This class is used internally and should not be used directly.
///
/// Use [ViewModelInstanceString] instead.
@internal
abstract class InternalViewModelInstanceString
    extends InternalViewModelInstanceValue {
  void onChanged(Function(String value) callback);
  set value(String val);
  set nativeValue(String val);
}

/// This class is used internally and should not be used directly.
///
/// Use [ViewModelInstanceTrigger] instead.
@internal
abstract class InternalViewModelInstanceTrigger
    extends InternalViewModelInstanceValue {
  void onChanged(Function(int value) callback);
  set value(int val);
  set nativeValue(int val);
  void advanced();
}

/// This class is used internally and should not be used directly.
///
/// Use [ViewModelInstanceEnum] instead.
@internal
abstract class InternalViewModelInstanceEnum
    extends InternalViewModelInstanceValue {
  void onChanged(Function(int value) callback);
  set value(int val);
  set nativeValue(int val);
}

/// This class is used internally and should not be used directly.
///
/// Use [ViewModelInstance] instead.
@internal
abstract class InternalViewModelInstanceViewModel
    extends InternalViewModelInstanceValue {
  InternalViewModelInstance get referenceViewModelInstance;
}

/// This class is used internally and should not be used directly.
@internal
abstract class InternalViewModelInstanceList
    extends InternalViewModelInstanceValue {
  InternalViewModelInstance referenceViewModelInstance(int index);
}

/// This class is used internally and should not be used directly.
///
/// Use [ViewModelInstance] instead.
@internal
abstract class InternalViewModelInstance {
  InternalViewModelInstanceViewModel propertyViewModel(int index);
  InternalViewModelInstanceNumber propertyNumber(int index);
  InternalViewModelInstanceBoolean propertyBoolean(int index);
  InternalViewModelInstanceColor propertyColor(int index);
  InternalViewModelInstanceString propertyString(int index);
  InternalViewModelInstanceTrigger propertyTrigger(int index);
  InternalViewModelInstanceEnum propertyEnum(int index);
  InternalViewModelInstanceList propertyList(int index);
  void dispose();
}

abstract class Animation {
  bool advance(double elapsedSeconds);
  bool advanceAndApply(double elapsedSeconds);
  void apply({double mix = 1.0});
  void dispose();
  double get time;
  double get duration;
  set time(double value);
  double globalToLocalTime(double seconds);
}

enum HitResult {
  none,
  hit,
  hitOpaque,
}

abstract class StateMachine implements EventListenerInterface {
  bool advance(double elapsedSeconds, bool newFrame);
  bool advanceAndApply(double elapsedSeconds);
  void dispose();

  /// Retrieve a number input from the state machine with the given [name].
  /// Get/set the [NumberInput.value] of the input.
  ///
  /// ```dart
  /// final number = stateMachine.number('numberInput');
  /// if (number != null) {
  ///  print(number.value);
  ///  number.value = 42;
  /// }
  /// ```
  /// {@template smi_input_template}
  /// Optionally provide a [path] to access a nested input.
  ///
  /// Docs: https://rive.app/docs/runtimes/state-machines
  /// {@endtemplate}
  NumberInput? number(String name, {String? path});

  /// Retrieve a boolean input from the state machine with the given [name].
  /// Get/set the [BooleanInput.value] of the input.
  ///
  /// ```dart
  /// final boolean = stateMachine.boolean('booleanInput');
  /// if (boolean != null) {
  ///   print(boolean.value);
  ///   boolean.value = true;
  /// }
  /// ```
  ///
  /// {@macro smi_input_template}
  BooleanInput? boolean(String name, {String? path});

  /// Retrieve a trigger input from the state machine with the given [name].
  /// Trigger the input by calling [TriggerInput.fire].
  ///
  /// ```dart
  /// final trigger = stateMachine.trigger('triggerInput');
  /// if (trigger != null) {
  ///  trigger.fire();
  /// }
  /// ```
  ///
  /// {@macro smi_input_template}
  TriggerInput? trigger(String name, {String? path});
  Input? inputAt(int index);

  CallbackHandler onDataBindChanged(Function() callback);
  @useResult
  CallbackHandler onInputChanged(Function(int index) callback);
  bool get isDone;
  bool hitTest(Vec2D position);
  HitResult pointerDown(Vec2D position);
  HitResult pointerMove(Vec2D position);
  HitResult pointerUp(Vec2D position);
  HitResult pointerExit(Vec2D position);

  /// This method is used internally and should not be called directly.
  /// Instead, use the [bindViewModelInstance] method.
  @internal
  void internalBindViewModelInstance(InternalViewModelInstance instance);

  /// Binds the provided [viewModelInstance] to the state machine
  ///
  /// Docs: https://rive.app/docs/runtimes/data-binding
  void bindViewModelInstance(ViewModelInstance viewModelInstance);

  /// This method is used internally and should not be called directly.
  /// Instead, use the [bindViewModelInstance] method.
  @internal
  void internalDataContext(InternalDataContext dataContext);
  List<Event> reportedEvents();
}

abstract interface class EventListenerInterface {
  /// The set of Rive event listeners
  @internal
  Set<void Function(Event)> get eventListeners;

  /// Adds a Rive event listener
  void addEventListener(OnRiveEvent callback);

  /// Removes the Rive event listener
  void removeEventListener(OnRiveEvent callback);

  // Removes all Rive event listeners
  void removeAllEventListeners();

  /// The number of Rive event listeners
  @visibleForTesting
  int get eventListenerCount;
}

mixin EventListenerMixin implements EventListenerInterface {
  final _eventListeners = <OnRiveEvent>{};

  @override
  Set<void Function(Event)> get eventListeners => _eventListeners;

  @override
  void addEventListener(OnRiveEvent callback) => _eventListeners.add(callback);

  @override
  void removeEventListener(OnRiveEvent callback) =>
      _eventListeners.remove(callback);

  @override
  void removeAllEventListeners() {
    _eventListeners.clear();
  }

  @override
  int get eventListenerCount => _eventListeners.length;
}

/// A Rive event listener callback
typedef OnRiveEvent = void Function(Event event);

/// Type of Rive event
enum EventType {
  general(128),
  openURL(131);

  final int value;
  const EventType(this.value);

  static final from = {
    128: general,
    131: openURL,
  };
}

/// The custom property type
enum CustomPropertyType {
  number(127),
  boolean(129),
  string(130);

  final int value;
  const CustomPropertyType(this.value);

  static final from = {
    127: number,
    129: boolean,
    130: string,
  };
}

/// The target for opening a URL
enum OpenUrlTarget {
  blank(0),
  parent(1),
  self(2),
  top(3);

  final int value;
  const OpenUrlTarget(this.value);

  static final from = {
    0: blank,
    1: parent,
    2: self,
    3: top,
  };
}

abstract interface class EventInterface {
  /// The name of the event
  String get name;

  /// The time in seconds since the event was triggered
  double get secondsDelay;

  /// The type of the event
  EventType get type;

  /// The set of custom properties for the event
  Map<String, CustomProperty> get properties;

  /// Retrieve a custom property from the event with the given [name].
  CustomProperty? property(String name);

  /// Retrieve a number property from the event with the given [name].
  CustomNumberProperty? numberProperty(String name);

  /// Retrieve a boolean property from the event with the given [name].
  CustomBooleanProperty? booleanProperty(String name);

  /// Retrieve a string property from the event with the given [name].
  CustomStringProperty? stringProperty(String name);

  /// Dispose the event.
  ///
  /// After calling dispose, the event should no longer be used.
  void dispose();
}

mixin EventPropertyMixin implements EventInterface {
  @override
  CustomProperty? property(String name) {
    final property = properties[name];
    return property;
  }

  @override
  CustomNumberProperty? numberProperty(String name) {
    final property = properties[name];
    if (property is CustomNumberProperty) {
      return property;
    }
    return null;
  }

  @override
  CustomBooleanProperty? booleanProperty(String name) {
    final property = properties[name];
    if (property is CustomBooleanProperty) {
      return property;
    }
    return null;
  }

  @override
  CustomStringProperty? stringProperty(String name) {
    final property = properties[name];
    if (property is CustomStringProperty) {
      return property;
    }
    return null;
  }
}

sealed class Event implements EventInterface {}

/// A general Rive event
abstract class GeneralEvent extends Event {}

/// An event for opening a URL
abstract class OpenUrlEvent extends Event {
  String get url;
  OpenUrlTarget get target;
}

abstract interface class CustomPropertyInterface<T> {
  /// The name of the custom property
  String get name;

  /// The type of the custom property
  CustomPropertyType get type;

  /// The value of the custom property
  T get value;

  /// Dispose the custom property.
  ///
  /// After calling dispose, the custom property should no longer be used.
  void dispose();
}

sealed class CustomProperty<T> implements CustomPropertyInterface<T> {}

abstract class CustomNumberProperty extends CustomProperty<double> {}

abstract class CustomBooleanProperty extends CustomProperty<bool> {}

abstract class CustomStringProperty extends CustomProperty<String> {}

abstract class Input {
  String get name;
  void dispose();
}

abstract class NumberInput extends Input {
  double get value;
  set value(double value);
}

abstract class BooleanInput extends Input {
  bool get value;
  set value(bool value);
}

abstract class TriggerInput extends Input {
  void fire();
}

abstract class Component {
  Mat2D get worldTransform;
  set worldTransform(Mat2D value);

  double get x;
  set x(double value);

  double get y;
  set y(double value);

  double get scaleX;
  set scaleX(double value);

  double get scaleY;
  set scaleY(double value);

  double get rotation;
  set rotation(double value);

  void setLocalFromWorld(Mat2D worldTransform);

  void dispose();
}
