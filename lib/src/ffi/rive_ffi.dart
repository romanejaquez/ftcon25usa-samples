import 'dart:async';
import 'dart:ffi';
import 'dart:typed_data';
import 'dart:ui' show Color;

import 'package:ffi/ffi.dart';
import 'package:meta/meta.dart';
import 'package:rive_native/math.dart';
import 'package:rive_native/rive_audio.dart';
import 'package:rive_native/rive_text.dart';
import 'package:rive_native/src/ffi/dynamic_library_helper.dart';
import 'package:rive_native/src/ffi/flutter_renderer_ffi.dart';
import 'package:rive_native/src/ffi/rive_audio_ffi.dart';
import 'package:rive_native/src/ffi/rive_data_binding_ffi.dart';
import 'package:rive_native/src/ffi/rive_event_ffi.dart';
import 'package:rive_native/src/ffi/rive_ffi_reference.dart';
import 'package:rive_native/src/ffi/rive_renderer_ffi.dart';
import 'package:rive_native/src/ffi/rive_text_ffi.dart';
import 'package:rive_native/src/rive.dart';
import 'package:rive_native/src/rive_renderer.dart';
import 'dart:io' as io;

final DynamicLibrary nativeLib = DynamicLibraryHelper.open();

/// Load a list of bytes from a file on the local filesystem at [path].
Future<Uint8List?> localFileBytes(String path) => io.File(path).readAsBytes();

typedef ViewModelNumberCallback
    = Pointer<NativeFunction<Void Function(Uint64, Float)>>;

typedef ViewModelBooleanCallback
    = Pointer<NativeFunction<Void Function(Uint64, Bool)>>;

typedef ViewModelColorCallback
    = Pointer<NativeFunction<Void Function(Uint64, Uint32)>>;

typedef ViewModelStringCallback
    = Pointer<NativeFunction<Void Function(Uint64, Pointer<Utf8>)>>;

typedef ViewModelTriggerCallback
    = Pointer<NativeFunction<Void Function(Uint64, Int)>>;

typedef ViewModelEnumCallback
    = Pointer<NativeFunction<Void Function(Uint64, Int)>>;

typedef _StateMachineInputNative = Pointer<Void> Function(
    Pointer<Void> smi, Pointer<Void> inputName, Pointer<Void> path);

typedef _AssetLoaderCallbackNative = Bool Function(
  Pointer<Void>,
  Pointer<Uint8>,
  Int,
);

typedef _AssetLoaderCallbackPointer
    = Pointer<NativeFunction<_AssetLoaderCallbackNative>>;

typedef _FreeStringNative = Void Function(Pointer<Utf8> str);

typedef _FreeString = void Function(Pointer<Utf8> str);

final freeString =
    nativeLib.lookupFunction<_FreeStringNative, _FreeString>('freeString');

final void Function(
  ViewModelNumberCallback viewModelNumberCallback,
  ViewModelBooleanCallback viewModelBooleanCallback,
  ViewModelColorCallback viewModelColorCallback,
  ViewModelStringCallback viewModelStringCallback,
  ViewModelTriggerCallback viewModelTriggerCallback,
  ViewModelEnumCallback viewModelEnumCallback,
) _initBindingCallbacks = nativeLib
    .lookup<
        NativeFunction<
            Void Function(
              ViewModelNumberCallback,
              ViewModelBooleanCallback,
              ViewModelColorCallback,
              ViewModelStringCallback,
              ViewModelTriggerCallback,
              ViewModelEnumCallback,
            )>>('initBindingCallbacks')
    .asFunction();

final Pointer<Void> Function(
  Pointer<Uint8> bytes,
  int length,
  Pointer<Void> riveFactory,
  _AssetLoaderCallbackPointer,
) _loadRiveFile = nativeLib
    .lookup<
        NativeFunction<
            Pointer<Void> Function(
              Pointer<Uint8>,
              Uint64,
              Pointer<Void>,
              _AssetLoaderCallbackPointer,
            )>>('loadRiveFile')
    .asFunction();
final Pointer<NativeFunction<Void Function(Pointer<Void>)>>
    _deleteRiveFileNative = nativeLib
        .lookup<NativeFunction<Void Function(Pointer<Void>)>>('deleteRiveFile');
final void Function(Pointer<Void> file) _deleteRiveFile =
    _deleteRiveFileNative.asFunction();
final Pointer<Void> Function(Pointer<Void>, bool frameOrigin)
    _riveFileArtboardDefault = nativeLib
        .lookup<NativeFunction<Pointer<Void> Function(Pointer<Void>, Bool)>>(
            'riveFileArtboardDefault')
        .asFunction();
final Pointer<Void> Function(
        Pointer<Void> file, Pointer<Void> name, bool frameOrigin)
    _riveFileArtboardNamed = nativeLib
        .lookup<
            NativeFunction<
                Pointer<Void> Function(Pointer<Void>, Pointer<Void> name,
                    Bool)>>('riveFileArtboardNamed')
        .asFunction();
final Pointer<Void> Function(Pointer<Void> file, int index, bool frameOrigin)
    _riveFileArtboardByIndex = nativeLib
        .lookup<
            NativeFunction<
                Pointer<Void> Function(
                    Pointer<Void>, Uint32, Bool)>>('riveFileArtboardByIndex')
        .asFunction();
final int Function(Pointer<Void>) _riveFileAssetId = nativeLib
    .lookup<NativeFunction<Uint32 Function(Pointer<Void>)>>('riveFileAssetId')
    .asFunction();
final Pointer<Utf8> Function(Pointer<Void>) _riveFileAssetName = nativeLib
    .lookup<NativeFunction<Pointer<Utf8> Function(Pointer<Void>)>>(
        'riveFileAssetName')
    .asFunction();
final Pointer<Utf8> Function(Pointer<Void>) _riveFileAssetFileExtension =
    nativeLib
        .lookup<NativeFunction<Pointer<Utf8> Function(Pointer<Void>)>>(
            'riveFileAssetFileExtension')
        .asFunction();
final Pointer<Utf8> Function(Pointer<Void>) _riveFileAssetCdnBaseUrl = nativeLib
    .lookup<NativeFunction<Pointer<Utf8> Function(Pointer<Void>)>>(
        'riveFileAssetCdnBaseUrl')
    .asFunction();
final Pointer<Utf8> Function(Pointer<Void>) _riveFileAssetCdnUuid = nativeLib
    .lookup<NativeFunction<Pointer<Utf8> Function(Pointer<Void>)>>(
        'riveFileAssetCdnUuid')
    .asFunction();
final int Function(Pointer<Void>) _riveFileAssetCoreType = nativeLib
    .lookup<NativeFunction<Uint16 Function(Pointer<Void>)>>(
        'riveFileAssetCoreType')
    .asFunction();
final bool Function(Pointer<Void>, Pointer<Void>) riveFileAssetSetRenderImage =
    nativeLib
        .lookup<NativeFunction<Bool Function(Pointer<Void>, Pointer<Void>)>>(
            'riveFileAssetSetRenderImage')
        .asFunction();
final bool Function(Pointer<Void>, Pointer<Void>) riveFileAssetSetFont =
    nativeLib
        .lookup<NativeFunction<Bool Function(Pointer<Void>, Pointer<Void>)>>(
            'riveFileAssetSetFont')
        .asFunction();
final bool Function(Pointer<Void>, Pointer<Void>) riveFileAssetSetAudioSource =
    nativeLib
        .lookup<NativeFunction<Bool Function(Pointer<Void>, Pointer<Void>)>>(
            'riveFileAssetSetAudioSource')
        .asFunction();
final Pointer<Void> Function(Pointer<Void> file, int index, int indexInstance)
    _riveDataContext = nativeLib
        .lookup<
            NativeFunction<
                Pointer<Void> Function(
                    Pointer<Void>, Uint64, Uint64)>>('riveDataContext')
        .asFunction();
final Pointer<Void> Function(Pointer<Void> dataContext)
    _riveDataContextViewModelInstance = nativeLib
        .lookup<NativeFunction<Pointer<Void> Function(Pointer<Void>)>>(
            'riveDataContextViewModelInstance')
        .asFunction();
final Pointer<NativeFunction<Void Function(Pointer<Void>)>>
    _deleteDataContextNative =
    nativeLib.lookup<NativeFunction<Void Function(Pointer<Void>)>>(
        'deleteDataContext');
final void Function(Pointer<Void> file) _deleteDataContext =
    _deleteDataContextNative.asFunction();

final int Function(Pointer<Void> dataBind) _riveDataBindDirt = nativeLib
    .lookup<NativeFunction<Uint64 Function(Pointer<Void>)>>('riveDataBindDirt')
    .asFunction();

final void Function(Pointer<Void> dataBind, int dirt) _riveDataBindSetDirt =
    nativeLib
        .lookup<NativeFunction<Void Function(Pointer<Void>, Uint64)>>(
            'riveDataBindSetDirt')
        .asFunction();
final int Function(Pointer<Void> dataBind) _riveDataBindFlags = nativeLib
    .lookup<NativeFunction<Uint64 Function(Pointer<Void>)>>('riveDataBindFlags')
    .asFunction();
final int Function(Pointer<Void> dataBind, int dirt) _riveDataBindUpdate =
    nativeLib
        .lookup<NativeFunction<Uint64 Function(Pointer<Void>, Uint64)>>(
            'riveDataBindUpdate')
        .asFunction();
final int Function(Pointer<Void> dataBind) _riveDataBindUpdateSourceBinding =
    nativeLib
        .lookup<NativeFunction<Uint64 Function(Pointer<Void>)>>(
            'riveDataBindUpdateSourceBinding')
        .asFunction();
final void Function(Pointer<Void> artboard, Pointer<Float> out)
    _artboardBounds = nativeLib
        .lookup<NativeFunction<Void Function(Pointer<Void>, Pointer<Float>)>>(
            'artboardBounds')
        .asFunction();
final void Function(Pointer<Void> artboard, Pointer<Void> renderer)
    _artboardDraw = nativeLib
        .lookup<NativeFunction<Void Function(Pointer<Void>, Pointer<Void>)>>(
            'artboardDraw')
        .asFunction();
final void Function(Pointer<Void> artboard, Pointer<Void> renderPath, double,
        double, double, double, double, double) _artboardAddToRenderPath =
    nativeLib
        .lookup<
            NativeFunction<
                Void Function(Pointer<Void>, Pointer<Void>, Float, Float, Float,
                    Float, Float, Float)>>('artboardAddToRenderPath')
        .asFunction();
final int Function(Pointer<Void> artboard) _artboardAnimationCount = nativeLib
    .lookup<NativeFunction<Uint64 Function(Pointer<Void>)>>(
        'artboardAnimationCount')
    .asFunction();
final int Function(Pointer<Void> artboard) _artboardStateMachineCount =
    nativeLib
        .lookup<NativeFunction<Uint64 Function(Pointer<Void>)>>(
            'artboardStateMachineCount')
        .asFunction();
final Pointer<Void> Function(Pointer<Void> artboard, int index)
    _artboardAnimationAt = nativeLib
        .lookup<NativeFunction<Pointer<Void> Function(Pointer<Void>, Uint64)>>(
            'artboardAnimationAt')
        .asFunction();
final Pointer<Void> Function(Pointer<Void> artboard, int index)
    _artboardStateMachineAt = nativeLib
        .lookup<NativeFunction<Pointer<Void> Function(Pointer<Void>, Uint64)>>(
            'riveArtboardStateMachineAt')
        .asFunction();
final bool Function(Pointer<Void> artboard) _artboardGetFrameOrigin = nativeLib
    .lookup<NativeFunction<Bool Function(Pointer<Void>)>>(
        'artboardGetFrameOrigin')
    .asFunction();
final bool Function(Pointer<Void> artboard, double seconds, int flags)
    _artboardAdvance = nativeLib
        .lookup<NativeFunction<Bool Function(Pointer<Void>, Float, Int)>>(
            'riveArtboardAdvance')
        .asFunction();
final double Function(Pointer<Void> artboard) _riveArtboardGetOpacity =
    nativeLib
        .lookup<NativeFunction<Float Function(Pointer<Void>)>>(
            'riveArtboardGetOpacity')
        .asFunction();
final void Function(Pointer<Void> artboard, double opacity)
    _riveArtboardSetOpacity = nativeLib
        .lookup<NativeFunction<Void Function(Pointer<Void>, Float)>>(
            'riveArtboardSetOpacity')
        .asFunction();
final bool Function(Pointer<Void> artboard) _riveArtboardUpdatePass = nativeLib
    .lookup<NativeFunction<Bool Function(Pointer<Void>)>>(
        'riveArtboardUpdatePass')
    .asFunction();
final bool Function(Pointer<Void> artboard) _riveArtboardHasComponentDirt =
    nativeLib
        .lookup<NativeFunction<Bool Function(Pointer<Void>)>>(
            'riveArtboardHasComponentDirt')
        .asFunction();
final double Function(Pointer<Void> artboard) _riveArtboardGetWidth = nativeLib
    .lookup<NativeFunction<Float Function(Pointer<Void>)>>(
        'riveArtboardGetWidth')
    .asFunction();
final void Function(Pointer<Void> artboard, double width)
    _riveArtboardSetWidth = nativeLib
        .lookup<NativeFunction<Void Function(Pointer<Void>, Float)>>(
            'riveArtboardSetWidth')
        .asFunction();
final double Function(Pointer<Void> artboard) _riveArtboardGetHeight = nativeLib
    .lookup<NativeFunction<Float Function(Pointer<Void>)>>(
        'riveArtboardGetHeight')
    .asFunction();
final void Function(Pointer<Void> artboard, double height)
    _riveArtboardSetHeight = nativeLib
        .lookup<NativeFunction<Void Function(Pointer<Void>, Float)>>(
            'riveArtboardSetHeight')
        .asFunction();
final double Function(Pointer<Void> artboard) _riveArtboardGetOriginalWidth =
    nativeLib
        .lookup<NativeFunction<Float Function(Pointer<Void>)>>(
            'riveArtboardGetOriginalWidth')
        .asFunction();
final double Function(Pointer<Void> artboard) _riveArtboardGetOriginalHeight =
    nativeLib
        .lookup<NativeFunction<Float Function(Pointer<Void>)>>(
            'riveArtboardGetOriginalHeight')
        .asFunction();
final Pointer<Utf8> Function(
        Pointer<Void> artboard, Pointer<Void> runName, Pointer<Void> path)
    _artboardGetText = nativeLib
        .lookup<
            NativeFunction<
                Pointer<Utf8> Function(
                    Pointer<Void> artboard,
                    Pointer<Void> runName,
                    Pointer<Void> path)>>('artboardGetText')
        .asFunction();
final bool Function(Pointer<Void> artboard, Pointer<Void> runName,
        Pointer<Void> value, Pointer<Void> path) _artboardSetText =
    nativeLib
        .lookup<
            NativeFunction<
                Bool Function(
                    Pointer<Void> artboard,
                    Pointer<Void> runName,
                    Pointer<Void> value,
                    Pointer<Void> path)>>('artboardSetText')
        .asFunction();
