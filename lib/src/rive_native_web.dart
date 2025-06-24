// ignore: avoid_web_libraries_in_flutter
import 'dart:async';
import 'dart:convert';
import 'dart:js_interop' as js;
import 'dart:js_interop_unsafe';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:ui_web' as ui_web;

import 'package:flutter/widgets.dart';
import 'package:rive_native/rive_native.dart';
import 'package:rive_native/src/wasm_version.dart';
import 'package:rive_native/src/web/layout_engine_web.dart';
import 'package:rive_native/src/web/rive_audio_web.dart';
import 'package:rive_native/src/web/rive_renderer_web.dart';
import 'package:rive_native/src/web/rive_text_web.dart';
import 'package:rive_native/src/web/scripting_workspace_web.dart';
import 'package:web/web.dart' as html;

extension RiveNativeJsExtension on js.JSFunction {
  @js.JS('call')
  external js.JSAny? callAsFunctionEx([
    js.JSAny? thisArg,
    js.JSAny? arg1,
    js.JSAny? arg2,
    js.JSAny? arg3,
    js.JSAny? arg4,
    js.JSAny? arg5,
    js.JSAny? arg6,
    js.JSAny? arg7,
    js.JSAny? arg8,
    js.JSAny? arg9,
    js.JSAny? arg10,
    js.JSAny? arg11,
    js.JSAny? arg12,
    js.JSAny? arg13,
    js.JSAny? arg14,
    js.JSAny? arg15,
    js.JSAny? arg16,
    js.JSAny? arg17,
    js.JSAny? arg18,
  ]);
}

base class _WebRenderTexture extends RenderTexture {
  // late int _webRenderer;
  static int _canvasCounter = 0;
  js.JSObject? jsRenderContext;
  js.JSAny? jsRenderContextPtr;
  final String rendererId;
  final html.HTMLCanvasElement canvasElement;

  @override
  bool get isReady => true;

  static _WebRenderTexture make() {
    var id = '_rr_${_canvasCounter++}';
    var canvasElement = html.HTMLCanvasElement()
      ..id = id
      ..style.height = '100%'
      ..style.width = '100%';
    html.document.body!.append(canvasElement);

    var renderer = RiveWasm.makeRenderer.callAsFunction(null, canvasElement);
    assert(renderer != null && renderer is js.JSObject);
    return _WebRenderTexture(renderer as js.JSObject, canvasElement, id);
  }

  _WebRenderTexture(this.jsRenderContext, this.canvasElement, this.rendererId) {
    jsRenderContextPtr = jsRenderContext?.getProperty('_ptr'.toJS);
    ui_web.platformViewRegistry.registerViewFactory(rendererId, (int viewId) {
      return canvasElement;
    });
  }

  @override
  void dispose() {
    RiveWasm.deleteRenderer.callAsFunction(null, jsRenderContextPtr);
    jsRenderContext = null;
    jsRenderContextPtr = null;
  }

  @override
  Widget widget({RenderTexturePainter? painter, Key? key}) => Stack(
        children: [
          Positioned.fill(child: HtmlElementView(viewType: rendererId)),
          Positioned.fill(child: _RiveNativeWebView(this, painter, key: key)),
        ],
      );

  @override
  void clear(Color color, [bool write = true]) => RiveWasm.clearRenderer
      .callAsFunction(null, jsRenderContext, color.value.toJS);

  @override
  void flush(double devicePixelRatio) =>
      RiveWasm.flushRenderer.callAsFunction(null, jsRenderContextPtr);

  @override
  dynamic get nativeTexture => null;

  @override
  Renderer get renderer => WebRiveRenderer(jsRenderContextPtr, Factory.rive);

  @override
  Future<ui.Image> toImage() {
    final completer = Completer<ui.Image>();
    void blobResult(html.Blob blob) {
      blob.arrayBuffer().toDart.then((js.JSArrayBuffer buffer) {
        ui.decodeImageFromList(buffer.toDart.asUint8List(), (image) {
          completer.complete(image);
        });
      });
    }

    canvasElement.toBlob(blobResult.toJS, 'image/png');
    // ui.decodeImageFromList(
    //   Uint8List(0),
    //   (image) {
    //     completer.complete(image);
    //   },
    // );
    return completer.future;
    // final scene = ui.SceneBuilder();
    // print('view id is: $_viewId');
    // scene.addPlatformView(
    //   _viewId,
    //   // offset: Offset(-offset.dx, -offset.dy - 40),
    //   // width: _width.toDouble(),
    //   // height: _height.toDouble(),

    // );

    // final build = scene.build();
    // return build.toImage(1000, 1000);
    // final imageData =
    //     await imagemCapturada.toByteData(format: ImageByteFormat.png);
    // final imageBytes = imageData!.buffer
    //     .asUint8List(imageData.offsetInBytes, imageData.buffer.lengthInBytes);
    // return imageBytes;
  }
}

class WasmBuffer {
  js.JSAny _pointer;
  late Uint8List _data;
  Uint8List get data => _data;
  js.JSAny get pointer => _pointer;

  WasmBuffer(int size)
      : _pointer = RiveWasm.allocateBuffer.callAsFunction(null, size.toJS)
            as js.JSAny {
    _data = RiveWasm.heap((_pointer as js.JSNumber).toDartInt, size);
  }

  factory WasmBuffer.fromBytes(Uint8List bytes) {
    var buffer = WasmBuffer(bytes.length);
    buffer.data.setRange(0, bytes.length, bytes);
    return buffer;
  }

  void dispose() {
    RiveWasm.deleteBuffer.callAsFunction(null, _pointer);
    _pointer = 0.toJS;
    _data = Uint8List(0);
  }
}

class RiveWasm {
  static late js.JSFunction makeRenderer;
  static late js.JSFunction deleteRenderer;
  static late js.JSFunction deleteFlutterRenderer;
  static late js.JSFunction flushRenderer;
  static late js.JSFunction clearRenderer;
  static late js.JSFunction saveRenderer;
  static late js.JSFunction restoreRenderer;
  static late js.JSFunction transformRenderer;
  static late js.JSFunction makeEmptyRenderPath;
  static late js.JSFunction deleteRenderPath;
  static late js.JSFunction renderPathHitTest;
  static late js.JSFunction addPath;
  static late js.JSFunction addPathBackwards;
  static late js.JSFunction trimPathEffectPath;
  static late js.JSFunction makeTrimPathEffect;
  static late js.JSFunction deleteTrimPathEffect;
  static late js.JSFunction trimPathEffectInvalidate;
  static late js.JSFunction trimPathEffectGetEnd;
  static late js.JSFunction trimPathEffectSetEnd;
  static late js.JSFunction trimPathEffectGetMode;
  static late js.JSFunction trimPathEffectSetMode;
  static late js.JSFunction trimPathEffectGetOffset;
  static late js.JSFunction trimPathEffectSetOffset;
  static late js.JSFunction trimPathEffectGetStart;
  static late js.JSFunction trimPathEffectSetStart;
  static late js.JSFunction makePathMeasure;
  static late js.JSFunction deletePathMeasure;
  static late js.JSFunction pathMeasureAtPercentage;
  static late js.JSFunction pathMeasureAtDistance;
  static late js.JSFunction pathMeasureLength;
  static late js.JSFunction deleteRenderImage;
  static late js.JSFunction renderImageWidth;
  static late js.JSFunction renderImageHeight;
  static late js.JSFunction makeVertexRenderBuffer;
  static late js.JSFunction makeIndexRenderBuffer;
  static late js.JSFunction deleteRenderBuffer;
  static late js.JSFunction mapRenderBuffer;
  static late js.JSFunction unmapRenderBuffer;
  static late js.JSFunction setArtboardLayoutChangedCallback;
  static late js.JSFunction setArtboardLayoutDirtyCallback;
  static late js.JSFunction setStateMachineInputChangedCallback;
  static late js.JSFunction setArtboardEventCallback;
  static late js.JSFunction addRawPath;
  static late js.JSFunction addRawPathWithTransform;
  static late js.JSFunction addRawPathWithTransformClockwise;

  static late js.JSFunction deleteDashPathEffect;
  static late js.JSFunction makeDashPathEffect;
  static late js.JSFunction dashPathEffectGetPathLength;
  static late js.JSFunction dashPathEffectGetOffset;
  static late js.JSFunction dashPathEffectSetOffset;
  static late js.JSFunction dashPathEffectGetOffsetIsPercentage;
  static late js.JSFunction dashPathEffectSetOffsetIsPercentage;
  static late js.JSFunction dashPathClearDashes;
  static late js.JSFunction dashPathAddDash;
  static late js.JSFunction dashPathInvalidate;
  static late js.JSFunction dashPathEffectPath;

  static late js.JSFunction renderPathColinearCheck;
  static late js.JSFunction renderPathPreciseBounds;
  static late js.JSFunction renderPathPreciseLength;
  static late js.JSFunction renderPathBounds;
  static late js.JSFunction renderPathIsClosed;
  static late js.JSFunction renderPathHasBounds;
  static late js.JSFunction renderPathIsClockwise;

  static late js.JSFunction renderPathCopyBuffers;

  static const scratchBufferSize = 1024;

  static Uint8List get scratchBuffer {
    return (heapViewU8.callAsFunction(
      null,
      scratchBufferPtr,
      scratchBufferSize.toJS,
    ) as js.JSUint8Array)
        .toDart;
  }

  static late js.JSNumber scratchBufferPtr;
  static late js.JSFunction appendCommands;
  static late js.JSFunction makeRenderPath;
  static late js.JSFunction renderPathSetFillRule;
  static late js.JSFunction appendRenderPath;
  static late js.JSFunction rewindRenderPath;
  static late js.JSFunction makeRenderPaint;
  static late js.JSFunction deleteRenderPaint;
  static late js.JSFunction updatePaint;
  static late js.JSFunction drawPath;
  static late js.JSFunction drawImage;
  static late js.JSFunction drawImageMesh;
  static late js.JSFunction clipPath;
  static late js.JSFunction heapViewU8;
  static late js.JSFunction stringViewU8;
  static late js.JSFunction decodeImage;
  static late js.JSFunction renderImageSetSize;