final bool Function(Pointer<Void> artboard, bool value)
    _artboardSetFrameOrigin = nativeLib
        .lookup<NativeFunction<Bool Function(Pointer<Void>, Bool value)>>(
            'artboardSetFrameOrigin')
        .asFunction();
final Pointer<Void> Function(Pointer<Void> artboard, Pointer<Void> name)
    _artboardComponentNamed = nativeLib
        .lookup<
            NativeFunction<
                Pointer<Void> Function(Pointer<Void>,
                    Pointer<Void> name)>>('artboardComponentNamed')
        .asFunction();
final void Function(Pointer<Void> component, Pointer<Float> out)
    _componentGetWorldTransform = nativeLib
        .lookup<NativeFunction<Void Function(Pointer<Void>, Pointer<Float>)>>(
            'componentGetWorldTransform')
        .asFunction();

final void Function(
  Pointer<Void> artboard,
  double xx,
  double xy,
  double yx,
  double yy,
  double tx,
  double ty,
) _componentSetWorldTransform = nativeLib
    .lookup<
        NativeFunction<
            Void Function(Pointer<Void>, Float xx, Float xy, Float yx, Float yy,
                Float tx, Float ty)>>('componentSetWorldTransform')
    .asFunction();
final void Function(Pointer<Void> component, Pointer<Float> out)
    _artboardGetRenderTransform = nativeLib
        .lookup<NativeFunction<Void Function(Pointer<Void>, Pointer<Float>)>>(
            'artboardGetRenderTransform')
        .asFunction();
final void Function(
  Pointer<Void> artboard,
  double xx,
  double xy,
  double yx,
  double yy,
  double tx,
  double ty,
) _artboardSetRenderTransform = nativeLib
    .lookup<
        NativeFunction<
            Void Function(Pointer<Void>, Float xx, Float xy, Float yx, Float yy,
                Float tx, Float ty)>>('artboardSetRenderTransform')
    .asFunction();
final void Function(
  Pointer<Void> artboard,
  double xx,
  double xy,
  double yx,
  double yy,
  double tx,
  double ty,
) _componentSetLocalFromWorld = nativeLib
    .lookup<
        NativeFunction<
            Void Function(Pointer<Void>, Float xx, Float xy, Float yx, Float yy,
                Float tx, Float ty)>>('componentSetLocalFromWorld')
    .asFunction();
final double Function(Pointer<Void> component) _componentGetScaleX = nativeLib
    .lookup<NativeFunction<Float Function(Pointer<Void>)>>('componentGetScaleX')
    .asFunction();
final void Function(Pointer<Void> component, double value) _componentSetScaleX =
    nativeLib
        .lookup<NativeFunction<Void Function(Pointer<Void>, Float)>>(
            'componentSetScaleX')
        .asFunction();
final double Function(Pointer<Void> component) _componentGetScaleY = nativeLib
    .lookup<NativeFunction<Float Function(Pointer<Void>)>>('componentGetScaleY')
    .asFunction();
final void Function(Pointer<Void> component, double value) _componentSetScaleY =
    nativeLib
        .lookup<NativeFunction<Void Function(Pointer<Void>, Float)>>(
            'componentSetScaleY')
        .asFunction();
final void Function(Pointer<Void> component, double value) _componentSetX =
    nativeLib
        .lookup<NativeFunction<Void Function(Pointer<Void>, Float)>>(
            'componentSetX')
        .asFunction();
final double Function(Pointer<Void> component) _componentGetX = nativeLib
    .lookup<NativeFunction<Float Function(Pointer<Void>)>>('componentGetX')
    .asFunction();
final void Function(Pointer<Void> component, double value) _componentSetY =
    nativeLib
        .lookup<NativeFunction<Void Function(Pointer<Void>, Float)>>(
            'componentSetY')
        .asFunction();
final double Function(Pointer<Void> component) _componentGetY = nativeLib
    .lookup<NativeFunction<Float Function(Pointer<Void>)>>('componentGetY')
    .asFunction();
final double Function(Pointer<Void> component) _componentGetRotation = nativeLib
    .lookup<NativeFunction<Float Function(Pointer<Void>)>>(
        'componentGetRotation')
    .asFunction();
final void Function(Pointer<Void> component, double value)
    _componentSetRotation = nativeLib
        .lookup<NativeFunction<Void Function(Pointer<Void>, Float)>>(
            'componentSetRotation')
        .asFunction();
final Pointer<Void> Function(Pointer<Void> artboard, Pointer<Void> name)
    _artboardAnimationNamed = nativeLib
        .lookup<
            NativeFunction<
                Pointer<Void> Function(Pointer<Void>,
                    Pointer<Void> name)>>('artboardAnimationNamed')
        .asFunction();
final Pointer<NativeFunction<Void Function(Pointer<Void>)>>
    _deleteArtboardInstanceNative =
    nativeLib.lookup<NativeFunction<Void Function(Pointer<Void>)>>(
        'deleteArtboardInstance');
final void Function(Pointer<Void> file) _deleteArtboardInstance =
    _deleteArtboardInstanceNative.asFunction();
final Pointer<Void> Function(Pointer<Void> file)
    _riveArtboardStateMachineDefault = nativeLib
        .lookup<NativeFunction<Pointer<Void> Function(Pointer<Void>)>>(
            'riveArtboardStateMachineDefault')
        .asFunction();
final Pointer<Void> Function(Pointer<Void> file, Pointer<Void> name)
    _riveArtboardStateMachineNamed = nativeLib
        .lookup<
            NativeFunction<
                Pointer<Void> Function(Pointer<Void>,
                    Pointer<Void> name)>>('riveArtboardStateMachineNamed')
        .asFunction();
final Pointer<NativeFunction<Void Function(Pointer<Void>)>>
    _animationInstanceDeleteNative =
    nativeLib.lookup<NativeFunction<Void Function(Pointer<Void>)>>(
        'animationInstanceDelete');
final void Function(Pointer<Void> smi) _animationInstanceDelete =
    _animationInstanceDeleteNative.asFunction();
final Pointer<NativeFunction<Void Function(Pointer<Void>)>>
    _deleteStateMachineInstanceNative =
    nativeLib.lookup<NativeFunction<Void Function(Pointer<Void>)>>(
        'deleteStateMachineInstance');
final void Function(Pointer<Void> smi) _deleteStateMachineInstance =
    _deleteStateMachineInstanceNative.asFunction();
final bool Function(Pointer<Void> ami, double) _animationInstanceAdvance =
    nativeLib
        .lookup<NativeFunction<Bool Function(Pointer<Void>, Float)>>(
            'animationInstanceAdvance')
        .asFunction();

final double Function(Pointer<Void> ami) _animationInstanceGetTime = nativeLib
    .lookup<NativeFunction<Float Function(Pointer<Void>)>>(
        'animationInstanceGetTime')
    .asFunction();
final double Function(Pointer<Void> ami) _animationInstanceGetDuration =
    nativeLib
        .lookup<NativeFunction<Float Function(Pointer<Void>)>>(
            'animationInstanceGetDuration')
        .asFunction();
final double Function(Pointer<Void> ami, double)
    animationInstanceGetLocalSeconds = nativeLib
        .lookup<NativeFunction<Float Function(Pointer<Void>, Float)>>(
            'animationInstanceGetLocalSeconds')
        .asFunction();
final void Function(Pointer<Void> ami, double) _animationInstanceSetTime =
    nativeLib
        .lookup<NativeFunction<Void Function(Pointer<Void>, Float)>>(
            'animationInstanceSetTime')
        .asFunction();

final bool Function(Pointer<Void> ami, double)
    _animationInstanceAdvanceAndApply = nativeLib
        .lookup<NativeFunction<Bool Function(Pointer<Void>, Float)>>(
            'animationInstanceAdvanceAndApply')
        .asFunction();
final void Function(Pointer<Void> ami, double) _animationInstanceApply =
    nativeLib
        .lookup<NativeFunction<Void Function(Pointer<Void>, Float)>>(
            'animationInstanceApply')
        .asFunction();
final bool Function(Pointer<Void> ami, double, bool)
    _stateMachineInstanceAdvance = nativeLib
        .lookup<NativeFunction<Bool Function(Pointer<Void>, Float, Bool)>>(
            'stateMachineInstanceAdvance')
        .asFunction();
final bool Function(Pointer<Void> ami, double)
    _stateMachineInstanceAdvanceAndApply = nativeLib
        .lookup<NativeFunction<Bool Function(Pointer<Void>, Float)>>(
            'stateMachineInstanceAdvanceAndApply')
        .asFunction();
final bool Function(Pointer<Void> ami, double x, double y)
    _stateMachineInstanceHitTest = nativeLib
        .lookup<NativeFunction<Bool Function(Pointer<Void>, Float, Float)>>(
            'stateMachineInstanceHitTest')
        .asFunction();
final int Function(Pointer<Void> ami, double x, double y)
    _stateMachineInstancePointerDown = nativeLib
        .lookup<NativeFunction<Uint8 Function(Pointer<Void>, Float, Float)>>(
            'stateMachineInstancePointerDown')
        .asFunction();
final int Function(Pointer<Void> ami, double x, double y)
    _stateMachineInstancePointerUp = nativeLib
        .lookup<NativeFunction<Uint8 Function(Pointer<Void>, Float, Float)>>(
            'stateMachineInstancePointerUp')
        .asFunction();
final int Function(Pointer<Void> ami, double x, double y)
    _stateMachineInstancePointerMove = nativeLib
        .lookup<NativeFunction<Uint8 Function(Pointer<Void>, Float, Float)>>(
            'stateMachineInstancePointerMove')
        .asFunction();
final int Function(Pointer<Void> ami, double x, double y)
    _stateMachineInstancePointerExit = nativeLib
        .lookup<NativeFunction<Uint8 Function(Pointer<Void>, Float, Float)>>(
            'stateMachineInstancePointerExit')
        .asFunction();
final Pointer<Void> Function(
    Pointer<Void> smi,
    int
        index) _stateMachineInput = nativeLib
    .lookup<NativeFunction<Pointer<Void> Function(Pointer<Void>, Uint64 name)>>(
        'stateMachineInput')
    .asFunction();
final int Function(Pointer<Void> input) _stateMachineInputType = nativeLib
    .lookup<NativeFunction<Uint16 Function(Pointer<Void>)>>(
        'stateMachineInputType')
    .asFunction();
final Pointer<Utf8> Function(Pointer<Void> input) _stateMachineInputName =
    nativeLib
        .lookup<NativeFunction<Pointer<Utf8> Function(Pointer<Void>)>>(
            'stateMachineInputName')
        .asFunction();
final _StateMachineInputNative _stateMachineInstanceNumber = nativeLib
    .lookup<NativeFunction<_StateMachineInputNative>>(
        'stateMachineInstanceNumber')
    .asFunction();
final bool Function(Pointer<Void> smi) _stateMachineInstanceDone = nativeLib
    .lookup<NativeFunction<Bool Function(Pointer<Void>)>>(
        'stateMachineInstanceDone')
    .asFunction();
final double Function(Pointer<Void>) _getNumberValue = nativeLib
    .lookup<NativeFunction<Float Function(Pointer<Void>)>>('getNumberValue')
    .asFunction();
final void Function(Pointer<Void>, double) _setNumberValue = nativeLib
    .lookup<NativeFunction<Void Function(Pointer<Void>, Float)>>(
        'setNumberValue')
    .asFunction();
void Function(Pointer<Void>,
        Pointer<NativeFunction<Void Function(Pointer<Void>, Uint64)>>)
    _setStateMachineInputChangedCallback = nativeLib
        .lookup<
                NativeFunction<
                    Void Function(
                        Pointer<Void>,
                        Pointer<
                            NativeFunction<
                                Void Function(Pointer<Void>, Uint64)>>)>>(
            'setStateMachineInputChangedCallback')
        .asFunction();
void Function(Pointer<Void>, Pointer<NativeFunction<Void Function()>>)
    _setStateMachineDataBindChangedCallback = nativeLib
        .lookup<
                NativeFunction<
                    Void Function(Pointer<Void>,
                        Pointer<NativeFunction<Void Function()>>)>>(
            'setStateMachineDataBindChangedCallback')
        .asFunction();
void Function(
        Pointer<Void>, Pointer<NativeFunction<Void Function(Pointer<Void>)>>)
    _setArtboardLayoutChangedCallback = nativeLib
        .lookup<
                NativeFunction<
                    Void Function(
                        Pointer<Void>,
                        Pointer<
                            NativeFunction<Void Function(Pointer<Void>)>>)>>(
            'setArtboardLayoutChangedCallback')
        .asFunction();
void Function(Pointer<Void>,
        Pointer<NativeFunction<Void Function(Pointer<Void>, Uint32)>>)
    _setArtboardEventCallback = nativeLib
        .lookup<
            NativeFunction<
                Void Function(
                    Pointer<Void>,
                    Pointer<
                        NativeFunction<
                            Void Function(Pointer<Void>,
                                Uint32)>>)>>('setArtboardEventCallback')
        .asFunction();
final _StateMachineInputNative _stateMachineInstanceBoolean = nativeLib
    .lookup<NativeFunction<_StateMachineInputNative>>(
        'stateMachineInstanceBoolean')
    .asFunction();
final Pointer<NativeFunction<Void Function(Pointer<Void>)>> _deleteInputNative =
    nativeLib
        .lookup<NativeFunction<Void Function(Pointer<Void>)>>('deleteInput');
final void Function(Pointer<Void> file) _deleteInput =
    _deleteInputNative.asFunction();

final Pointer<NativeFunction<Void Function(Pointer<Void>)>>
    _deleteComponentNative =
    nativeLib.lookup<NativeFunction<Void Function(Pointer<Void>)>>(
        'deleteComponent');
final void Function(Pointer<Void> file) _deleteComponent =
    _deleteComponentNative.asFunction();
final bool Function(Pointer<Void>) _getBooleanValue = nativeLib
    .lookup<NativeFunction<Bool Function(Pointer<Void>)>>('getBooleanValue')
    .asFunction();
final void Function(Pointer<Void>, bool) _setBooleanValue = nativeLib
    .lookup<NativeFunction<Void Function(Pointer<Void>, Bool)>>(
        'setBooleanValue')
    .asFunction();
final _StateMachineInputNative _stateMachineInstanceTrigger = nativeLib
    .lookup<NativeFunction<_StateMachineInputNative>>(
        'stateMachineInstanceTrigger')
    .asFunction();
final void Function(Pointer<Void> stateMachine, Pointer<Void> viewModelInstance)
    _stateMachineDataContextFromInstance = nativeLib
        .lookup<NativeFunction<Void Function(Pointer<Void>, Pointer<Void>)>>(
            'stateMachineDataContextFromInstance')
        .asFunction();
final void Function(Pointer<Void> stateMachine, Pointer<Void> dataContext)
    _stateMachineDataContext = nativeLib
        .lookup<NativeFunction<Void Function(Pointer<Void>, Pointer<Void>)>>(
            'stateMachineDataContext')
        .asFunction();
final void Function(Pointer<Void>) _fireTrigger = nativeLib
    .lookup<NativeFunction<Void Function(Pointer<Void>)>>('fireTrigger')
    .asFunction();