  static late js.JSFunction makeFlutterFactory;
  static late js.JSFunction deleteFlutterFactory;
  static late js.JSFunction initFactoryCallbacks;
  static late js.JSFunction makeFlutterRenderer;
  static late js.JSFunction allocateBuffer;
  static late js.JSFunction deleteBuffer;
  static late js.JSFunction loadRiveFile;
  static late js.JSFunction riveFileAssetName;
  static late js.JSFunction riveFileAssetFileExtension;
  static late js.JSFunction riveFileAssetCdnBaseUrl;
  static late js.JSFunction riveFileAssetCdnUuid;
  static late js.JSFunction riveFileAssetId;
  static late js.JSFunction riveFileAssetCoreType;
  static late js.JSFunction riveFileAssetSetRenderImage;
  static late js.JSFunction riveFileAssetSetFont;
  static late js.JSFunction riveFileAssetSetAudioSource;
  static late js.JSFunction deleteRiveFile;
  static late js.JSFunction riveFileArtboardDefault;
  static late js.JSFunction riveFileArtboardNamed;
  static late js.JSFunction riveFileArtboardByIndex;
  static late js.JSFunction riveFileViewModelCount;
  static late js.JSFunction riveFileViewModelRuntimeByIndex;
  static late js.JSFunction riveFileViewModelRuntimeByName;
  static late js.JSFunction riveFileDefaultArtboardViewModelRuntime;
  static late js.JSFunction viewModelRuntimePropertyCount;
  static late js.JSFunction viewModelRuntimeInstanceCount;
  static late js.JSFunction viewModelRuntimeName;
  static late js.JSFunction viewModelRuntimeProperties;
  static late js.JSFunction fileEnums;
  static late js.JSFunction createVMIRuntimeFromIndex;
  static late js.JSFunction createVMIRuntimeFromName;
  static late js.JSFunction createDefaultVMIRuntime;
  static late js.JSFunction createVMIRuntime;
  static late js.JSFunction vmiRuntimeName;
  static late js.JSFunction vmiRuntimeProperties;
  static late js.JSFunction vmiRuntimeGetViewModelProperty;
  static late js.JSFunction vmiRuntimeGetNumberProperty;
  static late js.JSFunction getVMINumberRuntimeValue;
  static late js.JSFunction setVMINumberRuntimeValue;
  static late js.JSFunction vmiRuntimeGetStringProperty;
  static late js.JSFunction getVMIStringRuntimeValue;
  static late js.JSFunction setVMIStringRuntimeValue;
  static late js.JSFunction vmiRuntimeGetBooleanProperty;
  static late js.JSFunction getVMIBooleanRuntimeValue;
  static late js.JSFunction setVMIBooleanRuntimeValue;
  static late js.JSFunction vmiRuntimeGetColorProperty;
  static late js.JSFunction getVMIColorRuntimeValue;
  static late js.JSFunction setVMIColorRuntimeValue;
  static late js.JSFunction vmiRuntimeGetEnumProperty;
  static late js.JSFunction getVMIEnumRuntimeValue;
  static late js.JSFunction setVMIEnumRuntimeValue;
  static late js.JSFunction vmiRuntimeGetTriggerProperty;
  static late js.JSFunction triggerVMITriggerRuntime;
  static late js.JSFunction vmiValueRuntimeHasChanged;
  static late js.JSFunction vmiValueRuntimeClearChanges;
  static late js.JSFunction artboardSetVMIRuntime;
  static late js.JSFunction stateMachineSetVMIRuntime;
  static late js.JSFunction deleteVMIValueRuntime;
  static late js.JSFunction deleteVMIRuntime;
  static late js.JSFunction deleteViewModelRuntime;
  static late js.JSFunction artboardDraw;
  static late js.JSFunction deleteArtboardInstance;
  static late js.JSFunction artboardAnimationCount;
  static late js.JSFunction artboardStateMachineCount;
  static late js.JSFunction artboardAnimationAt;
  static late js.JSFunction artboardComponentNamed;
  static late js.JSFunction componentGetWorldTransform;
  static late js.JSFunction componentSetWorldTransform;
  static late js.JSFunction artboardGetRenderTransform;
  static late js.JSFunction artboardSetRenderTransform;
  static late js.JSFunction componentGetScaleX;
  static late js.JSFunction componentSetScaleX;
  static late js.JSFunction componentGetX;
  static late js.JSFunction componentSetX;
  static late js.JSFunction componentGetScaleY;
  static late js.JSFunction componentSetScaleY;
  static late js.JSFunction componentGetY;
  static late js.JSFunction componentSetY;
  static late js.JSFunction componentGetRotation;
  static late js.JSFunction componentSetRotation;
  static late js.JSFunction componentSetLocalFromWorld;
  static late js.JSFunction artboardAnimationNamed;
  static late js.JSFunction artboardSetFrameOrigin;
  static late js.JSFunction artboardGetFrameOrigin;
  static late js.JSFunction animationInstanceAdvance;
  static late js.JSFunction animationInstanceApply;
  static late js.JSFunction animationInstanceAdvanceAndApply;
  static late js.JSFunction animationInstanceGetTime;
  static late js.JSFunction animationInstanceGetDuration;
  static late js.JSFunction animationInstanceGetLocalSeconds;
  static late js.JSFunction animationInstanceSetTime;
  static late js.JSFunction animationInstanceDelete;
  static late js.JSFunction artboardAddToRenderPath;
  static late js.JSFunction artboardBounds;
  static late js.JSFunction artboardLayoutBounds;
  static late js.JSFunction riveArtboardAdvance;
  static late js.JSFunction riveArtboardGetOpacity;
  static late js.JSFunction riveArtboardSetOpacity;
  static late js.JSFunction riveArtboardGetWidth;
  static late js.JSFunction riveArtboardSetWidth;
  static late js.JSFunction riveArtboardGetHeight;
  static late js.JSFunction riveArtboardSetHeight;
  static late js.JSFunction riveArtboardGetOriginalWidth;
  static late js.JSFunction riveArtboardGetOriginalHeight;
  static late js.JSFunction riveArtboardStateMachineDefault;
  static late js.JSFunction riveArtboardStateMachineNamed;
  static late js.JSFunction riveArtboardStateMachineAt;
  static late js.JSFunction riveArtboardHasComponentDirt;
  static late js.JSFunction riveArtboardUpdatePass;
  static late js.JSFunction deleteStateMachineInstance;
  static late js.JSFunction stateMachineInstanceAdvance;
  static late js.JSFunction stateMachineInstanceAdvanceAndApply;
  static late js.JSFunction deleteInput;
  static late js.JSFunction deleteComponent;
  static late js.JSFunction stateMachineInput;
  static late js.JSFunction stateMachineInputName;
  static late js.JSFunction stateMachineInputType;
  static late js.JSFunction stateMachineInstanceNumber;
  static late js.JSFunction stateMachineInstanceDone;
  static late js.JSFunction stateMachineInstanceHitTest;
  static late js.JSFunction stateMachineInstancePointerDown;
  static late js.JSFunction stateMachineInstancePointerUp;
  static late js.JSFunction stateMachineInstancePointerMove;
  static late js.JSFunction stateMachineInstancePointerExit;
  static late js.JSFunction stateMachineGetReportedEventCount;
  static late js.JSFunction stateMachineReportedEventAt;
  static late js.JSFunction deleteEvent;
  static late js.JSFunction deleteCustomProperty;
  static late js.JSFunction getEventName;
  static late js.JSFunction getOpenUrlEventUrl;
  static late js.JSFunction getOpenUrlEventTarget;
  static late js.JSFunction getEventCustomPropertyCount;
  static late js.JSFunction getEventCustomProperty;
  static late js.JSFunction getCustomPropertyNumber;
  static late js.JSFunction getCustomPropertyBoolean;
  static late js.JSFunction getCustomPropertyString;
  static late js.JSFunction getNumberValue;
  static late js.JSFunction setNumberValue;
  static late js.JSFunction stateMachineInstanceBoolean;
  static late js.JSFunction getBooleanValue;
  static late js.JSFunction setBooleanValue;
  static late js.JSFunction stateMachineInstanceTrigger;
  static late js.JSFunction fireTrigger;
  static late js.JSFunction stateMachineInstanceBatchAdvance;
  static late js.JSFunction stateMachineInstanceBatchAdvanceAndRender;
  static late js.JSFunction artboardSetText;
  static late js.JSFunction artboardGetText;
  static late js.JSFunction artboardTakeLayoutNode;
  static late js.JSFunction artboardSyncStyleChanges;
  static late js.JSFunction artboardWidthOverride;
  static late js.JSFunction artboardHeightOverride;
  static late js.JSFunction artboardWidthIntrinsicallySizeOverride;
  static late js.JSFunction artboardHeightIntrinsicallySizeOverride;
  static late js.JSFunction updateLayoutBounds;
  static late js.JSFunction cascadeLayoutStyle;

  static late js.JSFunction makeFlutterRenderImage;
  static late js.JSFunction flutterRenderImageId;
  static late js.JSFunction riveDataContext;
  static late js.JSFunction deleteDataContext;
  static late js.JSFunction deleteViewModelInstance;
  static late js.JSFunction deleteViewModelInstanceValue;
  static late js.JSFunction riveDataContextViewModelInstance;
  static late js.JSFunction viewModelInstancePropertyValue;
  static late js.JSFunction viewModelInstanceListItemViewModel;
  static late js.JSFunction viewModelInstanceReferenceViewModel;
  static late js.JSFunction setViewModelInstanceNumberValue;
  static late js.JSFunction setViewModelInstanceColorValue;
  static late js.JSFunction setViewModelInstanceStringValue;
  static late js.JSFunction setViewModelInstanceBooleanValue;
  static late js.JSFunction setViewModelInstanceTriggerValue;
  static late js.JSFunction setViewModelInstanceTriggerAdvanced;
  static late js.JSFunction setViewModelInstanceEnumValue;
  static late js.JSFunction artboardCollectDataBinds;
  static late js.JSFunction artboardTotalDataBinds;
  static late js.JSFunction artboardDataBindAt;
  static late js.JSFunction riveDataBindDirt;
  static late js.JSFunction riveDataBindSetDirt;
  static late js.JSFunction riveDataBindFlags;
  static late js.JSFunction riveDataBindUpdate;
  static late js.JSFunction riveDataBindUpdateSourceBinding;
  static late js.JSFunction artboardClearDataContext;
  static late js.JSFunction artboardDataContextFromInstance;
  static late js.JSFunction artboardInternalDataContext;
  static late js.JSFunction artboardDataContext;
  static late js.JSFunction stateMachineDataContextFromInstance;
  static late js.JSFunction stateMachineDataContext;
  static late js.JSFunction setStateMachineDataBindChangedCallback;
  static late js.JSFunction setViewModelInstanceNumberCallback;
  static late js.JSFunction setViewModelInstanceBooleanCallback;
  static late js.JSFunction setViewModelInstanceColorCallback;
  static late js.JSFunction setViewModelInstanceStringCallback;
  static late js.JSFunction setViewModelInstanceTriggerCallback;
  static late js.JSFunction setViewModelInstanceEnumCallback;
  static late js.JSFunction initBindingCallbacks;

  static late js.JSFunction makeRawText;
  static late js.JSFunction deleteRawText;
  static late js.JSFunction rawTextAppend;
  static late js.JSFunction rawTextClear;
  static late js.JSFunction rawTextIsEmpty;
  static late js.JSFunction rawTextGetSizing;
  static late js.JSFunction rawTextSetSizing;
  static late js.JSFunction rawTextGetOverflow;
  static late js.JSFunction rawTextSetOverflow;
  static late js.JSFunction rawTextGetAlign;
  static late js.JSFunction rawTextSetAlign;
  static late js.JSFunction rawTextGetMaxWidth;
  static late js.JSFunction rawTextSetMaxWidth;
  static late js.JSFunction rawTextGetMaxHeight;
  static late js.JSFunction rawTextSetMaxHeight;
  static late js.JSFunction rawTextGetParagraphSpacing;
  static late js.JSFunction rawTextSetParagraphSpacing;
  static late js.JSFunction rawTextBounds;
  static late js.JSFunction rawTextRender;

  static ByteData heapView() =>
      ByteData.sublistView(heapViewU8.callAsFunction() as Uint8List);

  static Uint8List heap(int pointer, int size) =>
      (heapViewU8.callAsFunction(null, pointer.toJS, size.toJS)
              as js.JSUint8Array)
          .toDart;

  static String toDartString(int pointer) {
    var codeUnits =
        (stringViewU8.callAsFunction(null, pointer.toJS) as js.JSUint8Array)
            .toDart;
    return utf8.decode(codeUnits);
  }