final void Function(Pointer<Pointer<Void>>, int, double) _batchAdvance =
    nativeLib
        .lookup<
            NativeFunction<
                Void Function(Pointer<Pointer<Void>>, Uint64,
                    Float)>>('stateMachineInstanceBatchAdvance')
        .asFunction();
final void Function(Pointer<Pointer<Void>>, int, double, Pointer<Void>)
    _batchAdvanceAndRender = nativeLib
        .lookup<
                NativeFunction<
                    Void Function(
                        Pointer<Pointer<Void>>, Uint64, Float, Pointer<Void>)>>(
            'stateMachineInstanceBatchAdvanceAndRender')
        .asFunction();
final int Function(Pointer<Void> stateMachine)
    _stateMachineGetReportedEventCount = nativeLib
        .lookup<NativeFunction<IntPtr Function(Pointer<Void>)>>(
            'stateMachineGetReportedEventCount')
        .asFunction();
final ReportedEventStruct Function(Pointer<Void> stateMachine, int index)
    _stateMachineReportedEventAt = nativeLib
        .lookup<
            NativeFunction<
                ReportedEventStruct Function(
                    Pointer<Void>, IntPtr)>>('stateMachineReportedEventAt')
        .asFunction();
final Pointer<NativeFunction<Void Function(Pointer<Void>)>> _deleteEventNative =
    nativeLib
        .lookup<NativeFunction<Void Function(Pointer<Void>)>>('deleteEvent');
final void Function(Pointer<Void> file) _deleteEvent =
    _deleteEventNative.asFunction();
final Pointer<NativeFunction<Void Function(Pointer<Void>)>>
    _deleteCustomPropertyNative =
    nativeLib.lookup<NativeFunction<Void Function(Pointer<Void>)>>(
        'deleteCustomProperty');
final void Function(Pointer<Void> file) _deleteCustomProperty =
    _deleteCustomPropertyNative.asFunction();
final Pointer<Utf8> Function(Pointer<Void>) _getEventName = nativeLib
    .lookup<NativeFunction<Pointer<Utf8> Function(Pointer<Void>)>>(
        'getEventName')
    .asFunction();
final Pointer<Utf8> Function(Pointer<Void>) _getOpenUrlEventUrl = nativeLib
    .lookup<NativeFunction<Pointer<Utf8> Function(Pointer<Void>)>>(
        'getOpenUrlEventUrl')
    .asFunction();
final int Function(Pointer<Void>) _getOpenUrlEventTarget = nativeLib
    .lookup<NativeFunction<Uint32 Function(Pointer<Void>)>>(
        'getOpenUrlEventTarget')
    .asFunction();
final int Function(Pointer<Void> stateMachine) _getEventCustomPropertyCount =
    nativeLib
        .lookup<NativeFunction<IntPtr Function(Pointer<Void>)>>(
            'getEventCustomPropertyCount')
        .asFunction();
final CustomPropertyStruct Function(Pointer<Void> event, int index)
    _getEventCustomProperty = nativeLib
        .lookup<
            NativeFunction<
                CustomPropertyStruct Function(
                    Pointer<Void>, IntPtr)>>('getEventCustomProperty')
        .asFunction();
final double Function(Pointer<Void> property) _getCustomPropertyNumber =
    nativeLib
        .lookup<NativeFunction<Float Function(Pointer<Void> property)>>(
            'getCustomPropertyNumber')
        .asFunction();
final bool Function(Pointer<Void> property) _getCustomPropertyBoolean =
    nativeLib
        .lookup<NativeFunction<Bool Function(Pointer<Void> property)>>(
            'getCustomPropertyBoolean')
        .asFunction();
final Pointer<Utf8> Function(Pointer<Void> property) _getCustomPropertyString =
    nativeLib
        .lookup<NativeFunction<Pointer<Utf8> Function(Pointer<Void> property)>>(
            'getCustomPropertyString')
        .asFunction();

final void Function(Pointer<Void> artboard, Pointer<Float> out)
    _artboardLayoutBounds = nativeLib
        .lookup<NativeFunction<Void Function(Pointer<Void>, Pointer<Float>)>>(
            'artboardLayoutBounds')
        .asFunction();
final Pointer<Void> Function(Pointer<Void> artboard) _artboardTakeLayoutNode =
    nativeLib
        .lookup<NativeFunction<Pointer<Void> Function(Pointer<Void>)>>(
            'artboardTakeLayoutNode')
        .asFunction();
final void Function(Pointer<Void> artboard) _artboardSyncStyleChanges =
    nativeLib
        .lookup<NativeFunction<Void Function(Pointer<Void>)>>(
            'artboardSyncStyleChanges')
        .asFunction();
final void Function(Pointer<Void> artboard, Pointer<Void> viewModelInstance,
        Pointer<Void> dataContext) _artboardDataContextFromInstance =
    nativeLib
        .lookup<
            NativeFunction<
                Void Function(Pointer<Void>, Pointer<Void>,
                    Pointer<Void>)>>('artboardDataContextFromInstance')
        .asFunction();
final void Function(Pointer<Void> artboard, Pointer<Void> dataContext)
    _artboardInternalDataContext = nativeLib
        .lookup<NativeFunction<Void Function(Pointer<Void>, Pointer<Void>)>>(
            'artboardInternalDataContext')
        .asFunction();
final Pointer<Void> Function(Pointer<Void> artboard) _artboardDataContext =
    nativeLib
        .lookup<NativeFunction<Pointer<Void> Function(Pointer<Void>)>>(
            'artboardDataContext')
        .asFunction();
final void Function(Pointer<Void> artboard) _artboardClearDataContext =
    nativeLib
        .lookup<NativeFunction<Void Function(Pointer<Void>)>>(
            'artboardClearDataContext')
        .asFunction();
final int Function(Pointer<Void> artboard) _artboardTotalDataBinds = nativeLib
    .lookup<NativeFunction<Uint16 Function(Pointer<Void>)>>(
        'artboardTotalDataBinds')
    .asFunction();
final int Function(Pointer<Void> artboard) _artboardCollectDataBinds = nativeLib
    .lookup<NativeFunction<Uint16 Function(Pointer<Void>)>>(
        'artboardCollectDataBinds')
    .asFunction();
final Pointer<Void> Function(Pointer<Void> artboard, int index)
    _artboardDataBindAt = nativeLib
        .lookup<NativeFunction<Pointer<Void> Function(Pointer<Void>, Uint64)>>(
            'artboardDataBindAt')
        .asFunction();
final Pointer<Void> Function(Pointer<Void> artboard, double, int, bool)
    _artboardWidthOverride = nativeLib
        .lookup<
            NativeFunction<
                Pointer<Void> Function(Pointer<Void>, Float, Uint64,
                    Bool)>>('artboardWidthOverride')
        .asFunction();
final Pointer<Void> Function(Pointer<Void> artboard, double, int, bool)
    _artboardHeightOverride = nativeLib
        .lookup<
            NativeFunction<
                Pointer<Void> Function(Pointer<Void>, Float, Uint64,
                    Bool)>>('artboardHeightOverride')
        .asFunction();
final Pointer<Void> Function(Pointer<Void> artboard, bool)
    _artboardWidthIntrinsicallySizeOverride = nativeLib
        .lookup<NativeFunction<Pointer<Void> Function(Pointer<Void>, Bool)>>(
            'artboardWidthIntrinsicallySizeOverride')
        .asFunction();
final Pointer<Void> Function(Pointer<Void> artboard, bool)
    _artboardHeightIntrinsicallySizeOverride = nativeLib
        .lookup<NativeFunction<Pointer<Void> Function(Pointer<Void>, Bool)>>(
            'artboardHeightIntrinsicallySizeOverride')
        .asFunction();
final Pointer<Void> Function(Pointer<Void> artboard, bool) _updateLayoutBounds =
    nativeLib
        .lookup<NativeFunction<Pointer<Void> Function(Pointer<Void>, Bool)>>(
            'updateLayoutBounds')
        .asFunction();
final Pointer<Void> Function(Pointer<Void> artboard, int) _cascadeLayoutStyle =
    nativeLib
        .lookup<NativeFunction<Pointer<Void> Function(Pointer<Void>, Uint64)>>(
            'cascadeLayoutStyle')
        .asFunction();
void Function(Pointer<Void>, Pointer<NativeFunction<Void Function()>>)
    _setArtboardLayoutDirtyCallback = nativeLib
        .lookup<
                NativeFunction<
                    Void Function(Pointer<Void>,
                        Pointer<NativeFunction<Void Function()>>)>>(
            'setArtboardLayoutDirtyCallback')
        .asFunction();

final Pointer<Void> Function(Pointer<Void>, int index)
    _viewModelInstancePropertyValue = nativeLib
        .lookup<NativeFunction<Pointer<Void> Function(Pointer<Void>, Uint64)>>(
            'viewModelInstancePropertyValue')
        .asFunction();
final Pointer<NativeFunction<Void Function(Pointer<Void>)>>
    _deleteViewModelInstanceValueNative =
    nativeLib.lookup<NativeFunction<Void Function(Pointer<Void>)>>(
        'deleteViewModelInstanceValue');
final void Function(Pointer<Void> file) _deleteViewModelInstanceValue =
    _deleteViewModelInstanceValueNative.asFunction();

final Pointer<Void> Function(Pointer<Void>)
    _viewModelInstanceReferenceViewModel = nativeLib
        .lookup<NativeFunction<Pointer<Void> Function(Pointer<Void>)>>(
            'viewModelInstanceReferenceViewModel')
        .asFunction();
final Pointer<Void> Function(Pointer<Void> viewModelInstance, int index)
    _viewModelInstanceListItemViewModel = nativeLib
        .lookup<NativeFunction<Pointer<Void> Function(Pointer<Void>, Uint64)>>(
            'viewModelInstanceListItemViewModel')
        .asFunction();

final Pointer<NativeFunction<Void Function(Pointer<Void>)>>
    _deleteViewModelInstanceNative =
    nativeLib.lookup<NativeFunction<Void Function(Pointer<Void>)>>(
        'deleteViewModelInstance');
final void Function(Pointer<Void> file) _deleteViewModelInstance =
    _deleteViewModelInstanceNative.asFunction();
final Pointer<Void> Function(Pointer<Void>)
    _setViewModelInstanceNumberCallback = nativeLib
        .lookup<NativeFunction<Pointer<Void> Function(Pointer<Void>)>>(
            'setViewModelInstanceNumberCallback')
        .asFunction();
final Pointer<Void> Function(Pointer<Void>)
    _setViewModelInstanceBooleanCallback = nativeLib
        .lookup<NativeFunction<Pointer<Void> Function(Pointer<Void>)>>(
            'setViewModelInstanceBooleanCallback')
        .asFunction();
final Pointer<Void> Function(Pointer<Void>) _setViewModelInstanceColorCallback =
    nativeLib
        .lookup<NativeFunction<Pointer<Void> Function(Pointer<Void>)>>(
            'setViewModelInstanceColorCallback')
        .asFunction();
final Pointer<Void> Function(Pointer<Void>)
    _setViewModelInstanceStringCallback = nativeLib
        .lookup<NativeFunction<Pointer<Void> Function(Pointer<Void>)>>(
            'setViewModelInstanceStringCallback')
        .asFunction();
final Pointer<Void> Function(Pointer<Void>)
    _setViewModelInstanceTriggerCallback = nativeLib
        .lookup<NativeFunction<Pointer<Void> Function(Pointer<Void>)>>(
            'setViewModelInstanceTriggerCallback')
        .asFunction();
final void Function(Pointer<Void>) _setViewModelInstanceTriggerAdvanced =
    nativeLib
        .lookup<NativeFunction<Void Function(Pointer<Void>)>>(
            'setViewModelInstanceTriggerAdvanced')
        .asFunction();
final Pointer<Void> Function(Pointer<Void>) _setViewModelInstanceEnumCallback =
    nativeLib
        .lookup<NativeFunction<Pointer<Void> Function(Pointer<Void>)>>(
            'setViewModelInstanceEnumCallback')
        .asFunction();
final void Function(Pointer<Void>, double) _setViewModelInstanceNumberValue =
    nativeLib
        .lookup<NativeFunction<Void Function(Pointer<Void>, Float)>>(
            'setViewModelInstanceNumberValue')
        .asFunction();
final void Function(Pointer<Void>, bool) _setViewModelInstanceBooleanValue =
    nativeLib
        .lookup<NativeFunction<Void Function(Pointer<Void>, Bool)>>(
            'setViewModelInstanceBooleanValue')
        .asFunction();
final void Function(Pointer<Void>, int) _setViewModelInstanceColorValue =
    nativeLib
        .lookup<NativeFunction<Void Function(Pointer<Void>, Uint64)>>(
            'setViewModelInstanceColorValue')
        .asFunction();
final void Function(Pointer<Void>, Pointer<Void>)
    _setViewModelInstanceStringValue = nativeLib
        .lookup<NativeFunction<Void Function(Pointer<Void>, Pointer<Void>)>>(
            'setViewModelInstanceStringValue')
        .asFunction();
final void Function(Pointer<Void>, int) _setViewModelInstanceTriggerValue =
    nativeLib
        .lookup<NativeFunction<Void Function(Pointer<Void>, Uint32)>>(
            'setViewModelInstanceTriggerValue')
        .asFunction();
final void Function(Pointer<Void>, int) _setViewModelInstanceEnumValue =
    nativeLib
        .lookup<NativeFunction<Void Function(Pointer<Void>, Uint32)>>(
            'setViewModelInstanceEnumValue')
        .asFunction();

final Pointer<Void> Function(Pointer<Void>) _makeRawText = nativeLib
    .lookup<NativeFunction<Pointer<Void> Function(Pointer<Void>)>>(
        'makeRawText')
    .asFunction();

abstract class _NativeFile {
  static final int Function(Pointer<Void> file) viewModelCount = nativeLib
      .lookup<NativeFunction<Uint64 Function(Pointer<Void>)>>(
          'riveFileViewModelCount')
      .asFunction();
  static final Pointer<Void> Function(
      Pointer<Void> file,
      int
          index) viewModelRuntimeByIndex = nativeLib
      .lookup<NativeFunction<Pointer<Void> Function(Pointer<Void>, Uint32)>>(
          'riveFileViewModelRuntimeByIndex')
      .asFunction();
  static final Pointer<Void> Function(Pointer<Void> file, Pointer<Void> name)
      viewModelRuntimeByName = nativeLib
          .lookup<
              NativeFunction<
                  Pointer<Void> Function(Pointer<Void>,
                      Pointer<Void> name)>>('riveFileViewModelRuntimeByName')
          .asFunction();
  static final Pointer<Void> Function(
          Pointer<Void> file, Pointer<Void> artboard)
      defaultArtboardViewModelRuntime = nativeLib
          .lookup<
                  NativeFunction<
                      Pointer<Void> Function(
                          Pointer<Void>, Pointer<Void> artboard)>>(
              'riveFileDefaultArtboardViewModelRuntime')
          .asFunction();
  static final DataEnumArray Function(Pointer<Void> file) enums = nativeLib
      .lookup<NativeFunction<DataEnumArray Function(Pointer<Void> file)>>(
          'fileEnums')
      .asFunction();
  static final void Function(DataEnumArray dataArray) deleteDataEnumArray =
      nativeLib
          .lookup<NativeFunction<Void Function(DataEnumArray)>>(
              'deleteDataEnumArray')
          .asFunction();
}

abstract class _NativeArtboard {
  static final void Function(
          Pointer<Void> artboard, Pointer<Void> viewModelInstance)
      setVMIRuntime = nativeLib
          .lookup<
              NativeFunction<
                  Void Function(
                    Pointer<Void>,
                    Pointer<Void>,
                  )>>('artboardSetVMIRuntime')
          .asFunction();
}

abstract class _NativeStateMachine {
  static final void Function(
          Pointer<Void> stateMachine, Pointer<Void> viewModelInstanceRuntime)
      setVMIRuntime = nativeLib
          .lookup<NativeFunction<Void Function(Pointer<Void>, Pointer<Void>)>>(
              'stateMachineSetVMIRuntime')
          .asFunction();
}

abstract class _NativeViewModelRuntime {
  static final int Function(Pointer<Void> viewModel) propertyCount = nativeLib
      .lookup<NativeFunction<Uint64 Function(Pointer<Void>)>>(
          'viewModelRuntimePropertyCount')
      .asFunction();
  static final int Function(Pointer<Void> viewModel) instanceCount = nativeLib
      .lookup<NativeFunction<Uint64 Function(Pointer<Void>)>>(
          'viewModelRuntimeInstanceCount')
      .asFunction();
  static final Pointer<Utf8> Function(Pointer<Void> viewModel) name = nativeLib
      .lookup<NativeFunction<Pointer<Utf8> Function(Pointer<Void>)>>(
          'viewModelRuntimeName')
      .asFunction();
  static final ViewModelPropertyDataArray Function(Pointer<Void> viewModel)
      properties = nativeLib
          .lookup<
              NativeFunction<
                  ViewModelPropertyDataArray Function(
                      Pointer<Void>)>>('viewModelRuntimeProperties')
          .asFunction();
  static final void Function(ViewModelPropertyDataArray dataArray)
      deletePropertyDataArray = nativeLib
          .lookup<NativeFunction<Void Function(ViewModelPropertyDataArray)>>(
              'deleteViewModelPropertyDataArray')
          .asFunction();
  static final Pointer<Void> Function(Pointer<Void> file, int index)
      createFromIndex = nativeLib
          .lookup<
              NativeFunction<
                  Pointer<Void> Function(Pointer<Void>,
                      Uint32 index)>>('createVMIRuntimeFromIndex')
          .asFunction();
  static final Pointer<Void> Function(
          Pointer<Void> viewModel, Pointer<Void> name) createFromName =
      nativeLib
          .lookup<
              NativeFunction<
                  Pointer<Void> Function(Pointer<Void>,
                      Pointer<Void> name)>>('createVMIRuntimeFromName')
          .asFunction();
  static final Pointer<Void> Function(Pointer<Void> viewModel) createDefault =
      nativeLib
          .lookup<NativeFunction<Pointer<Void> Function(Pointer<Void>)>>(
              'createDefaultVMIRuntime')
          .asFunction();
  static final Pointer<Void> Function(Pointer<Void> viewModel) create =
      nativeLib
          .lookup<NativeFunction<Pointer<Void> Function(Pointer<Void>)>>(
              'createVMIRuntime')
          .asFunction();
  static final Pointer<NativeFunction<Void Function(Pointer<Void>)>>
      deleteNative =
      nativeLib.lookup<NativeFunction<Void Function(Pointer<Void>)>>(
          'deleteViewModelRuntime');
  static final void Function(Pointer<Void> smi) delete =
      deleteNative.asFunction();
}

abstract class _NativeVMIRuntime {
  static final Pointer<Utf8> Function(Pointer<Void> viewModel) name = nativeLib
      .lookup<NativeFunction<Pointer<Utf8> Function(Pointer<Void>)>>(
          'vmiRuntimeName')
      .asFunction();
  static final ViewModelPropertyDataArray Function(Pointer<Void> viewModel)
      properties = nativeLib
          .lookup<
              NativeFunction<
                  ViewModelPropertyDataArray Function(
                      Pointer<Void>)>>('vmiRuntimeProperties')
          .asFunction();
  static final Pointer<Void> Function(
          Pointer<Void> viewModel, Pointer<Void> path) getNumberProperty =
      nativeLib
          .lookup<
              NativeFunction<
                  Pointer<Void> Function(Pointer<Void>,
                      Pointer<Void> path)>>('vmiRuntimeGetNumberProperty')
          .asFunction();
  static final Pointer<Void> Function(
          Pointer<Void> viewModel, Pointer<Void> path) getStringProperty =
      nativeLib
          .lookup<
              NativeFunction<
                  Pointer<Void> Function(Pointer<Void>,
                      Pointer<Void> path)>>('vmiRuntimeGetStringProperty')
          .asFunction();
  static final Pointer<Void> Function(
          Pointer<Void> viewModel, Pointer<Void> path) getColorProperty =
      nativeLib
          .lookup<
              NativeFunction<
                  Pointer<Void> Function(Pointer<Void>,
                      Pointer<Void> path)>>('vmiRuntimeGetColorProperty')
          .asFunction();
  static final Pointer<Void> Function(
          Pointer<Void> viewModel, Pointer<Void> path) getBooleanProperty =
      nativeLib
          .lookup<
              NativeFunction<
                  Pointer<Void> Function(Pointer<Void>,
                      Pointer<Void> path)>>('vmiRuntimeGetBooleanProperty')
          .asFunction();
  static final Pointer<Void> Function(
          Pointer<Void> viewModel, Pointer<Void> path) getEnumProperty =
      nativeLib
          .lookup<
              NativeFunction<
                  Pointer<Void> Function(Pointer<Void>,
                      Pointer<Void> path)>>('vmiRuntimeGetEnumProperty')
          .asFunction();
  static final Pointer<Void> Function(
          Pointer<Void> viewModel, Pointer<Void> path) getTriggerProperty =
      nativeLib
          .lookup<
              NativeFunction<
                  Pointer<Void> Function(Pointer<Void>,
                      Pointer<Void> path)>>('vmiRuntimeGetTriggerProperty')
          .asFunction();
  static final Pointer<Void> Function(
          Pointer<Void> viewModel, Pointer<Void> path) getViewModelProperty =
      nativeLib
          .lookup<
              NativeFunction<
                  Pointer<Void> Function(Pointer<Void>,
                      Pointer<Void> path)>>('vmiRuntimeGetViewModelProperty')
          .asFunction();
  static final Pointer<NativeFunction<Void Function(Pointer<Void>)>>
      deleteNative =
      nativeLib.lookup<NativeFunction<Void Function(Pointer<Void>)>>(
          'deleteVMIRuntime');
  static final void Function(Pointer<Void> smi) delete =
      deleteNative.asFunction();
}

abstract class _NativeVMIValueRuntime {
  static final bool Function(Pointer<Void>) hasChanged = nativeLib
      .lookup<NativeFunction<Bool Function(Pointer<Void>)>>(
          'vmiValueRuntimeHasChanged')
      .asFunction();
  static final void Function(Pointer<Void>) clearChanges = nativeLib
      .lookup<NativeFunction<Void Function(Pointer<Void>)>>(
          'vmiValueRuntimeClearChanges')
      .asFunction();
  static final Pointer<NativeFunction<Void Function(Pointer<Void>)>>
      deleteNative =
      nativeLib.lookup<NativeFunction<Void Function(Pointer<Void>)>>(
          'deleteVMIValueRuntime');
  static final void Function(Pointer<Void> file) delete =
      deleteNative.asFunction();
}

abstract class _NativeVMINumberRuntime {
  static final double Function(Pointer<Void>) getValue = nativeLib
      .lookup<NativeFunction<Float Function(Pointer<Void>)>>(
          'getVMINumberRuntimeValue')
      .asFunction();
  static final void Function(Pointer<Void>, double) setValue = nativeLib
      .lookup<NativeFunction<Void Function(Pointer<Void>, Float)>>(
          'setVMINumberRuntimeValue')
      .asFunction();
}

abstract class _NativeVMIStringRuntime {
  static final Pointer<Utf8> Function(Pointer<Void>) getValue = nativeLib
      .lookup<NativeFunction<Pointer<Utf8> Function(Pointer<Void>)>>(
          'getVMIStringRuntimeValue')
      .asFunction();
  static final void Function(Pointer<Void>, Pointer<Utf8>) setValue = nativeLib
      .lookup<NativeFunction<Void Function(Pointer<Void>, Pointer<Utf8>)>>(
          'setVMIStringRuntimeValue')
      .asFunction();
}

abstract class _NativeVMIColorRuntime {
  static final int Function(Pointer<Void>) getValue = nativeLib
      .lookup<NativeFunction<Uint64 Function(Pointer<Void>)>>(
          'getVMIColorRuntimeValue')
      .asFunction();
  static final void Function(Pointer<Void>, int) setValue = nativeLib
      .lookup<NativeFunction<Void Function(Pointer<Void>, Uint64)>>(
          'setVMIColorRuntimeValue')
      .asFunction();
}

abstract class _NativeVMIBooleanRuntime {
  static final bool Function(Pointer<Void>) getValue = nativeLib
      .lookup<NativeFunction<Bool Function(Pointer<Void>)>>(
          'getVMIBooleanRuntimeValue')
      .asFunction();
  static final void Function(Pointer<Void>, bool) setValue = nativeLib
      .lookup<NativeFunction<Void Function(Pointer<Void>, Bool)>>(
          'setVMIBooleanRuntimeValue')
      .asFunction();
}

abstract class _NativeVMIEnumRuntime {
  static final Pointer<Utf8> Function(Pointer<Void>) getValue = nativeLib
      .lookup<NativeFunction<Pointer<Utf8> Function(Pointer<Void>)>>(
          'getVMIEnumRuntimeValue')
      .asFunction();
  static final void Function(Pointer<Void>, Pointer<Utf8>) setValue = nativeLib
      .lookup<NativeFunction<Void Function(Pointer<Void>, Pointer<Utf8>)>>(
          'setVMIEnumRuntimeValue')
      .asFunction();
}

abstract class _NativeVMITriggerRuntime {
  static final void Function(Pointer<Void>) trigger = nativeLib
      .lookup<NativeFunction<Void Function(Pointer<Void>)>>(
          'triggerVMITriggerRuntime')
      .asFunction();
}

final Pointer<Float> _floatQueryBuffer =
    calloc.allocate<Float>(sizeOf<Float>() * 6);

sealed class FFIFileAsset implements FileAssetInterface, RiveFFIReference {
  @override
  Pointer<Void> get pointer => _pointer;

  final Pointer<Void> _pointer;
  final Factory _riveFactory;

  FFIFileAsset(this._pointer, this._riveFactory);

  @override
  int get assetId => _riveFileAssetId(pointer);

  @override
  String get name {
    var stringPointer = _riveFileAssetName(pointer);
    if (stringPointer == nullptr) {
      return '';
    }
    return stringPointer.toDartString();
  }

  @override
  String get fileExtension {
    var stringPointer = _riveFileAssetFileExtension(pointer);
    if (stringPointer == nullptr) {
      return '';
    }
    var result = stringPointer.toDartString();
    freeString(stringPointer);
    return result;
  }

  @override
  String get cdnBaseUrl {
    var stringPointer = _riveFileAssetCdnBaseUrl(pointer);
    if (stringPointer == nullptr) {
      return '';
    }
    return stringPointer.toDartString();
  }

  @override
  String get cdnUuid {
    var stringPointer = _riveFileAssetCdnUuid(pointer);
    if (stringPointer == nullptr) {
      return '';
    }
    var result = stringPointer.toDartString();
    freeString(stringPointer);
    return result;
  }

  @override
  Factory get riveFactory => _riveFactory;
}

class FFIUnknownAsset extends FFIFileAsset implements UnknownAsset {
  FFIUnknownAsset(super.pointer, super.riveFactory);

  @override
  Future<bool> decode(Uint8List bytes) async {
    return false; // nothing to decode
  }
}

class FFIImageAsset extends FFIFileAsset implements ImageAsset {
  FFIImageAsset(super.pointer, super.riveFactory);

  @override
  bool renderImage(RenderImage renderImage) => riveFileAssetSetRenderImage(
        pointer,
        (renderImage as FFIRenderImage).pointer,
      );

  @override
  Future<bool> decode(Uint8List bytes) async {
    final decodedImage = await riveFactory.decodeImage(bytes);
    if (decodedImage == null) {
      return false;
    }
    return renderImage(decodedImage);
  }
}

class FFIFontAsset extends FFIFileAsset implements FontAsset {
  FFIFontAsset(super.pointer, super.riveFactory);

  @override
  bool font(Font font) => riveFileAssetSetFont(
        pointer,
        (font as FontFFI).fontPtr,
      );

  @override
  Future<bool> decode(Uint8List bytes) async {
    final decodedFont = await riveFactory.decodeFont(bytes);
    if (decodedFont == null) {
      return Future.value(false);
    }
    return font(decodedFont);
  }
}

class FFIAudioAsset extends FFIFileAsset implements AudioAsset {
  FFIAudioAsset(super.pointer, super.riveFactory);

  @override
  bool audio(AudioSource audioSource) {
    return riveFileAssetSetAudioSource(
      pointer,
      (audioSource as AudioSourceFFI).nativePtr,
    );
  }

  @override
  Future<bool> decode(Uint8List bytes) async {
    final decodedAudio = await riveFactory.decodeAudio(bytes);
    if (decodedAudio == null) {
      return false;
    }
    return audio(decodedAudio);
  }
}

class FFIRiveFile extends File implements RiveFFIReference, Finalizable {
  final Factory riveFactory;
  static final _finalizer = NativeFinalizer(_deleteRiveFileNative);

  @override
  String toString() {
    return 'FFIRiveFile($_pointer)';
  }

  @override
  Pointer<Void> get pointer => _pointer;

  Pointer<Void> _pointer;

  static final _instances = <int, InternalViewModelInstanceValue?>{};

  @internal
  static void internalRegisterViewModelInstance(
      int ptr, InternalViewModelInstanceValue vmi) {
    _instances[ptr] = vmi;
  }

  @internal
  static void internalUnregisterViewModelInstance(int ptr) {
    _instances[ptr] = null;
  }

  static void _vmNumberCallback(int ptr, double value) {
    InternalViewModelInstanceValue? vmi = _instances[ptr];
    if (vmi is FFIInternalViewModelInstanceNumber) {
      vmi.nativeValue = value;
    }
  }

  static void _vmBooleanCallback(int ptr, bool value) {
    InternalViewModelInstanceValue? vmi = _instances[ptr];
    if (vmi is FFIInternalViewModelInstanceBoolean) {
      vmi.nativeValue = value;
    }
  }

  static void _vmColorCallback(int ptr, int value) {
    InternalViewModelInstanceValue? vmi = _instances[ptr];
    if (vmi is FFIInternalViewModelInstanceColor) {
      vmi.nativeValue = value;
    }
  }