  static void link(js.JSObject module) {
    makeRenderer = module['makeRenderer'] as js.JSFunction;
    deleteRenderer = module['deleteRenderer'] as js.JSFunction;
    flushRenderer = module['flushRenderer'] as js.JSFunction;
    clearRenderer = module['clearRenderer'] as js.JSFunction;
    saveRenderer = module['saveRenderer'] as js.JSFunction;
    restoreRenderer = module['restoreRenderer'] as js.JSFunction;
    transformRenderer = module['transformRenderer'] as js.JSFunction;

    makeEmptyRenderPath = module['_makeEmptyRenderPath'] as js.JSFunction;
    deleteRenderPath = module['_deleteRenderPath'] as js.JSFunction;
    renderPathHitTest = module['_renderPathHitTest'] as js.JSFunction;
    addPath = module['_addPath'] as js.JSFunction;
    addRawPath = module['_addRawPath'] as js.JSFunction;
    addRawPathWithTransform =
        module['_addRawPathWithTransform'] as js.JSFunction;
    addRawPathWithTransformClockwise =
        module['_addRawPathWithTransformClockwise'] as js.JSFunction;
    addPathBackwards = module['_addPathBackwards'] as js.JSFunction;
    appendCommands = module['_appendCommands'] as js.JSFunction;
    makeRenderPath = module['_makeRenderPath'] as js.JSFunction;
    renderPathSetFillRule = module['_renderPathSetFillRule'] as js.JSFunction;
    appendRenderPath = module['_appendRenderPath'] as js.JSFunction;
    rewindRenderPath = module['_rewindRenderPath'] as js.JSFunction;
    makeRenderPaint = module['_makeRenderPaint'] as js.JSFunction;
    deleteRenderPaint = module['_deleteRenderPaint'] as js.JSFunction;
    updatePaint = module['_updatePaint'] as js.JSFunction;
    drawPath = module['_drawPath'] as js.JSFunction;
    drawImage = module['_drawImage'] as js.JSFunction;
    drawImageMesh = module['_drawImageMesh'] as js.JSFunction;
    clipPath = module['_clipPath'] as js.JSFunction;
    trimPathEffectPath = module['_trimPathEffectPath'] as js.JSFunction;
    makeTrimPathEffect = module['_makeTrimPathEffect'] as js.JSFunction;
    deleteTrimPathEffect = module['_deleteTrimPathEffect'] as js.JSFunction;
    trimPathEffectInvalidate =
        module['_trimPathEffectInvalidate'] as js.JSFunction;
    trimPathEffectGetEnd = module['_trimPathEffectGetEnd'] as js.JSFunction;
    trimPathEffectSetEnd = module['_trimPathEffectSetEnd'] as js.JSFunction;
    trimPathEffectGetMode = module['_trimPathEffectGetMode'] as js.JSFunction;
    trimPathEffectSetMode = module['_trimPathEffectSetMode'] as js.JSFunction;
    trimPathEffectGetOffset =
        module['_trimPathEffectGetOffset'] as js.JSFunction;
    trimPathEffectSetOffset =
        module['_trimPathEffectSetOffset'] as js.JSFunction;
    trimPathEffectGetStart = module['_trimPathEffectGetStart'] as js.JSFunction;
    trimPathEffectSetStart = module['_trimPathEffectSetStart'] as js.JSFunction;

    makePathMeasure = module['_makePathMeasure'] as js.JSFunction;
    deletePathMeasure = module['_deletePathMeasure'] as js.JSFunction;
    pathMeasureAtPercentage =
        module['_pathMeasureAtPercentage'] as js.JSFunction;
    pathMeasureAtDistance = module['_pathMeasureAtDistance'] as js.JSFunction;
    pathMeasureLength = module['_pathMeasureLength'] as js.JSFunction;

    decodeImage = module['decodeImage'] as js.JSFunction;
    renderImageSetSize = module['_renderImageSetSize'] as js.JSFunction;
    deleteRenderImage = module['_deleteRenderImage'] as js.JSFunction;
    renderImageWidth = module['_renderImageWidth'] as js.JSFunction;
    renderImageHeight = module['_renderImageHeight'] as js.JSFunction;

    makeVertexRenderBuffer = module['_makeVertexRenderBuffer'] as js.JSFunction;
    makeIndexRenderBuffer = module['_makeIndexRenderBuffer'] as js.JSFunction;
    deleteRenderBuffer = module['_deleteRenderBuffer'] as js.JSFunction;
    mapRenderBuffer = module['_mapRenderBuffer'] as js.JSFunction;
    unmapRenderBuffer = module['_unmapRenderBuffer'] as js.JSFunction;

    // Allocate the scratch buffer.
    allocateBuffer = module["_allocateBuffer"] as js.JSFunction;
    deleteBuffer = module["_deleteBuffer"] as js.JSFunction;
    scratchBufferPtr = allocateBuffer.callAsFunction(
        null, scratchBufferSize.toJS) as js.JSNumber;
    heapViewU8 = module["heapViewU8"] as js.JSFunction;
    stringViewU8 = module["stringViewU8"] as js.JSFunction;

    makeFlutterFactory = module['_makeFlutterFactory'] as js.JSFunction;
    deleteFlutterFactory = module['_deleteFlutterFactory'] as js.JSFunction;
    initFactoryCallbacks = module['initFactoryCallbacks'] as js.JSFunction;
    makeFlutterRenderer = module['_makeFlutterRenderer'] as js.JSFunction;
    deleteFlutterRenderer = module['_deleteFlutterRenderer'] as js.JSFunction;

    loadRiveFile = module['loadRiveFile'] as js.JSFunction;
    deleteRiveFile = module['_deleteRiveFile'] as js.JSFunction;
    riveFileAssetName = module['riveFileAssetName'] as js.JSFunction;
    riveFileAssetFileExtension =
        module['riveFileAssetFileExtension'] as js.JSFunction;
    riveFileAssetCdnBaseUrl =
        module['riveFileAssetCdnBaseUrl'] as js.JSFunction;
    riveFileAssetCdnUuid = module['riveFileAssetCdnUuid'] as js.JSFunction;
    riveFileAssetId = module['_riveFileAssetId'] as js.JSFunction;
    riveFileAssetCoreType = module['_riveFileAssetCoreType'] as js.JSFunction;
    riveFileAssetSetFont = module['_riveFileAssetSetFont'] as js.JSFunction;
    riveFileAssetSetAudioSource =
        module['_riveFileAssetSetAudioSource'] as js.JSFunction;
    riveFileAssetSetRenderImage =
        module['_riveFileAssetSetRenderImage'] as js.JSFunction;
    riveFileArtboardDefault =
        module['_riveFileArtboardDefault'] as js.JSFunction;
    riveFileArtboardNamed = module['_riveFileArtboardNamed'] as js.JSFunction;
    riveFileArtboardByIndex =
        module['_riveFileArtboardByIndex'] as js.JSFunction;
    riveFileViewModelCount = module['_riveFileViewModelCount'] as js.JSFunction;
    riveFileViewModelRuntimeByIndex =
        module['_riveFileViewModelRuntimeByIndex'] as js.JSFunction;
    riveFileViewModelRuntimeByName =
        module['_riveFileViewModelRuntimeByName'] as js.JSFunction;
    riveFileDefaultArtboardViewModelRuntime =
        module['_riveFileDefaultArtboardViewModelRuntime'] as js.JSFunction;
    viewModelRuntimePropertyCount =
        module['_viewModelRuntimePropertyCount'] as js.JSFunction;
    viewModelRuntimeInstanceCount =
        module['_viewModelRuntimeInstanceCount'] as js.JSFunction;
    viewModelRuntimeName = module['_viewModelRuntimeName'] as js.JSFunction;
    viewModelRuntimeProperties =
        module['viewModelRuntimeProperties'] as js.JSFunction;
    fileEnums = module['fileEnums'] as js.JSFunction;
    createVMIRuntimeFromIndex =
        module['_createVMIRuntimeFromIndex'] as js.JSFunction;
    createVMIRuntimeFromName =
        module['_createVMIRuntimeFromName'] as js.JSFunction;
    createDefaultVMIRuntime =
        module['_createDefaultVMIRuntime'] as js.JSFunction;
    createVMIRuntime = module['_createVMIRuntime'] as js.JSFunction;
    vmiRuntimeName = module['_vmiRuntimeName'] as js.JSFunction;
    vmiRuntimeProperties = module['vmiRuntimeProperties'] as js.JSFunction;
    vmiRuntimeGetViewModelProperty =
        module['_vmiRuntimeGetViewModelProperty'] as js.JSFunction;
    vmiRuntimeGetNumberProperty =
        module['_vmiRuntimeGetNumberProperty'] as js.JSFunction;
    getVMINumberRuntimeValue =
        module['_getVMINumberRuntimeValue'] as js.JSFunction;
    setVMINumberRuntimeValue =
        module['_setVMINumberRuntimeValue'] as js.JSFunction;
    vmiRuntimeGetStringProperty =
        module['_vmiRuntimeGetStringProperty'] as js.JSFunction;
    getVMIStringRuntimeValue =
        module['_getVMIStringRuntimeValue'] as js.JSFunction;
    setVMIStringRuntimeValue =
        module['_setVMIStringRuntimeValue'] as js.JSFunction;
    vmiRuntimeGetBooleanProperty =
        module['_vmiRuntimeGetBooleanProperty'] as js.JSFunction;
    getVMIBooleanRuntimeValue =
        module['_getVMIBooleanRuntimeValue'] as js.JSFunction;
    setVMIBooleanRuntimeValue =
        module['_setVMIBooleanRuntimeValue'] as js.JSFunction;
    vmiRuntimeGetColorProperty =
        module['_vmiRuntimeGetColorProperty'] as js.JSFunction;
    getVMIColorRuntimeValue =
        module['_getVMIColorRuntimeValue'] as js.JSFunction;
    setVMIColorRuntimeValue =
        module['_setVMIColorRuntimeValue'] as js.JSFunction;
    vmiRuntimeGetEnumProperty =
        module['_vmiRuntimeGetEnumProperty'] as js.JSFunction;
    getVMIEnumRuntimeValue = module['getVMIEnumRuntimeValue'] as js.JSFunction;
    setVMIEnumRuntimeValue = module['_setVMIEnumRuntimeValue'] as js.JSFunction;
    vmiRuntimeGetTriggerProperty =
        module['_vmiRuntimeGetTriggerProperty'] as js.JSFunction;
    triggerVMITriggerRuntime =
        module['_triggerVMITriggerRuntime'] as js.JSFunction;
    vmiValueRuntimeHasChanged =
        module['_vmiValueRuntimeHasChanged'] as js.JSFunction;
    vmiValueRuntimeClearChanges =
        module['_vmiValueRuntimeClearChanges'] as js.JSFunction;
    artboardSetVMIRuntime = module['_artboardSetVMIRuntime'] as js.JSFunction;
    stateMachineSetVMIRuntime =
        module['_stateMachineSetVMIRuntime'] as js.JSFunction;
    deleteVMIValueRuntime = module['_deleteVMIValueRuntime'] as js.JSFunction;
    deleteVMIRuntime = module['_deleteVMIRuntime'] as js.JSFunction;
    deleteViewModelRuntime = module['_deleteViewModelRuntime'] as js.JSFunction;
    artboardDraw = module['_artboardDraw'] as js.JSFunction;
    deleteArtboardInstance = module['_deleteArtboardInstance'] as js.JSFunction;
    artboardAnimationCount = module['_artboardAnimationCount'] as js.JSFunction;
    artboardStateMachineCount =
        module['_artboardStateMachineCount'] as js.JSFunction;
    artboardAnimationAt = module['_artboardAnimationAt'] as js.JSFunction;
    artboardComponentNamed = module['_artboardComponentNamed'] as js.JSFunction;
    componentGetWorldTransform =
        module['_componentGetWorldTransform'] as js.JSFunction;
    componentSetWorldTransform =
        module['_componentSetWorldTransform'] as js.JSFunction;
    artboardGetRenderTransform =
        module['_artboardGetRenderTransform'] as js.JSFunction;
    artboardSetRenderTransform =
        module['_artboardSetRenderTransform'] as js.JSFunction;
    componentGetScaleX = module['_componentGetScaleX'] as js.JSFunction;
    componentSetScaleX = module['_componentSetScaleX'] as js.JSFunction;
    componentGetX = module['_componentGetX'] as js.JSFunction;
    componentSetX = module['_componentSetX'] as js.JSFunction;
    componentGetScaleY = module['_componentGetScaleY'] as js.JSFunction;
    componentSetScaleY = module['_componentSetScaleY'] as js.JSFunction;
    componentGetY = module['_componentGetY'] as js.JSFunction;
    componentSetY = module['_componentSetY'] as js.JSFunction;
    componentGetRotation = module['_componentGetRotation'] as js.JSFunction;
    componentSetRotation = module['_componentSetRotation'] as js.JSFunction;
    componentSetLocalFromWorld =
        module['_componentSetLocalFromWorld'] as js.JSFunction;
    artboardAnimationNamed = module['_artboardAnimationNamed'] as js.JSFunction;
    artboardSetFrameOrigin = module['_artboardSetFrameOrigin'] as js.JSFunction;
    artboardGetFrameOrigin = module['_artboardGetFrameOrigin'] as js.JSFunction;
    animationInstanceAdvance =
        module['_animationInstanceAdvance'] as js.JSFunction;
    animationInstanceApply = module['_animationInstanceApply'] as js.JSFunction;
    animationInstanceAdvanceAndApply =
        module['_animationInstanceAdvanceAndApply'] as js.JSFunction;
    animationInstanceGetTime =
        module['_animationInstanceGetTime'] as js.JSFunction;
    animationInstanceGetDuration =
        module['_animationInstanceGetDuration'] as js.JSFunction;
    animationInstanceGetLocalSeconds =
        module['_animationInstanceGetLocalSeconds'] as js.JSFunction;
    animationInstanceSetTime =
        module['_animationInstanceSetTime'] as js.JSFunction;
    animationInstanceDelete =
        module['_animationInstanceDelete'] as js.JSFunction;
    artboardAddToRenderPath =
        module['_artboardAddToRenderPath'] as js.JSFunction;
    artboardBounds = module['_artboardBounds'] as js.JSFunction;
    artboardLayoutBounds = module['_artboardLayoutBounds'] as js.JSFunction;
    riveArtboardAdvance = module['_riveArtboardAdvance'] as js.JSFunction;
    riveArtboardGetOpacity = module['_riveArtboardGetOpacity'] as js.JSFunction;
    riveArtboardSetOpacity = module['_riveArtboardSetOpacity'] as js.JSFunction;
    riveArtboardGetWidth = module['_riveArtboardGetWidth'] as js.JSFunction;
    riveArtboardSetWidth = module['_riveArtboardSetWidth'] as js.JSFunction;
    riveArtboardGetHeight = module['_riveArtboardGetHeight'] as js.JSFunction;
    riveArtboardSetHeight = module['_riveArtboardSetHeight'] as js.JSFunction;
    riveArtboardGetOriginalWidth =
        module['_riveArtboardGetOriginalWidth'] as js.JSFunction;
    riveArtboardGetOriginalHeight =
        module['_riveArtboardGetOriginalHeight'] as js.JSFunction;
    riveArtboardStateMachineDefault =
        module['_riveArtboardStateMachineDefault'] as js.JSFunction;
    riveArtboardStateMachineNamed =
        module['_riveArtboardStateMachineNamed'] as js.JSFunction;
    riveArtboardStateMachineAt =
        module['_riveArtboardStateMachineAt'] as js.JSFunction;
    riveArtboardHasComponentDirt =
        module['_riveArtboardHasComponentDirt'] as js.JSFunction;
    riveArtboardUpdatePass = module['_riveArtboardUpdatePass'] as js.JSFunction;
    setArtboardLayoutChangedCallback =
        module['setArtboardLayoutChangedCallback'] as js.JSFunction;
    setArtboardLayoutDirtyCallback =
        module['setArtboardLayoutDirtyCallback'] as js.JSFunction;
    deleteInput = module['_deleteInput'] as js.JSFunction;
    deleteComponent = module['_deleteComponent'] as js.JSFunction;
    deleteStateMachineInstance =
        module['_deleteStateMachineInstance'] as js.JSFunction;
    stateMachineInstanceAdvance =
        module['_stateMachineInstanceAdvance'] as js.JSFunction;
    stateMachineInstanceAdvanceAndApply =
        module['_stateMachineInstanceAdvanceAndApply'] as js.JSFunction;
    setStateMachineInputChangedCallback =
        module['setStateMachineInputChangedCallback'] as js.JSFunction;
    setArtboardEventCallback =
        module['setArtboardEventCallback'] as js.JSFunction;
    stateMachineInput = module['_stateMachineInput'] as js.JSFunction;
    stateMachineInputName = module['_stateMachineInputName'] as js.JSFunction;
    stateMachineInputType = module['_stateMachineInputType'] as js.JSFunction;
    stateMachineInstanceNumber =
        module['_stateMachineInstanceNumber'] as js.JSFunction;
    stateMachineInstanceDone =
        module['_stateMachineInstanceDone'] as js.JSFunction;
    stateMachineInstanceHitTest =
        module['_stateMachineInstanceHitTest'] as js.JSFunction;
    stateMachineInstancePointerDown =
        module['_stateMachineInstancePointerDown'] as js.JSFunction;
    stateMachineInstancePointerUp =
        module['_stateMachineInstancePointerUp'] as js.JSFunction;
    stateMachineInstancePointerMove =
        module['_stateMachineInstancePointerMove'] as js.JSFunction;
    stateMachineInstancePointerExit =
        module['_stateMachineInstancePointerExit'] as js.JSFunction;

    stateMachineGetReportedEventCount =
        module['_stateMachineGetReportedEventCount'] as js.JSFunction;
    stateMachineReportedEventAt =
        module['stateMachineReportedEventAt'] as js.JSFunction;
    deleteEvent = module['_deleteEvent'] as js.JSFunction;
    deleteCustomProperty = module['_deleteCustomProperty'] as js.JSFunction;
    getEventName = module['_getEventName'] as js.JSFunction;
    getOpenUrlEventUrl = module['_getOpenUrlEventUrl'] as js.JSFunction;
    getOpenUrlEventTarget = module['_getOpenUrlEventTarget'] as js.JSFunction;
    getEventCustomPropertyCount =
        module['_getEventCustomPropertyCount'] as js.JSFunction;
    getEventCustomProperty = module['getEventCustomProperty'] as js.JSFunction;
    getCustomPropertyNumber =
        module['_getCustomPropertyNumber'] as js.JSFunction;
    getCustomPropertyBoolean =
        module['_getCustomPropertyBoolean'] as js.JSFunction;
    getCustomPropertyString =
        module['_getCustomPropertyString'] as js.JSFunction;
    getNumberValue = module['_getNumberValue'] as js.JSFunction;
    setNumberValue = module['_setNumberValue'] as js.JSFunction;
    stateMachineInstanceBoolean =
        module['_stateMachineInstanceBoolean'] as js.JSFunction;
    getBooleanValue = module['_getBooleanValue'] as js.JSFunction;
    setBooleanValue = module['_setBooleanValue'] as js.JSFunction;
    stateMachineInstanceTrigger =
        module['_stateMachineInstanceTrigger'] as js.JSFunction;
    fireTrigger = module['_fireTrigger'] as js.JSFunction;
    stateMachineInstanceBatchAdvance =
        module['_stateMachineInstanceBatchAdvance'] as js.JSFunction;
    stateMachineInstanceBatchAdvanceAndRender =
        module['_stateMachineInstanceBatchAdvanceAndRender'] as js.JSFunction;
    artboardSetText = module['_artboardSetText'] as js.JSFunction;
    artboardGetText = module['_artboardGetText'] as js.JSFunction;
    artboardTakeLayoutNode = module['_artboardTakeLayoutNode'] as js.JSFunction;
    artboardSyncStyleChanges =
        module['_artboardSyncStyleChanges'] as js.JSFunction;
    artboardWidthOverride = module['_artboardWidthOverride'] as js.JSFunction;
    artboardHeightOverride = module['_artboardHeightOverride'] as js.JSFunction;
    artboardWidthIntrinsicallySizeOverride =
        module['_artboardWidthIntrinsicallySizeOverride'] as js.JSFunction;
    artboardHeightIntrinsicallySizeOverride =
        module['_artboardHeightIntrinsicallySizeOverride'] as js.JSFunction;
    updateLayoutBounds = module['_updateLayoutBounds'] as js.JSFunction;
    cascadeLayoutStyle = module['_cascadeLayoutStyle'] as js.JSFunction;

    makeFlutterRenderImage = module['_makeFlutterRenderImage'] as js.JSFunction;
    flutterRenderImageId = module['_flutterRenderImageId'] as js.JSFunction;
    riveDataContext = module['_riveDataContext'] as js.JSFunction;
    deleteDataContext = module['_deleteDataContext'] as js.JSFunction;
    deleteViewModelInstance =
        module['_deleteViewModelInstance'] as js.JSFunction;
    deleteViewModelInstanceValue =
        module['_deleteViewModelInstanceValue'] as js.JSFunction;
    riveDataContextViewModelInstance =
        module['_riveDataContextViewModelInstance'] as js.JSFunction;
    viewModelInstancePropertyValue =
        module['_viewModelInstancePropertyValue'] as js.JSFunction;
    viewModelInstanceListItemViewModel =
        module['_viewModelInstanceListItemViewModel'] as js.JSFunction;
    viewModelInstanceReferenceViewModel =
        module['_viewModelInstanceReferenceViewModel'] as js.JSFunction;
    setViewModelInstanceNumberValue =
        module['_setViewModelInstanceNumberValue'] as js.JSFunction;
    setViewModelInstanceColorValue =
        module['_setViewModelInstanceColorValue'] as js.JSFunction;
    setViewModelInstanceStringValue =
        module['_setViewModelInstanceStringValue'] as js.JSFunction;
    setViewModelInstanceBooleanValue =
        module['_setViewModelInstanceBooleanValue'] as js.JSFunction;
    setViewModelInstanceTriggerValue =
        module['_setViewModelInstanceTriggerValue'] as js.JSFunction;
    setViewModelInstanceTriggerAdvanced =
        module['_setViewModelInstanceTriggerAdvanced'] as js.JSFunction;
    setViewModelInstanceEnumValue =
        module['_setViewModelInstanceEnumValue'] as js.JSFunction;
    artboardCollectDataBinds =
        module['_artboardCollectDataBinds'] as js.JSFunction;
    artboardTotalDataBinds = module['_artboardTotalDataBinds'] as js.JSFunction;
    artboardDataBindAt = module['_artboardDataBindAt'] as js.JSFunction;
    riveDataBindDirt = module['_riveDataBindDirt'] as js.JSFunction;
    riveDataBindSetDirt = module['_riveDataBindSetDirt'] as js.JSFunction;
    riveDataBindFlags = module['_riveDataBindFlags'] as js.JSFunction;
    riveDataBindUpdate = module['_riveDataBindUpdate'] as js.JSFunction;
    riveDataBindUpdateSourceBinding =
        module['_riveDataBindUpdateSourceBinding'] as js.JSFunction;
    artboardClearDataContext =
        module['_artboardClearDataContext'] as js.JSFunction;
    artboardDataContextFromInstance =
        module['_artboardDataContextFromInstance'] as js.JSFunction;
    artboardInternalDataContext =
        module['_artboardInternalDataContext'] as js.JSFunction;
    artboardDataContext = module['_artboardDataContext'] as js.JSFunction;
    stateMachineDataContextFromInstance =
        module['_stateMachineDataContextFromInstance'] as js.JSFunction;
    stateMachineDataContext =
        module['_stateMachineDataContext'] as js.JSFunction;
    setStateMachineDataBindChangedCallback =
        module['setStateMachineDataBindChangedCallback'] as js.JSFunction;
    setViewModelInstanceNumberCallback =
        module['_setViewModelInstanceNumberCallback'] as js.JSFunction;
    setViewModelInstanceBooleanCallback =
        module['_setViewModelInstanceBooleanCallback'] as js.JSFunction;
    setViewModelInstanceColorCallback =
        module['_setViewModelInstanceColorCallback'] as js.JSFunction;
    setViewModelInstanceStringCallback =
        module['_setViewModelInstanceStringCallback'] as js.JSFunction;
    setViewModelInstanceTriggerCallback =
        module['_setViewModelInstanceTriggerCallback'] as js.JSFunction;
    setViewModelInstanceEnumCallback =
        module['_setViewModelInstanceEnumCallback'] as js.JSFunction;
    initBindingCallbacks = module['initBindingCallbacks'] as js.JSFunction;
    deleteDashPathEffect = module['_deleteDashPathEffect'] as js.JSFunction;
    makeDashPathEffect = module['_makeDashPathEffect'] as js.JSFunction;
    dashPathEffectGetOffset =
        module['_dashPathEffectGetOffset'] as js.JSFunction;
    dashPathEffectGetPathLength =
        module['_dashPathEffectGetPathLength'] as js.JSFunction;
    dashPathEffectSetOffset =
        module['_dashPathEffectSetOffset'] as js.JSFunction;
    dashPathEffectGetOffsetIsPercentage =
        module['_dashPathEffectGetOffsetIsPercentage'] as js.JSFunction;
    dashPathEffectSetOffsetIsPercentage =
        module['_dashPathEffectSetOffsetIsPercentage'] as js.JSFunction;
    dashPathClearDashes = module['_dashPathClearDashes'] as js.JSFunction;
    dashPathAddDash = module['_dashPathAddDash'] as js.JSFunction;
    dashPathInvalidate = module['_dashPathInvalidate'] as js.JSFunction;
    dashPathEffectPath = module['_dashPathEffectPath'] as js.JSFunction;
    renderPathColinearCheck =
        module['_renderPathColinearCheck'] as js.JSFunction;
    renderPathPreciseBounds =
        module['_renderPathPreciseBounds'] as js.JSFunction;
    renderPathPreciseLength =
        module['_renderPathPreciseLength'] as js.JSFunction;
    renderPathBounds = module['_renderPathBounds'] as js.JSFunction;
    renderPathIsClosed = module['_renderPathIsClosed'] as js.JSFunction;
    renderPathHasBounds = module['_renderPathHasBounds'] as js.JSFunction;
    renderPathCopyBuffers = module['_renderPathCopyBuffers'] as js.JSFunction;
    renderPathIsClockwise = module['_renderPathIsClockwise'] as js.JSFunction;

    makeRawText = module['_makeRawText'] as js.JSFunction;
    deleteRawText = module['_deleteRawText'] as js.JSFunction;
    rawTextAppend = module['_rawTextAppend'] as js.JSFunction;
    rawTextClear = module['_rawTextClear'] as js.JSFunction;
    rawTextIsEmpty = module['_rawTextIsEmpty'] as js.JSFunction;
    rawTextGetSizing = module['_rawTextGetSizing'] as js.JSFunction;
    rawTextSetSizing = module['_rawTextSetSizing'] as js.JSFunction;
    rawTextGetOverflow = module['_rawTextGetOverflow'] as js.JSFunction;
    rawTextSetOverflow = module['_rawTextSetOverflow'] as js.JSFunction;
    rawTextGetAlign = module['_rawTextGetAlign'] as js.JSFunction;
    rawTextSetAlign = module['_rawTextSetAlign'] as js.JSFunction;
    rawTextGetMaxWidth = module['_rawTextGetMaxWidth'] as js.JSFunction;
    rawTextSetMaxWidth = module['_rawTextSetMaxWidth'] as js.JSFunction;
    rawTextGetMaxHeight = module['_rawTextGetMaxHeight'] as js.JSFunction;
    rawTextSetMaxHeight = module['_rawTextSetMaxHeight'] as js.JSFunction;
    rawTextGetParagraphSpacing =
        module['_rawTextGetParagraphSpacing'] as js.JSFunction;
    rawTextSetParagraphSpacing =
        module['_rawTextSetParagraphSpacing'] as js.JSFunction;
    rawTextBounds = module['_rawTextBounds'] as js.JSFunction;
    rawTextRender = module['_rawTextRender'] as js.JSFunction;
  }
}