  static void _vmStringCallback(int ptr, Pointer<Utf8> value) {
    InternalViewModelInstanceValue? vmi = _instances[ptr];
    if (vmi is FFIInternalViewModelInstanceString) {
      vmi.nativeValue = value.toDartString();
    }
  }

  static void _vmTriggerCallback(int ptr, int value) {
    InternalViewModelInstanceValue? vmi = _instances[ptr];
    if (vmi is FFIInternalViewModelInstanceTrigger) {
      vmi.nativeValue = value;
    }
  }

  static void _vmEnumCallback(int ptr, int value) {
    InternalViewModelInstanceValue? vmi = _instances[ptr];
    if (vmi is FFIInternalViewModelInstanceEnum) {
      vmi.nativeValue = value;
    }
  }

  FFIRiveFile(this._pointer, this.riveFactory) {
    _finalizer.attach(this, _pointer.cast(), detach: this);
    _initBindingCallbacks(
      Pointer.fromFunction(_vmNumberCallback),
      Pointer.fromFunction(_vmBooleanCallback),
      Pointer.fromFunction(_vmColorCallback),
      Pointer.fromFunction(_vmStringCallback),
      Pointer.fromFunction(_vmTriggerCallback),
      Pointer.fromFunction(_vmEnumCallback),
    );
  }

  @override
  void dispose() {
    if (_pointer == nullptr) {
      return;
    }
    _finalizer.detach(this);
    _deleteRiveFile(_pointer);
    _pointer = nullptr;
  }

  @override
  Artboard? defaultArtboard({bool frameOrigin = true}) {
    var ptr = _riveFileArtboardDefault(pointer, frameOrigin);
    if (ptr == nullptr) {
      return null;
    }
    return FFIRiveArtboard(ptr, riveFactory);
  }

  @override
  Artboard? artboard(String name, {bool frameOrigin = true}) {
    var nativeString = name.toNativeUtf8();
    var ptr = _riveFileArtboardNamed(pointer, nativeString.cast(), frameOrigin);
    malloc.free(nativeString);
    if (ptr == nullptr) {
      return null;
    }
    return FFIRiveArtboard(ptr, riveFactory);
  }

  @override
  Artboard? artboardAt(int index, {bool frameOrigin = true}) {
    var ptr = _riveFileArtboardByIndex(pointer, index, frameOrigin);
    if (ptr == nullptr) {
      return null;
    }
    return FFIRiveArtboard(ptr, riveFactory);
  }

  @override
  InternalDataContext? internalDataContext(
      int viewModelIndex, int instanceIndex) {
    var ptr = _riveDataContext(pointer, viewModelIndex, instanceIndex);
    if (ptr == nullptr) {
      return null;
    }
    return FFIRiveInternalDataContext(ptr);
  }

  @override
  int get viewModelCount => _NativeFile.viewModelCount(pointer);

  @override
  ViewModel? viewModelByIndex(int index) {
    var ptr = _NativeFile.viewModelRuntimeByIndex(pointer, index);
    if (ptr == nullptr) {
      return null;
    }
    return FFIRiveViewModelRuntime(ptr);
  }

  @override
  ViewModel? viewModelByName(String name) {
    var nativeString = name.toNativeUtf8();
    var ptr = _NativeFile.viewModelRuntimeByName(pointer, nativeString.cast());
    malloc.free(nativeString);
    if (ptr == nullptr) {
      return null;
    }
    return FFIRiveViewModelRuntime(ptr);
  }

  @override
  ViewModel? defaultArtboardViewModel(covariant FFIRiveArtboard artboard) {
    var ptr =
        _NativeFile.defaultArtboardViewModelRuntime(pointer, artboard.pointer);
    if (ptr == nullptr) {
      return null;
    }
    return FFIRiveViewModelRuntime(ptr);
  }

  @override
  List<DataEnum> get enums {
    final result = _NativeFile.enums(pointer);
    final list = <DataEnum>[];
    for (int i = 0; i < result.length; i++) {
      final ffiEnum = result.data[i];
      final name = ffiEnum.name.toDartString();
      final enumList = <String>[];
      for (int j = 0; j < ffiEnum.length; j++) {
        enumList.add(ffiEnum.values[j].toDartString());
      }
      list.add(DataEnum(name, enumList));
    }

    _NativeFile.deleteDataEnumArray(result);
    return list;
  }
}

/// A helper function to convert the native property data array into a
/// Dart list of [ViewModelProperty].
List<ViewModelProperty> _generateViewModelPropertyList(
    ViewModelPropertyDataArray result) {
  final list = <ViewModelProperty>[];
  for (int i = 0; i < result.length; i++) {
    final ffiProp = result.data[i];
    final type = DataType.values[ffiProp.type];

    final name = ffiProp.name.toDartString();
    list.add(ViewModelProperty(name, type));
  }

  _NativeViewModelRuntime.deletePropertyDataArray(result);
  return list;
}

class FFIRiveViewModelRuntime
    implements ViewModel, RiveFFIReference, Finalizable {
  @override
  Pointer<Void> get pointer => _pointer;
  Pointer<Void> _pointer;

  static final _finalizer =
      NativeFinalizer(_NativeViewModelRuntime.deleteNative);

  FFIRiveViewModelRuntime(this._pointer) {
    _finalizer.attach(this, _pointer.cast(), detach: this);
  }

  @override
  int get propertyCount => _NativeViewModelRuntime.propertyCount(pointer);

  @override
  int get instanceCount => _NativeViewModelRuntime.instanceCount(pointer);

  @override
  String get name {
    final stringPointer = _NativeViewModelRuntime.name(pointer);
    if (stringPointer == nullptr) {
      return '';
    }
    return stringPointer.toDartString();
  }

  @override
  List<ViewModelProperty> get properties {
    final result = _NativeViewModelRuntime.properties(pointer);
    return _generateViewModelPropertyList(result);
  }

  @override
  ViewModelInstance? createInstanceByIndex(int index) {
    var ptr = _NativeViewModelRuntime.createFromIndex(pointer, index);
    return ptr == nullptr ? null : FFIRiveViewModelInstanceRuntime(ptr);
  }

  @override
  ViewModelInstance? createInstanceByName(String name) {
    var nativeString = name.toNativeUtf8();
    var ptr =
        _NativeViewModelRuntime.createFromName(pointer, nativeString.cast());
    malloc.free(nativeString);
    return ptr == nullptr ? null : FFIRiveViewModelInstanceRuntime(ptr);
  }

  @override
  ViewModelInstance? createDefaultInstance() {
    var ptr = _NativeViewModelRuntime.createDefault(pointer);
    return ptr == nullptr ? null : FFIRiveViewModelInstanceRuntime(ptr);
  }

  @override
  ViewModelInstance? createInstance() {
    var ptr = _NativeViewModelRuntime.create(pointer);
    return ptr == nullptr ? null : FFIRiveViewModelInstanceRuntime(ptr);
  }

  @override
  void dispose() {
    if (_pointer == nullptr) {
      return;
    }
    _NativeViewModelRuntime.delete(_pointer);
    _pointer = nullptr;
    _finalizer.detach(this);
  }
}

class FFIRiveViewModelInstanceRuntime
    with ViewModelInstanceCallbackMixin
    implements ViewModelInstance, RiveFFIReference, Finalizable {
  @override
  Pointer<Void> get pointer => _pointer;
  Pointer<Void> _pointer;

  late FFIRiveViewModelInstanceRuntime _rootViewModelInstance;

  static final _finalizer = NativeFinalizer(_NativeVMIRuntime.deleteNative);

  FFIRiveViewModelInstanceRuntime(
    this._pointer, {
    FFIRiveViewModelInstanceRuntime? rootViewModelInstance,
  }) {
    _finalizer.attach(this, _pointer.cast(), detach: this);
    if (rootViewModelInstance == null) {
      _rootViewModelInstance = this;
    } else {
      _rootViewModelInstance = rootViewModelInstance;
    }
  }

  Pointer<Void> _findPointerByPath(
      Pointer<Void> Function(Pointer<Void>, Pointer<Void>) function,
      String path) {
    var nativeString = path.toNativeUtf8();
    var ptr = function.call(pointer, nativeString.cast());
    malloc.free(nativeString);
    return ptr;
  }

  @override
  String get name {
    final stringPointer = _NativeVMIRuntime.name(pointer);
    if (stringPointer == nullptr) {
      return '';
    }
    return stringPointer.toDartString();
  }

  @override
  List<ViewModelProperty> get properties {
    final result = _NativeVMIRuntime.properties(pointer);
    return _generateViewModelPropertyList(result);
  }

  @override
  ViewModelInstanceNumber? number(String path) {
    var ptr = _findPointerByPath(_NativeVMIRuntime.getNumberProperty, path);
    return ptr == nullptr
        ? null
        : FFIViewModelInstanceNumberRuntime(ptr, _rootViewModelInstance);
  }

  @override
  ViewModelInstanceString? string(String path) {
    var ptr = _findPointerByPath(_NativeVMIRuntime.getStringProperty, path);
    return ptr == nullptr
        ? null
        : FFIViewModelInstanceStringRuntime(ptr, _rootViewModelInstance);
  }

  @override
  ViewModelInstanceBoolean? boolean(String path) {
    var ptr = _findPointerByPath(_NativeVMIRuntime.getBooleanProperty, path);
    return ptr == nullptr
        ? null
        : FFIViewModelInstanceBooleanRuntime(ptr, _rootViewModelInstance);
  }

  @override
  ViewModelInstanceColor? color(String path) {
    var ptr = _findPointerByPath(_NativeVMIRuntime.getColorProperty, path);
    return ptr == nullptr
        ? null
        : FFIViewModelInstanceColorRuntime(ptr, _rootViewModelInstance);
  }

  @override
  ViewModelInstanceEnum? enumerator(String path) {
    var ptr = _findPointerByPath(_NativeVMIRuntime.getEnumProperty, path);
    return ptr == nullptr
        ? null
        : FFIViewModelInstanceEnumRuntime(ptr, _rootViewModelInstance);
  }

  @override
  ViewModelInstanceTrigger? trigger(String path) {
    var ptr = _findPointerByPath(_NativeVMIRuntime.getTriggerProperty, path);
    return ptr == nullptr
        ? null
        : FFIViewModelInstanceTriggerRuntime(ptr, _rootViewModelInstance);
  }

  @override
  ViewModelInstance? viewModel(String path) {
    var ptr = _findPointerByPath(_NativeVMIRuntime.getViewModelProperty, path);
    return ptr == nullptr
        ? null
        : FFIRiveViewModelInstanceRuntime(
            ptr,
            rootViewModelInstance: _rootViewModelInstance,
          );
  }

  @override
  void dispose() {
    clearCallbacks();

    if (_pointer == nullptr) {
      return;
    }
    _NativeVMIRuntime.delete(_pointer);
    _pointer = nullptr;
    _finalizer.detach(this);
    _pointer = nullptr;
  }

  @override
  bool get isDisposed => _pointer == nullptr;
}

abstract class FFIViewModelInstanceValueRuntime
    implements ViewModelInstanceValue, RiveFFIReference, Finalizable {
  static final _finalizer =
      NativeFinalizer(_NativeVMIValueRuntime.deleteNative);

  final ViewModelInstance _rootViewModelInstance;
  @override
  ViewModelInstance get rootViewModelInstance => _rootViewModelInstance;

  @override
  Pointer<Void> get pointer => _pointer;
  Pointer<Void> _pointer;

  FFIViewModelInstanceValueRuntime(this._pointer, this._rootViewModelInstance) {
    _finalizer.attach(this, _pointer.cast(), detach: this);
  }

  @override
  void dispose() {
    if (_pointer == nullptr) {
      return;
    }
    _NativeVMIValueRuntime.delete(_pointer);
    _pointer = nullptr;
    _finalizer.detach(this);
  }
}

abstract class FFIViewModelInstanceObservableValueRuntime<T>
    extends FFIViewModelInstanceValueRuntime
    with ViewModelInstanceObservableValueMixin<T> {
  FFIViewModelInstanceObservableValueRuntime(
    super._pointer,
    super._rootViewModelInstance,
  );

  @override
  bool get hasChanged => _NativeVMIValueRuntime.hasChanged(pointer);

  @override
  void clearChanges() => _NativeVMIValueRuntime.clearChanges(pointer);

  @override
  void dispose() {
    clearListeners();
    super.dispose();
  }
}

class FFIViewModelInstanceNumberRuntime
    extends FFIViewModelInstanceObservableValueRuntime<double>
    implements ViewModelInstanceNumber {
  FFIViewModelInstanceNumberRuntime(
    super._pointer,
    super._rootViewModelInstance,
  );

  @override
  double get nativeValue => _NativeVMINumberRuntime.getValue(pointer);

  @override
  set nativeValue(double value) =>
      _NativeVMINumberRuntime.setValue(pointer, value);
}

class FFIViewModelInstanceStringRuntime
    extends FFIViewModelInstanceObservableValueRuntime<String>
    implements ViewModelInstanceString {
  FFIViewModelInstanceStringRuntime(
    super._pointer,
    super._rootViewModelInstance,
  );

  @override
  String get nativeValue {
    var stringPointer = _NativeVMIStringRuntime.getValue(pointer);
    if (stringPointer == nullptr) {
      return '';
    }
    return stringPointer.toDartString();
  }

  @override
  set nativeValue(String value) {
    var nativeString = value.toNativeUtf8();
    _NativeVMIStringRuntime.setValue(pointer, nativeString.cast());
    malloc.free(nativeString);
  }
}

class FFIViewModelInstanceBooleanRuntime
    extends FFIViewModelInstanceObservableValueRuntime<bool>
    implements ViewModelInstanceBoolean {
  FFIViewModelInstanceBooleanRuntime(
    super._pointer,
    super._rootViewModelInstance,
  );

  @override
  bool get nativeValue => _NativeVMIBooleanRuntime.getValue(pointer);

  @override
  set nativeValue(bool value) =>
      _NativeVMIBooleanRuntime.setValue(pointer, value);
}

class FFIViewModelInstanceColorRuntime
    extends FFIViewModelInstanceObservableValueRuntime<Color>
    implements ViewModelInstanceColor {
  FFIViewModelInstanceColorRuntime(
    super._pointer,
    super._rootViewModelInstance,
  );

  @override
  Color get nativeValue {
    var color = _NativeVMIColorRuntime.getValue(pointer);
    return Color(color);
  }

  @override
  set nativeValue(Color value) {
    // ignore: deprecated_member_use
    _NativeVMIColorRuntime.setValue(pointer, value.value);
  }
}

class FFIViewModelInstanceEnumRuntime
    extends FFIViewModelInstanceObservableValueRuntime<String>
    implements ViewModelInstanceEnum {
  FFIViewModelInstanceEnumRuntime(
    super._pointer,
    super._rootViewModelInstance,
  );

  @override
  String get nativeValue {
    var stringPointer = _NativeVMIEnumRuntime.getValue(pointer);
    if (stringPointer == nullptr) {
      return '';
    }
    final result = stringPointer.toDartString();
    freeString(stringPointer);
    return result;
  }

  @override
  set nativeValue(String value) {
    var nativeString = value.toNativeUtf8();
    _NativeVMIEnumRuntime.setValue(pointer, nativeString.cast());
    malloc.free(nativeString);
  }
}

class FFIViewModelInstanceTriggerRuntime
    extends FFIViewModelInstanceObservableValueRuntime<bool>
    implements ViewModelInstanceTrigger {
  FFIViewModelInstanceTriggerRuntime(
    super._pointer,
    super._rootViewModelInstance,
  );

  @override
  void trigger() {
    _NativeVMITriggerRuntime.trigger(pointer);
  }

  @override
  bool get nativeValue {
    return false;
  }

  @override
  set nativeValue(bool value) {
    if (value) {
      trigger();
    }
  }
}

class FFIStateMachine extends StateMachine
    with EventListenerMixin
    implements RiveFFIReference, Finalizable {
  @override
  Pointer<Void> get pointer => _pointer;
  Pointer<Void> _pointer;
  ViewModelInstance? _boundRuntimeViewModelInstance;

  static final _finalizer = NativeFinalizer(_deleteStateMachineInstanceNative);

  FFIStateMachine(this._pointer) {
    _finalizer.attach(this, _pointer.cast(), detach: this);
  }

  @override
  bool advance(double elapsedSeconds, bool newFrame) =>
      _stateMachineInstanceAdvance(pointer, elapsedSeconds, newFrame);

  @override
  bool advanceAndApply(double elapsedSeconds) {
    _handleEvents();
    final result =
        _stateMachineInstanceAdvanceAndApply(pointer, elapsedSeconds);
    _boundRuntimeViewModelInstance?.handleCallbacks();
    return result;
  }

  @override
  void dispose() {
    removeAllEventListeners();
    if (_pointer == nullptr) {
      return;
    }
    _deleteStateMachineInstance(_pointer);
    _pointer = nullptr;
    _finalizer.detach(this);
  }

  @override
  CallbackHandler onInputChanged(void Function(int index) callback) {
    final nativeCallback =
        NativeCallable<Void Function(Pointer<Void>, Uint64)>.isolateLocal(
      (Pointer<Void> stateMachineInput, int index) {
        return callback(index);
      },
    );
    _setStateMachineInputChangedCallback(
        pointer, nativeCallback.nativeFunction);

    return ClosureCallbackHandler(() {
      _setStateMachineInputChangedCallback(
        pointer,
        nullptr,
      );
      nativeCallback.close();
    });
  }

  @override
  CallbackHandler onDataBindChanged(void Function() callback) {
    final nativeCallback = NativeCallable<Void Function()>.isolateLocal(
      callback,
    );
    _setStateMachineDataBindChangedCallback(
        pointer, nativeCallback.nativeFunction);

    return ClosureCallbackHandler(() {
      nativeCallback.close();
    });
  }

  Pointer<Void> _inputWrapper(
    _StateMachineInputNative nativeFunction,
    String name, {
    String? path,
  }) {
    final nativeName = name.toNativeUtf8();
    final nativePath = path?.toNativeUtf8() ?? nullptr;
    final ptr = nativeFunction(pointer, nativeName.cast(), nativePath.cast());
    malloc.free(nativeName);
    if (nativePath != nullptr) {
      malloc.free(nativePath);
    }
    return ptr;
  }

  @override
  BooleanInput? boolean(String name, {String? path}) {
    final ptr = _inputWrapper(_stateMachineInstanceBoolean, name, path: path);
    return ptr == nullptr ? null : FFIBooleanInput(ptr);
  }

  @override
  NumberInput? number(String name, {String? path}) {
    final ptr = _inputWrapper(_stateMachineInstanceNumber, name, path: path);
    return ptr == nullptr ? null : FFINumberInput(ptr);
  }

  @override
  TriggerInput? trigger(String name, {String? path}) {
    final ptr = _inputWrapper(_stateMachineInstanceTrigger, name, path: path);
    return ptr == nullptr ? null : FFITriggerInput(ptr);
  }

  @override
  Input? inputAt(int index) {
    var inputPointer = _stateMachineInput(pointer, index);
    if (inputPointer == nullptr) {
      return null;
    }
    switch (_stateMachineInputType(inputPointer)) {
      case 56:
        return FFINumberInput(inputPointer);
      case 58:
        return FFITriggerInput(inputPointer);
      case 59:
        return FFIBooleanInput(inputPointer);
      default:
        return null;
    }
  }

  @override
  bool get isDone => _stateMachineInstanceDone(pointer);

  @override
  bool hitTest(Vec2D position) =>
      _stateMachineInstanceHitTest(pointer, position.x, position.y);

  @override
  HitResult pointerDown(Vec2D position) {
    var result =
        _stateMachineInstancePointerDown(pointer, position.x, position.y);
    return HitResult.values[result];
  }

  @override
  HitResult pointerExit(Vec2D position) {
    var result =
        _stateMachineInstancePointerExit(pointer, position.x, position.y);
    return HitResult.values[result];
  }

  @override
  HitResult pointerMove(Vec2D position) {
    var result =
        _stateMachineInstancePointerMove(pointer, position.x, position.y);
    return HitResult.values[result];
  }

  @override
  HitResult pointerUp(Vec2D position) {
    var result =
        _stateMachineInstancePointerUp(pointer, position.x, position.y);
    return HitResult.values[result];
  }

  @override
  void internalBindViewModelInstance(InternalViewModelInstance instance) {
    _stateMachineDataContextFromInstance(
        pointer, (instance as FFIRiveInternalViewModelInstance).pointer);
  }

  @override
  void bindViewModelInstance(
      covariant FFIRiveViewModelInstanceRuntime viewModelInstance) {
    _boundRuntimeViewModelInstance = viewModelInstance;
    _NativeStateMachine.setVMIRuntime(pointer, viewModelInstance.pointer);
  }

  @override
  void internalDataContext(InternalDataContext dataContext) {
    _stateMachineDataContext(
        pointer, (dataContext as FFIRiveInternalDataContext).pointer);
  }

  void _handleEvents() {
    final listeners = eventListeners.toList();
    // Only fetch reported events if a listener is present.
    if (listeners.isNotEmpty) {
      final events = reportedEvents();
      for (var listener in listeners) {
        events.forEach(listener);
      }
    }
  }

  @override
  List<Event> reportedEvents() {
    final count = _stateMachineGetReportedEventCount(pointer);
    List<Event> events = [];
    for (var index = 0; index < count; index++) {
      final eventReport = _stateMachineReportedEventAt(pointer, index);
      final eventType = EventType.from[eventReport.type];
      Event? event = switch (eventType) {
        null => null,
        EventType.general => FFIGeneralEvent(eventReport),
        EventType.openURL => FFIOpenURLEvent(eventReport),
      };
      if (event != null) {
        events.add(event);
      }
    }
    return events;
  }
}

sealed class FFIEvent
    with EventPropertyMixin
    implements EventInterface, RiveFFIReference, Finalizable {
  static final _finalizer = NativeFinalizer(_deleteEventNative);

  final ReportedEventStruct _native;
  FFIEvent._(this._native) {
    _finalizer.attach(this, pointer.cast(), detach: this);
  }

  @override
  void dispose() {
    if (pointer == nullptr) {
      return;
    }
    _deleteEvent(pointer);
    _native.event = nullptr;
    _finalizer.detach(this);
  }

  @override
  Pointer<Void> get pointer => _native.event;

  Map<String, CustomProperty>? _cachedProperties;

  @override
  Map<String, CustomProperty> get properties {
    if (_cachedProperties == null) {
      _populateProperties();
    }
    return _cachedProperties!;
  }

  void _populateProperties() {
    _cachedProperties = {};
    final count = _getEventCustomPropertyCount(pointer);
    for (var index = 0; index < count; index++) {
      final propertyStruct = _getEventCustomProperty(pointer, index);
      final propertyType = CustomPropertyType.from[propertyStruct.type];
      CustomProperty? property = switch (propertyType) {
        null => null,
        CustomPropertyType.number => FFICustomNumberProperty(propertyStruct),
        CustomPropertyType.boolean => FFICustomBooleanProperty(propertyStruct),
        CustomPropertyType.string => FFICustomStringProperty(propertyStruct),
      };

      if (property != null) {
        _cachedProperties![property.name] = property;
      }
    }
  }

  @override
  String get name {
    final stringPointer = _getEventName(pointer);
    if (stringPointer == nullptr) {
      return '';
    }
    return stringPointer.toDartString();
  }

  @override
  double get secondsDelay => _native.secondsDelay;

  @override
  EventType get type => EventType.from[_native.type] ?? EventType.general;
}

class FFIGeneralEvent extends FFIEvent implements GeneralEvent {
  FFIGeneralEvent(super._native) : super._();

  @override
  String toString() {
    return 'Event{type: $type, name: $name, properties: $properties}';
  }
}

class FFIOpenURLEvent extends FFIEvent implements OpenUrlEvent {
  FFIOpenURLEvent(super._native) : super._();

  @override
  OpenUrlTarget get target {
    final targetInt = _getOpenUrlEventTarget(pointer);
    final value = OpenUrlTarget.from[targetInt];
    return value ?? OpenUrlTarget.blank;
  }

  @override
  String get url {
    final stringPointer = _getOpenUrlEventUrl(pointer);
    if (stringPointer == nullptr) {
      return '';
    }
    return stringPointer.toDartString();
  }

  @override
  String toString() {
    return 'Event{type: $type, name: $name, url: $url, target: $target, properties: $properties}';
  }
}

sealed class FFICustomProperty<T>
    implements CustomPropertyInterface<T>, RiveFFIReference, Finalizable {
  static final _finalizer = NativeFinalizer(_deleteCustomPropertyNative);

  final CustomPropertyStruct _native;
  FFICustomProperty(this._native) {
    _finalizer.attach(this, pointer.cast(), detach: this);
  }

  @override
  void dispose() {
    if (pointer == nullptr) {
      return;
    }
    _deleteCustomProperty(pointer);
    _native.property = nullptr;
    _finalizer.detach(this);
  }

  @override
  Pointer<Void> get pointer => _native.property;

  @override
  String get name => _native.name.toDartString();

  @override
  CustomPropertyType get type => CustomPropertyType.from[_native.type]!;

  @override
  String toString() {
    return 'CustomProperty{type: $type, name: $name, value: $value}';
  }
}

class FFICustomNumberProperty extends FFICustomProperty<double>
    implements CustomNumberProperty {
  FFICustomNumberProperty(super._native);

  @override
  double get value => _getCustomPropertyNumber(pointer);
}

class FFICustomBooleanProperty extends FFICustomProperty<bool>
    implements CustomBooleanProperty {
  FFICustomBooleanProperty(super._native);

  @override
  bool get value => _getCustomPropertyBoolean(pointer);
}

class FFICustomStringProperty extends FFICustomProperty<String>
    implements CustomStringProperty {
  FFICustomStringProperty(super._native);

  @override
  String get value {
    final stringPointer = _getCustomPropertyString(pointer);
    if (stringPointer == nullptr) {
      return '';
    }
    return stringPointer.toDartString();
  }
}

abstract class FFIInput extends Input implements RiveFFIReference, Finalizable {
  static final _finalizer = NativeFinalizer(_deleteInputNative);

  @override
  Pointer<Void> pointer;

  FFIInput(this.pointer) {
    _finalizer.attach(this, pointer.cast(), detach: this);
  }

  @override
  String get name {
    var stringPointer = _stateMachineInputName(pointer);
    if (stringPointer == nullptr) {
      return '';
    }
    return stringPointer.toDartString();
  }

  @override
  void dispose() {
    if (pointer == nullptr) {
      return;
    }
    _deleteInput(pointer);
    pointer = nullptr;
    _finalizer.detach(this);
  }
}

class FFIBooleanInput extends FFIInput implements BooleanInput {
  FFIBooleanInput(super.pointer);

  @override
  bool get value => _getBooleanValue(pointer);

  @override
  set value(bool value) => _setBooleanValue(pointer, value);
}

class FFINumberInput extends FFIInput implements NumberInput {
  FFINumberInput(super.pointer);

  @override
  double get value => _getNumberValue(pointer);

  @override
  set value(double value) => _setNumberValue(pointer, value);
}

class FFITriggerInput extends FFIInput implements TriggerInput {
  FFITriggerInput(super.pointer);

  @override
  void fire() => _fireTrigger(pointer);
}