/// Extension method for converting a [String] to a WASM heap backed string.
extension StringUtf8Wasm on String {
  /// Creates a zero-terminated [Utf8] code-unit array from this String.
  WasmBuffer toWasmUtf8() {
    final units = utf8.encode(this);
    var buffer = WasmBuffer(units.length + 1);
    buffer.data.setRange(0, units.length, units);
    buffer.data[units.length] = 0;
    return buffer;
  }
}

class _WebRiveNative extends RiveNative {
  @override
  RenderTexture makeRenderTexture() => _WebRenderTexture.make();
}

bool get isRuntimeEnvironment =>
    const String.fromEnvironment('RIVE_ENVIRONMENT', defaultValue: 'runtime') ==
    'runtime';

bool get isLocalEnvironment =>
    const bool.fromEnvironment('LOCAL_RIVE_NATIVE', defaultValue: false);

const wasmHost = bool.hasEnvironment("RIVE_NATIVE_WASM_HOST")
    ? String.fromEnvironment("RIVE_NATIVE_WASM_HOST")
    : null;

String _wasmHost() {
  if (wasmHost != null) {
    return wasmHost!;
  }
  if (isLocalEnvironment) {
    return 'http://localhost:8282/release/';
  } else if (isRuntimeEnvironment) {
    return 'https://cdn.jsdelivr.net/npm/@rive-app/'
        'flutter-native-wasm@$wasmVersion/';
  }
  return '';
}