class FFIRiveArtboard extends Artboard
    implements RiveFFIReference, Finalizable {
  @override
  final Factory riveFactory;
  static final _finalizer = NativeFinalizer(_deleteArtboardInstanceNative);

  @override
  Pointer<Void> get pointer => _pointer;
  Pointer<Void> _pointer;

  FFIRiveArtboard(this._pointer, this.riveFactory) {
    _finalizer.attach(this, _pointer.cast(), detach: this);
  }

  @override
  void dispose() {
    if (_pointer == nullptr) {
      return;
    }
    _deleteArtboardInstance(_pointer);
    _pointer = nullptr;
    _finalizer.detach(this);
  }

  @override
  void draw(Renderer renderer) {
    assert(riveFactory.isValidRenderer(renderer));
    _artboardDraw(pointer, (renderer as RiveFFIReference).pointer);
  }

  @override
  StateMachine? defaultStateMachine() {
    var smiPointer = _riveArtboardStateMachineDefault(pointer);
    if (smiPointer == nullptr) {
      return null;
    }
    return FFIStateMachine(smiPointer);
  }

  @override
  StateMachine? stateMachine(String name) {
    var nativeString = name.toNativeUtf8();
    var smiPointer =
        _riveArtboardStateMachineNamed(pointer, nativeString.cast());
    malloc.free(nativeString);
    if (smiPointer == nullptr) {
      return null;
    }
    return FFIStateMachine(smiPointer);
  }

  @override
  StateMachine? stateMachineAt(int index) =>
      FFIStateMachine(_artboardStateMachineAt(pointer, index));

  @override
  AABB get bounds {
    _artboardBounds(pointer, _floatQueryBuffer);
    return AABB.fromValues(_floatQueryBuffer[0], _floatQueryBuffer[1],
        _floatQueryBuffer[2], _floatQueryBuffer[3]);
  }

  @override
  AABB get layoutBounds {
    _artboardLayoutBounds(pointer, _floatQueryBuffer);
    return AABB.fromValues(_floatQueryBuffer[0], _floatQueryBuffer[1],
        _floatQueryBuffer[2], _floatQueryBuffer[3]);
  }

  @override
  void addToRenderPath(RenderPath renderPath, Mat2D transform) =>
      _artboardAddToRenderPath(
        pointer,
        (renderPath as RiveFFIReference).pointer,
        transform[0],
        transform[1],
        transform[2],
        transform[3],
        transform[4],
        transform[5],
      );
  @override
  int animationCount() => _artboardAnimationCount(pointer);

  @override
  int stateMachineCount() => _artboardStateMachineCount(pointer);

  @override
  Animation animationAt(int index) {
    return FFIAnimation(_artboardAnimationAt(pointer, index));
  }

  @override
  Animation? animationNamed(String name) {
    var nativeString = name.toNativeUtf8();
    var ptr = _artboardAnimationNamed(pointer, nativeString.cast());
    malloc.free(nativeString);

    if (ptr == nullptr) {
      return null;
    }

    return FFIAnimation(ptr);
  }

  @override
  bool get frameOrigin => _artboardGetFrameOrigin(pointer);

  @override
  set frameOrigin(bool value) => _artboardSetFrameOrigin(pointer, value);

  @override
  Component? component(String name) {
    var nativeString = name.toNativeUtf8();
    var ptr = _artboardComponentNamed(pointer, nativeString.cast());
    malloc.free(nativeString);

    if (ptr == nullptr) {
      return null;
    }

    return FFIComponent(ptr);
  }

  @override
  String getText(String runName, {String? path}) {
    final nativeRunName = runName.toNativeUtf8();
    final nativePath = path?.toNativeUtf8() ?? nullptr;
    final stringPointer =
        _artboardGetText(pointer, nativeRunName.cast(), nativePath.cast());
    malloc.free(nativeRunName);
    if (nativePath != nullptr) {
      malloc.free(nativePath);
    }
    return stringPointer == nullptr ? '' : stringPointer.toDartString();
  }

  @override
  bool setText(String runName, String value, {String? path}) {
    final nativeRunName = runName.toNativeUtf8();
    final nativeValue = value.toNativeUtf8();
    final nativePath = path?.toNativeUtf8() ?? nullptr;

    final result = _artboardSetText(
        pointer, nativeRunName.cast(), nativeValue.cast(), nativePath.cast());
    malloc.free(nativeRunName);
    malloc.free(nativeValue);
    if (nativePath != nullptr) {
      malloc.free(nativePath);
    }
    return result;
  }

  @override
  Mat2D get renderTransform {
    _artboardGetRenderTransform(pointer, _floatQueryBuffer);
    return Mat2D()
      ..values[0] = _floatQueryBuffer[0]
      ..values[1] = _floatQueryBuffer[1]
      ..values[2] = _floatQueryBuffer[2]
      ..values[3] = _floatQueryBuffer[3]
      ..values[4] = _floatQueryBuffer[4]
      ..values[5] = _floatQueryBuffer[5];
  }

  @override
  set renderTransform(Mat2D value) => _artboardSetRenderTransform(
        pointer,
        value[0],
        value[1],
        value[2],
        value[3],
        value[4],
        value[5],
      );

  // Flags AdvanceFlags.advanceNested and AdvanceFlags.newFrame set to true
  // by default
  @override
  bool advance(double seconds, {int flags = 9}) =>
      _artboardAdvance(pointer, seconds, flags);

  @override
  double get opacity => _riveArtboardGetOpacity(pointer);

  @override
  set opacity(double value) => _riveArtboardSetOpacity(pointer, value);

  @override
  double get width => _riveArtboardGetWidth(pointer);

  @override
  set width(double value) => _riveArtboardSetWidth(pointer, value);

  @override
  double get height => _riveArtboardGetHeight(pointer);

  @override
  set height(double value) => _riveArtboardSetHeight(pointer, value);

  @override
  double get heightOriginal => _riveArtboardGetOriginalHeight(pointer);

  @override
  double get widthOriginal => _riveArtboardGetOriginalWidth(pointer);

  @override
  void resetArtboardSize() {
    width = heightOriginal;
    height = widthOriginal;
  }

  @override
  CallbackHandler onEvent(void Function(int) callback) {
    final nativeCallback =
        NativeCallable<Void Function(Pointer<Void>, Uint32)>.isolateLocal(
            (Pointer<Void> artboardPtr, int id) => callback(id));
    _setArtboardEventCallback(pointer, nativeCallback.nativeFunction);
    return ClosureCallbackHandler(() {
      _setArtboardEventCallback(
        pointer,
        nullptr,
      );
      nativeCallback.close();
    });
  }

  @override
  CallbackHandler onLayoutChanged(void Function() callback) {
    final nativeCallback =
        NativeCallable<Void Function(Pointer<Void>)>.isolateLocal(
            (Pointer<Void> artboardPtr) => callback());
    _setArtboardLayoutChangedCallback(pointer, nativeCallback.nativeFunction);
    return ClosureCallbackHandler(() {
      _setArtboardLayoutChangedCallback(
        pointer,
        nullptr,
      );
      nativeCallback.close();
    });
  }

  @override
  CallbackHandler onLayoutDirty(void Function() callback) {
    final nativeCallback =
        NativeCallable<Void Function()>.isolateLocal(callback);
    _setArtboardLayoutDirtyCallback(pointer, nativeCallback.nativeFunction);
    return ClosureCallbackHandler(() {
      _setArtboardLayoutDirtyCallback(
        pointer,
        nullptr,
      );
      nativeCallback.close();
    });
  }

  @override
  dynamic takeLayoutNode() => _artboardTakeLayoutNode(pointer);

  @override
  void syncStyleChanges() => _artboardSyncStyleChanges(pointer);

  @override
  void widthOverride(double width, int widthUnitValue, bool isRow) =>
      _artboardWidthOverride(pointer, width, widthUnitValue, isRow);

  @override
  void heightOverride(double height, int heightUnitValue, bool isRow) =>
      _artboardHeightOverride(pointer, height, heightUnitValue, isRow);

  @override
  void widthIntrinsicallySizeOverride(bool intrinsic) =>
      _artboardWidthIntrinsicallySizeOverride(pointer, intrinsic);

  @override
  void heightIntrinsicallySizeOverride(bool intrinsic) =>
      _artboardHeightIntrinsicallySizeOverride(pointer, intrinsic);

  @override
  void updateLayoutBounds(bool animate) =>
      _updateLayoutBounds(pointer, animate);

  @override
  void cascadeLayoutStyle(int direction) =>
      _cascadeLayoutStyle(pointer, direction);

  @override
  void internalBindViewModelInstance(
      InternalViewModelInstance instance, InternalDataContext dataContext) {
    _artboardDataContextFromInstance(
        pointer,
        (instance as FFIRiveInternalViewModelInstance).pointer,
        (dataContext as FFIRiveInternalDataContext).pointer);
  }

  @override
  void bindViewModelInstance(
      covariant FFIRiveViewModelInstanceRuntime viewModelInstance) {
    _NativeArtboard.setVMIRuntime(pointer, viewModelInstance.pointer);
  }

  @override
  void internalSetDataContext(InternalDataContext dataContext) {
    _artboardInternalDataContext(
        pointer, (dataContext as FFIRiveInternalDataContext).pointer);
  }

  @override
  InternalDataContext? get internalGetDataContext {
    var ptr = _artboardDataContext(pointer);
    if (ptr == nullptr) {
      return null;
    }
    return FFIRiveInternalDataContext(ptr);
  }

  @override
  void internalClearDataContext() {
    _artboardClearDataContext(pointer);
  }

  @override
  List<InternalDataBind> internalPopulateDataBinds() {
    _artboardCollectDataBinds(pointer);
    final totalDataBinds = _artboardTotalDataBinds(pointer);
    final dataBinds = <InternalDataBind>[];
    int index = 0;
    while (index < totalDataBinds) {
      final dataBindPointer = _artboardDataBindAt(pointer, index);
      dataBinds.add(FFIRiveInternalDataBind(dataBindPointer));
      index += 1;
    }
    return dataBinds;
  }

  @override
  bool updatePass() {
    return _riveArtboardUpdatePass(pointer);
  }

  @override
  bool hasComponentDirt() {
    return _riveArtboardHasComponentDirt(pointer);
  }
}

class FFIRiveInternalViewModelInstance extends InternalViewModelInstance
    implements Finalizable {
  static final _finalizer = NativeFinalizer(_deleteViewModelInstanceNative);

  Pointer<Void> get pointer => _pointer;
  Pointer<Void> _pointer;
  FFIRiveInternalViewModelInstance(this._pointer);

  @override
  InternalViewModelInstanceViewModel propertyViewModel(int index) {
    final propertyPointer = _viewModelInstancePropertyValue(pointer, index);
    return FFIRiveInternalViewModelInstanceViewModel(propertyPointer);
  }

  @override
  InternalViewModelInstanceNumber propertyNumber(int index) {
    final propertyPointer = _viewModelInstancePropertyValue(pointer, index);
    return FFIInternalViewModelInstanceNumber(propertyPointer);
  }

  @override
  InternalViewModelInstanceTrigger propertyTrigger(int index) {
    final propertyPointer = _viewModelInstancePropertyValue(pointer, index);
    return FFIInternalViewModelInstanceTrigger(propertyPointer);
  }

  @override
  InternalViewModelInstanceBoolean propertyBoolean(int index) {
    final propertyPointer = _viewModelInstancePropertyValue(pointer, index);
    return FFIInternalViewModelInstanceBoolean(propertyPointer);
  }

  @override
  InternalViewModelInstanceColor propertyColor(int index) {
    final propertyPointer = _viewModelInstancePropertyValue(pointer, index);
    return FFIInternalViewModelInstanceColor(propertyPointer);
  }

  @override
  InternalViewModelInstanceString propertyString(int index) {
    final propertyPointer = _viewModelInstancePropertyValue(pointer, index);
    return FFIInternalViewModelInstanceString(propertyPointer);
  }

  @override
  InternalViewModelInstanceEnum propertyEnum(int index) {
    final propertyPointer = _viewModelInstancePropertyValue(pointer, index);
    return FFIInternalViewModelInstanceEnum(propertyPointer);
  }

  @override
  InternalViewModelInstanceList propertyList(int index) {
    final propertyPointer = _viewModelInstancePropertyValue(pointer, index);
    return FFIRiveInternalViewModelInstanceList(propertyPointer, index);
  }

  @override
  void dispose() {
    if (_pointer == nullptr) {
      return;
    }
    _deleteViewModelInstance(_pointer);
    _pointer = nullptr;
    _finalizer.detach(this);
  }
}

class FFIRiveInternalViewModelInstanceViewModel
    extends InternalViewModelInstanceViewModel
    implements RiveFFIReference, Finalizable {
  static final _finalizer =
      NativeFinalizer(_deleteViewModelInstanceValueNative);

  @override
  Pointer<Void> get pointer => _pointer;
  Pointer<Void> _pointer;

  FFIRiveInternalViewModelInstanceViewModel(this._pointer) {
    _finalizer.attach(this, _pointer.cast(), detach: this);
  }

  @override
  void dispose() {
    if (_pointer == nullptr) {
      return;
    }
    _deleteViewModelInstanceValue(_pointer);
    _pointer = nullptr;
    _finalizer.detach(this);
  }

  @override
  InternalViewModelInstance get referenceViewModelInstance {
    final viewModelInstancePointer =
        _viewModelInstanceReferenceViewModel(pointer);
    return FFIRiveInternalViewModelInstance(viewModelInstancePointer);
  }
}

class FFIInternalViewModelInstanceNumber extends InternalViewModelInstanceNumber
    implements RiveFFIReference, Finalizable {
  static final _finalizer =
      NativeFinalizer(_deleteViewModelInstanceValueNative);

  @override
  Pointer<Void> get pointer => _pointer;
  Pointer<Void> _pointer;
  void Function(double value)? _callback;
  FFIInternalViewModelInstanceNumber(this._pointer) {
    _finalizer.attach(this, _pointer.cast(), detach: this);
    Pointer<Void> instancePointer =
        _setViewModelInstanceNumberCallback(pointer);
    instancePointerAddress = instancePointer.address;
    if (instancePointer != nullptr) {
      FFIRiveFile.internalRegisterViewModelInstance(
          instancePointerAddress, this);
    }
  }
  @override
  void onChanged(void Function(double value) callback) {
    _callback = callback;
  }

  @override
  set value(double val) {
    if (suppressCallback) {
      return;
    }
    suppressCallback = true;
    _setViewModelInstanceNumberValue(pointer, val);
    suppressCallback = false;
  }

  @override
  set nativeValue(double val) {
    if (suppressCallback) {
      return;
    }
    suppressCallback = true;
    if (_callback != null) {
      _callback!(val);
    }
    suppressCallback = false;
  }

  @override
  void dispose() {
    if (_pointer == nullptr) {
      return;
    }
    FFIRiveFile.internalUnregisterViewModelInstance(instancePointerAddress);
    _deleteViewModelInstanceValue(_pointer);
    _pointer = nullptr;
    _finalizer.detach(this);
  }
}

class FFIInternalViewModelInstanceColor extends InternalViewModelInstanceColor
    implements RiveFFIReference, Finalizable {
  static final _finalizer =
      NativeFinalizer(_deleteViewModelInstanceValueNative);

  @override
  Pointer<Void> get pointer => _pointer;
  Pointer<Void> _pointer;
  void Function(int value)? _callback;
  FFIInternalViewModelInstanceColor(this._pointer) {
    _finalizer.attach(this, _pointer.cast(), detach: this);

    Pointer<Void> instancePointer = _setViewModelInstanceColorCallback(pointer);
    instancePointerAddress = instancePointer.address;
    if (instancePointer != nullptr) {
      FFIRiveFile.internalRegisterViewModelInstance(
          instancePointerAddress, this);
    }
  }
  @override
  void onChanged(void Function(int value) callback) {
    _callback = callback;
  }

  @override
  set value(int val) {
    if (suppressCallback) {
      return;
    }
    suppressCallback = true;
    _setViewModelInstanceColorValue(pointer, val);
    suppressCallback = false;
  }

  @override
  set nativeValue(int val) {
    if (suppressCallback) {
      return;
    }
    suppressCallback = true;
    if (_callback != null) {
      _callback!(val);
    }
    suppressCallback = false;
  }

  @override
  void dispose() {
    if (_pointer == nullptr) {
      return;
    }
    FFIRiveFile.internalUnregisterViewModelInstance(instancePointerAddress);
    _deleteViewModelInstanceValue(_pointer);
    _pointer = nullptr;
    _finalizer.detach(this);
  }
}

class FFIInternalViewModelInstanceString extends InternalViewModelInstanceString
    implements RiveFFIReference, Finalizable {
  static final _finalizer =
      NativeFinalizer(_deleteViewModelInstanceValueNative);

  @override
  Pointer<Void> get pointer => _pointer;
  Pointer<Void> _pointer;
  void Function(String value)? _callback;
  FFIInternalViewModelInstanceString(this._pointer) {
    _finalizer.attach(this, _pointer.cast(), detach: this);

    Pointer<Void> instancePointer =
        _setViewModelInstanceStringCallback(pointer);
    instancePointerAddress = instancePointer.address;
    if (instancePointer != nullptr) {
      FFIRiveFile.internalRegisterViewModelInstance(
          instancePointerAddress, this);
    }
  }
  @override
  void onChanged(void Function(String value) callback) {
    _callback = callback;
  }

  @override
  set value(String val) {
    if (suppressCallback) {
      return;
    }
    suppressCallback = true;
    var nativeString = val.toNativeUtf8();
    _setViewModelInstanceStringValue(pointer, nativeString.cast());
    malloc.free(nativeString);
    suppressCallback = false;
  }

  @override
  set nativeValue(String val) {
    if (suppressCallback) {
      return;
    }
    suppressCallback = true;
    if (_callback != null) {
      _callback!(val);
    }
    suppressCallback = false;
  }

  @override
  void dispose() {
    if (_pointer == nullptr) {
      return;
    }
    FFIRiveFile.internalUnregisterViewModelInstance(instancePointerAddress);
    _deleteViewModelInstanceValue(_pointer);
    _pointer = nullptr;
    _finalizer.detach(this);
  }
}