Future<RiveNative?> _loadWasm(String source, String name) async {
  var script = html.HTMLScriptElement()
    ..src = _wasmHost() + source
    ..type = 'application/javascript'
    ..defer = true;

  html.document.body!.append(script);
  await script.onLoad.first;
  var initWasm = js.globalContext[name] as js.JSFunction;
  var promise = initWasm.callAsFunction() as js.JSObject;
  var thenFunction = promise['then'] as js.JSFunction;

  var completer = Completer<RiveNative?>();
  thenFunction.callAsFunction(
    promise,
    (js.JSObject module) {
      RiveWasm.link(module);
      LayoutEngineWasm.link(module);
      if (!isRuntimeEnvironment) {
        // Add scripting workspace for the Editor
        ScriptingWorkspaceWasm.link(module);
      }
      TextEngine.link(module);
      AudioEngineWasm.link(module);
      completer.complete(_WebRiveNative());
    }.toJS,
    ((js.JSObject error) => completer.complete(null)).toJS,
  );
  return completer.future;
}

Future<RiveNative?> makeRiveNative() async {
  RiveNative? result;

  if ((result = await _loadWasm('wasm/rive_native.js', 'RiveNative')) != null) {
    return result;
  }
  if ((result = await _loadWasm(
        'wasm_compatibility/rive_native.js',
        'RiveNative',
      )) !=
      null) {
    return result;
  }
  return null;
}