class FFIInternalViewModelInstanceBoolean
    extends InternalViewModelInstanceBoolean
    implements RiveFFIReference, Finalizable {
  static final _finalizer =
      NativeFinalizer(_deleteViewModelInstanceValueNative);

  @override
  Pointer<Void> get pointer => _pointer;
  Pointer<Void> _pointer;
  void Function(bool value)? _callback;
  FFIInternalViewModelInstanceBoolean(this._pointer) {
    _finalizer.attach(this, _pointer.cast(), detach: this);

    Pointer<Void> instancePointer =
        _setViewModelInstanceBooleanCallback(pointer);
    instancePointerAddress = instancePointer.address;
    if (instancePointer != nullptr) {
      FFIRiveFile.internalRegisterViewModelInstance(
          instancePointerAddress, this);
    }
  }
  @override
  void onChanged(void Function(bool value) callback) {
    _callback = callback;
  }

  @override
  set value(bool val) {
    if (suppressCallback) {
      return;
    }
    suppressCallback = true;
    _setViewModelInstanceBooleanValue(pointer, val);
    suppressCallback = false;
  }

  @override
  set nativeValue(bool val) {
    if (suppressCallback) {
      return;
    }
    suppressCallback = true;
    if (_callback != null) {
      _callback!(val);
    }
    suppressCallback = false;
  }

  @override
  void dispose() {
    if (_pointer == nullptr) {
      return;
    }
    FFIRiveFile.internalUnregisterViewModelInstance(instancePointerAddress);
    _deleteViewModelInstanceValue(_pointer);
    _pointer = nullptr;
    _finalizer.detach(this);
  }
}

class FFIInternalViewModelInstanceTrigger
    extends InternalViewModelInstanceTrigger
    implements RiveFFIReference, Finalizable {
  static final _finalizer =
      NativeFinalizer(_deleteViewModelInstanceValueNative);

  @override
  Pointer<Void> get pointer => _pointer;
  Pointer<Void> _pointer;
  void Function(int value)? _callback;
  FFIInternalViewModelInstanceTrigger(this._pointer) {
    _finalizer.attach(this, _pointer.cast(), detach: this);

    Pointer<Void> instancePointer =
        _setViewModelInstanceTriggerCallback(pointer);
    instancePointerAddress = instancePointer.address;
    if (instancePointer != nullptr) {
      FFIRiveFile.internalRegisterViewModelInstance(
          instancePointerAddress, this);
    }
  }
  @override
  void onChanged(void Function(int value) callback) {
    _callback = callback;
  }

  @override
  set value(int val) {
    if (suppressCallback) {
      return;
    }
    suppressCallback = true;
    _setViewModelInstanceTriggerValue(pointer, val);
    suppressCallback = false;
  }

  @override
  set nativeValue(int val) {
    if (suppressCallback) {
      return;
    }
    suppressCallback = true;
    if (_callback != null) {
      _callback!(val);
    }
    suppressCallback = false;
  }

  @override
  void dispose() {
    if (_pointer == nullptr) {
      return;
    }
    FFIRiveFile.internalUnregisterViewModelInstance(instancePointerAddress);
    _deleteViewModelInstanceValue(_pointer);
    _pointer = nullptr;
    _finalizer.detach(this);
  }

  @override
  advanced() {
    _setViewModelInstanceTriggerAdvanced(pointer);
  }
}

class FFIInternalViewModelInstanceEnum extends InternalViewModelInstanceEnum
    implements RiveFFIReference, Finalizable {
  static final _finalizer =
      NativeFinalizer(_deleteViewModelInstanceValueNative);

  @override
  Pointer<Void> get pointer => _pointer;
  Pointer<Void> _pointer;
  void Function(int value)? _callback;
  FFIInternalViewModelInstanceEnum(this._pointer) {
    _finalizer.attach(this, _pointer.cast(), detach: this);

    Pointer<Void> instancePointer = _setViewModelInstanceEnumCallback(pointer);
    instancePointerAddress = instancePointer.address;
    if (instancePointer != nullptr) {
      FFIRiveFile.internalRegisterViewModelInstance(
          instancePointerAddress, this);
    }
  }
  @override
  void onChanged(void Function(int value) callback) {
    _callback = callback;
  }

  @override
  set value(int val) {
    if (suppressCallback) {
      return;
    }
    suppressCallback = true;
    _setViewModelInstanceEnumValue(pointer, val);
    suppressCallback = false;
  }

  @override
  set nativeValue(int val) {
    if (suppressCallback) {
      return;
    }
    suppressCallback = true;
    if (_callback != null) {
      _callback!(val);
    }
    suppressCallback = false;
  }

  @override
  void dispose() {
    if (_pointer == nullptr) {
      return;
    }
    FFIRiveFile.internalUnregisterViewModelInstance(instancePointerAddress);
    _deleteViewModelInstanceValue(_pointer);
    _pointer = nullptr;
    _finalizer.detach(this);
  }
}

class FFIRiveInternalViewModelInstanceList extends InternalViewModelInstanceList
    implements RiveFFIReference, Finalizable {
  static final _finalizer =
      NativeFinalizer(_deleteViewModelInstanceValueNative);

  @override
  Pointer<Void> get pointer => _pointer;
  Pointer<Void> _pointer;
  int index;

  FFIRiveInternalViewModelInstanceList(this._pointer, this.index) {
    _finalizer.attach(this, _pointer.cast(), detach: this);
  }

  @override
  void dispose() {
    if (_pointer == nullptr) {
      return;
    }
    _deleteViewModelInstanceValue(_pointer);
    _pointer = nullptr;
    _finalizer.detach(this);
  }

  @override
  InternalViewModelInstance referenceViewModelInstance(int index) {
    final viewModelInstancePointer =
        _viewModelInstanceListItemViewModel(pointer, index);
    return FFIRiveInternalViewModelInstance(viewModelInstancePointer);
  }
}

class FFIRiveInternalDataContext extends InternalDataContext
    implements RiveFFIReference, Finalizable {
  static final _finalizer = NativeFinalizer(_deleteDataContextNative);
  @override
  Pointer<Void> get pointer => _pointer;
  Pointer<Void> _pointer;
  FFIRiveInternalDataContext(this._pointer) {
    _finalizer.attach(this, _pointer.cast(), detach: this);
  }

  @override
  InternalViewModelInstance get viewModelInstance {
    final viewModelInstancePointer = _riveDataContextViewModelInstance(pointer);
    return FFIRiveInternalViewModelInstance(viewModelInstancePointer);
  }

  @override
  void dispose() {
    if (_pointer == nullptr) {
      return;
    }
    _deleteDataContext(_pointer);
    _pointer = nullptr;
    _finalizer.detach(this);
  }
}

class FFIRiveInternalDataBind extends InternalDataBind
    implements RiveFFIReference {
  @override
  Pointer<Void> get pointer => _pointer;
  Pointer<Void> _pointer;
  FFIRiveInternalDataBind(this._pointer);

  @override
  int get dirt => _riveDataBindDirt(pointer);

  @override
  set dirt(int value) => _riveDataBindSetDirt(pointer, value);

  @override
  int get flags => _riveDataBindFlags(pointer);

  @override
  void updateSourceBinding() {
    _riveDataBindUpdateSourceBinding(pointer);
  }

  @override
  void update(int dirt) {
    _riveDataBindUpdate(pointer, dirt);
  }

  @override
  void dispose() {
    if (_pointer == nullptr) {
      return;
    }
    _pointer = nullptr;
  }
}

class FFIComponent extends Component implements RiveFFIReference, Finalizable {
  static final _finalizer = NativeFinalizer(_deleteComponentNative);

  @override
  Pointer<Void> pointer;

  FFIComponent(this.pointer) {
    _finalizer.attach(this, pointer.cast(), detach: this);
  }

  @override
  void dispose() {
    if (pointer == nullptr) {
      return;
    }
    _deleteComponent(pointer);
    pointer = nullptr;
    _finalizer.detach(this);
  }

  @override
  Mat2D get worldTransform {
    _componentGetWorldTransform(pointer, _floatQueryBuffer);
    return Mat2D()
      ..values[0] = _floatQueryBuffer[0]
      ..values[1] = _floatQueryBuffer[1]
      ..values[2] = _floatQueryBuffer[2]
      ..values[3] = _floatQueryBuffer[3]
      ..values[4] = _floatQueryBuffer[4]
      ..values[5] = _floatQueryBuffer[5];
  }

  @override
  set worldTransform(Mat2D value) => _componentSetWorldTransform(
        pointer,
        value[0],
        value[1],
        value[2],
        value[3],
        value[4],
        value[5],
      );

  @override
  double get scaleX => _componentGetScaleX(pointer);

  @override
  set scaleX(double value) => _componentSetScaleX(pointer, value);

  @override
  double get scaleY => _componentGetScaleY(pointer);

  @override
  set rotation(double value) => _componentSetRotation(pointer, value);

  @override
  double get rotation => _componentGetRotation(pointer);

  @override
  set scaleY(double value) => _componentSetScaleY(pointer, value);

  @override
  double get x => _componentGetX(pointer);

  @override
  set x(double value) => _componentSetX(pointer, value);

  @override
  double get y => _componentGetY(pointer);

  @override
  set y(double value) => _componentSetY(pointer, value);

  @override
  void setLocalFromWorld(Mat2D worldTransform) => _componentSetLocalFromWorld(
        pointer,
        worldTransform[0],
        worldTransform[1],
        worldTransform[2],
        worldTransform[3],
        worldTransform[4],
        worldTransform[5],
      );
}

class FFIAnimation extends Animation implements RiveFFIReference, Finalizable {
  static final _finalizer = NativeFinalizer(_animationInstanceDeleteNative);

  @override
  Pointer<Void> get pointer => _pointer;
  Pointer<Void> _pointer;

  FFIAnimation(this._pointer) {
    _finalizer.attach(this, _pointer.cast(), detach: this);
  }

  @override
  double get time => _animationInstanceGetTime(pointer);

  @override
  set time(double value) => _animationInstanceSetTime(pointer, value);

  @override
  bool advance(double elapsedSeconds) =>
      _animationInstanceAdvance(pointer, elapsedSeconds);

  @override
  bool advanceAndApply(double elapsedSeconds) =>
      _animationInstanceAdvanceAndApply(pointer, elapsedSeconds);

  @override
  void apply({double mix = 1.0}) => _animationInstanceApply(pointer, mix);

  @override
  void dispose() {
    if (_pointer == nullptr) {
      return;
    }
    _animationInstanceDelete(_pointer);
    _pointer = nullptr;
    _finalizer.detach(this);
  }

  @override
  double get duration => _animationInstanceGetDuration(_pointer);

  @override
  double globalToLocalTime(double seconds) =>
      animationInstanceGetLocalSeconds(_pointer, seconds);
}

Future<File?> decodeRiveFile(
  Uint8List bytes,
  Factory riveFactory, {
  AssetLoaderCallback? assetLoader,
}) async {
  // let the factory know we're starting to decode.
  var pointer = malloc.allocate<Uint8>(bytes.length);
  for (int i = 0; i < bytes.length; i++) {
    pointer[i] = bytes[i];
  }

  NativeCallable<_AssetLoaderCallbackNative>? nativeCallback;
  if (assetLoader != null) {
    nativeCallback = NativeCallable<_AssetLoaderCallbackNative>.isolateLocal(
      (
        Pointer<Void> fileAssetPointer,
        Pointer<Uint8> data,
        int size,
      ) {
        final assetType = _riveFileAssetCoreType(fileAssetPointer);

        FileAsset fileAsset = switch (assetType) {
          ImageAsset.coreType => FFIImageAsset(fileAssetPointer, riveFactory),
          FontAsset.coreType => FFIFontAsset(fileAssetPointer, riveFactory),
          AudioAsset.coreType => FFIAudioAsset(fileAssetPointer, riveFactory),
          _ => FFIUnknownAsset(fileAssetPointer, riveFactory),
        };

        final Uint8List? assetData =
            data != nullptr ? data.asTypedList(size) : null;

        return assetLoader(
          fileAsset,
          assetData,
        );
      },
      exceptionalReturn: false,
    );
  }

  // Pass the pointer in to a native method.
  var result = _loadRiveFile(
    pointer,
    bytes.length,
    (riveFactory as FFIFactory).pointer,
    nativeCallback?.nativeFunction ?? nullptr,
  );
  malloc.free(pointer);
  await riveFactory.completedDecodingFile(result != nullptr);
  nativeCallback?.close();
  nativeCallback = null;
  if (result == nullptr) {
    return null;
  }

  return FFIRiveFile(result, riveFactory);
}

void batchAdvanceStateMachines(
    Iterable<StateMachine> stateMachines, double elapsedSeconds) {
  if (stateMachines.isEmpty) {
    return;
  }

  var mem = malloc
      .allocate<Pointer<Void>>(stateMachines.length * sizeOf<Pointer<Void>>());
  int index = 0;
  for (final machine in stateMachines) {
    mem[index++] = (machine as RiveFFIReference).pointer;
  }
  _batchAdvance(mem, stateMachines.length, elapsedSeconds);
  malloc.free(mem);
}

void batchAdvanceAndRenderStateMachines(Iterable<StateMachine> stateMachines,
    double elapsedSeconds, Renderer renderer) {
  if (stateMachines.isEmpty) {
    return;
  }

  var mem = malloc
      .allocate<Pointer<Void>>(stateMachines.length * sizeOf<Pointer<Void>>());
  int index = 0;
  for (final machine in stateMachines) {
    mem[index++] = (machine as RiveFFIReference).pointer;
  }
  _batchAdvanceAndRender(mem, stateMachines.length, elapsedSeconds,
      (renderer as RiveFFIReference).pointer);
  malloc.free(mem);
}

abstract class FFIFactory extends Factory {
  final Pointer<Void> pointer;
  FFIFactory(this.pointer);

  @override
  RenderPath makePath([bool initEmpty = false]) =>
      FFIRenderPath(this, initEmpty);

  @override
  RenderPaint makePaint() => FFIRenderPaint(this);

  @override
  IndexRenderBuffer? makeIndexBuffer(int elementCount) {
    if (elementCount <= 0) {
      return null;
    }
    return FFIIndexRenderBuffer(this, elementCount);
  }

  @override
  VertexRenderBuffer? makeVertexBuffer(int elementCount) {
    if (elementCount <= 0) {
      return null;
    }
    return FFIVertexRenderBuffer(this, elementCount);
  }

  @override
  Future<RenderImage?> decodeImage(Uint8List bytes) =>
      FFIRenderImage.decode(this, bytes);

  @override
  Future<Font?> decodeFont(Uint8List bytes) async => Font.decode(bytes);

  @override
  Future<AudioSource?> decodeAudio(Uint8List bytes) async =>
      AudioEngine.loadSource(bytes);

  @override
  RenderText makeText() => RenderTextFFI(_makeRawText(pointer));
}

Factory getRiveFactory() => FFIRiveFactory.instance;

Factory getFlutterFactory() => FFIFlutterFactory.instance;