class _RiveNativeWebView extends LeafRenderObjectWidget {
  final _WebRenderTexture renderTexture;
  // final _NativeRenderTexture renderTexture;
  final RenderTexturePainter? painter;
  const _RiveNativeWebView(this.renderTexture, this.painter, {super.key});

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RiveNativeWebViewRenderObject(renderTexture, painter)
      ..devicePixelRatio = MediaQuery.devicePixelRatioOf(context)
      ..tickerModeEnabled = TickerMode.of(context);
  }

  @override
  void updateRenderObject(
    BuildContext context,
    covariant _RiveNativeWebViewRenderObject renderObject,
  ) {
    renderObject
      ..renderTexture = renderTexture
      ..painter = painter
      ..devicePixelRatio = MediaQuery.devicePixelRatioOf(context)
      ..tickerModeEnabled = TickerMode.of(context);
  }

  @override
  void didUnmountRenderObject(
    covariant _RiveNativeWebViewRenderObject renderObject,
  ) {
    renderObject.painter = null;
  }
}

class _RiveNativeWebViewRenderObject
    extends RiveNativeRenderBox<RenderTexturePainter> {
  _WebRenderTexture _renderTexture;

  _RiveNativeWebViewRenderObject(
    this._renderTexture,
    RenderTexturePainter? renderTexturePainter,
  ) {
    painter = renderTexturePainter;
  }

  @override
  bool get shouldAdvance => _shouldAdvance;
  bool _shouldAdvance = false;

  @override
  void frameCallback(Duration duration) {
    super.frameCallback(duration);
    _paintTexture();
  }

  void _paintTexture() {
    final painter = rivePainter;
    if (painter == null || !renderTexture.isReady || !hasSize) {
      return;
    }
    // Question (Gordon): Why is this not using the devicePixelRatio from the
    // render object?
    final devicePixelRatio = html.window.devicePixelRatio;
    final width = (size.width * devicePixelRatio).roundToDouble();
    final height = (size.height * devicePixelRatio).roundToDouble();
    _renderTexture.clear(painter.background);
    _shouldAdvance = painter.paint(
      _renderTexture,
      devicePixelRatio.toDouble(),
      Size(width, height),
      elapsedSeconds,
    );
    _renderTexture.flush(devicePixelRatio.toDouble());
    if (painter.paintsCanvas) {
      markNeedsPaint();
    }
  }

  _WebRenderTexture get renderTexture => _renderTexture;
  set renderTexture(_WebRenderTexture value) {
    if (_renderTexture == value) {
      return;
    }
    _renderTexture = value;
    markNeedsPaint();
  }

  @override
  void performLayout() {
    super.performLayout();
    _paintTexture();

    // var width = (size.width * html.window.devicePixelRatio).round();
    // var height = (size.height * html.window.devicePixelRatio).round();
    // var canvas = _renderTexture.canvasElement;
    // if (canvas.width != width || canvas.height != height) {
    //   canvas.width = width;
    //   canvas.height = height;
    //   var renderer = _makeRenderer.callAsFunction(
    //     null,
    //     width.toJS,
    //     height.toJS,
    //   );
    //   print('renderr is $renderer');
    // }
  }

  @override
  Size computeDryLayout(BoxConstraints constraints) => constraints.smallest;

  @override
  void paint(PaintingContext context, Offset offset) {
    var painter = rivePainter;
    if (painter != null && painter.paintsCanvas) {
      painter.paintCanvas(context.canvas, offset, size);
    }
  }
}
