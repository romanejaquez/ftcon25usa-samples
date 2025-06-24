import 'dart:async';
import 'dart:js_interop' as js;
import 'dart:js_interop_unsafe';
import 'dart:typed_data';

import 'package:rive_native/rive_audio.dart';

late js.JSFunction _makeAudioEngine;
late js.JSFunction _engineTime;
late js.JSFunction _numChannels;
late js.JSFunction _sampleRate;
late js.JSFunction _unrefAudioEngine;
late js.JSFunction _makeAudioSourceBuffer;
late js.JSFunction _simpleArrayData;
late js.JSFunction _makeAudioSource;
late js.JSFunction _makeAudioReader;
late js.JSFunction _audioReaderRead;
late js.JSFunction _unrefAudioSource;
late js.JSFunction _unrefAudioReader;
late js.JSFunction _playAudioSource;
late js.JSFunction _audioSourceNumChannels;
late js.JSFunction _audioSourceSampleRate;
late js.JSFunction _audioSourceFormat;
late js.JSFunction _unrefAudioSound;
late js.JSFunction _stopAudioSound;
late js.JSFunction _getSoundVolume;
late js.JSFunction _getSoundCompleted;
late js.JSFunction _setSoundVolume;
late js.JSFunction _engineInitLevelMonitor;
late js.JSFunction _engineLevel;
late js.JSFunction _makeBufferedAudioSource;
late js.JSFunction _bufferedAudioSamples;
late js.JSFunction _heapViewU8;
late js.JSFunction _heapViewF32;

mixin AudioSourceWasm {
  int get nativePtr;
  set nativePtr(int value);
  int get sampleRate =>
      (_audioSourceSampleRate.callAsFunction(null, nativePtr.toJS)
              as js.JSNumber)
          .toDartInt;
  int get channels =>
      (_audioSourceNumChannels.callAsFunction(null, nativePtr.toJS)
              as js.JSNumber)
          .toDartInt;

  AudioFormat get format => AudioFormat.values[
      (_audioSourceFormat.callAsFunction(null, nativePtr.toJS) as js.JSNumber)
          .toDartInt];

  void dispose() {
    _unrefAudioSource.callAsFunction(null, nativePtr.toJS);
    nativePtr = 0;
  }
}

class BufferedAudioSourceWasm extends BufferedAudioSource with AudioSourceWasm {
  @override
  int nativePtr;
  final int dataPtr;
  final int dataLength;
  BufferedAudioSourceWasm(
    this.nativePtr,
    this.dataLength,
    this.dataPtr,
  );

  @override
  int get length => dataLength ~/ channels;

  @override
  Float32List get samples =>
      AudioEngineWasm.wasmHeapFloat32(dataPtr, dataLength);
}

class StreamingAudioSourceWasm extends StreamingAudioSource
    with AudioSourceWasm {
  @override
  int nativePtr;

  StreamingAudioSourceWasm(
    this.nativePtr,
  );

  @override
  Future<BufferedAudioSource> makeBuffered({int? channels, int? sampleRate}) {
    var decodeWorkPtr = (_makeAudioReader.callAsFunction(
      null,
      nativePtr.toJS,
      (channels ?? this.channels).toJS,
      (sampleRate ?? this.sampleRate).toJS,
    ) as js.JSNumber)
        .toDartInt;
    final completer = Completer<BufferedAudioSource>();
    Timer.periodic(
      const Duration(milliseconds: 10),
      (timer) {
        var obj = _audioReaderRead.callAsFunction(null, decodeWorkPtr.toJS)
            as js.JSObject;
        var data = (obj['data'] as js.JSNumber).toDartInt;

        if (data != 0) {
          assert(data % 4 == 0);
          timer.cancel();

          var nativeBufferedSource = (_makeBufferedAudioSource.callAsFunction(
            null,
            decodeWorkPtr.toJS,
            (channels ?? this.channels).toJS,
            (sampleRate ?? this.sampleRate).toJS,
          ) as js.JSNumber)
              .toDartInt;

          // Decode worker can be nuked now.
          _unrefAudioReader.callAsFunction(null, decodeWorkPtr.toJS);

          var samplesSpan = _bufferedAudioSamples.callAsFunction(
              null, nativeBufferedSource.toJS) as js.JSObject;
          var samplesData = (samplesSpan['data'] as js.JSNumber).toDartInt;
          var samplesCount = (samplesSpan['count'] as js.JSNumber).toDartInt;
          assert(samplesData % 4 == 0);
          completer.complete(
            BufferedAudioSourceWasm(
              nativeBufferedSource,
              samplesCount,
              samplesData ~/ 4,
            ),
          );
        }
      },
    );
    return completer.future;
  }
}

class AudioSoundWasm extends AudioSound {
  int nativePtr;
  final int sampleRate;
  AudioSoundWasm(this.nativePtr, this.sampleRate);

  @override
  void stop({Duration fadeTime = Duration.zero}) {
    _stopAudioSound.callAsFunction(
      null,
      nativePtr.toJS,
      (fadeTime.inMicroseconds * 1e-6 * sampleRate).round().toJS,
    );
  }

  @override
  void dispose() {
    _unrefAudioSound.callAsFunction(
      null,
      nativePtr.toJS,
    );
    nativePtr = 0;
  }

  @override
  double get volume =>
      (_getSoundVolume.callAsFunction(null, nativePtr.toJS) as js.JSNumber)
          .toDartDouble;

  @override
  bool get completed =>
      (_getSoundCompleted.callAsFunction(null, nativePtr.toJS) as js.JSBoolean)
          .toDart;

  @override
  set volume(double value) =>
      _setSoundVolume.callAsFunction(null, nativePtr.toJS, value.toJS);
}

extension JSFunctionUtilExtension on js.JSFunction {
  @js.JS('call')
  external js.JSAny? callAsFunction([
    js.JSAny? thisArg,
    js.JSAny? arg1,
    js.JSAny? arg2,
    js.JSAny? arg3,
    js.JSAny? arg4,
    js.JSAny? arg5,
  ]);
}

class AudioEngineWasm extends AudioEngine {
  int nativePtr;
  static late js.JSObject module;

  @override
  final int channels;

  @override
  final int sampleRate;
  AudioEngineWasm(this.nativePtr,
      {required this.channels, required this.sampleRate});

  static void link(js.JSObject module) {
    AudioEngineWasm.module = module;
    _makeAudioEngine = module['makeAudioEngine'] as js.JSFunction;
    _engineTime = module['engineTime'] as js.JSFunction;
    _audioSourceNumChannels = module['audioSourceNumChannels'] as js.JSFunction;
    _audioSourceSampleRate = module['audioSourceSampleRate'] as js.JSFunction;
    _audioSourceFormat = module['audioSourceFormat'] as js.JSFunction;
    _numChannels = module['numChannels'] as js.JSFunction;
    _sampleRate = module['sampleRate'] as js.JSFunction;
    _unrefAudioEngine = module['unrefAudioEngine'] as js.JSFunction;
    _makeAudioSourceBuffer = module['makeAudioSourceBuffer'] as js.JSFunction;
    _simpleArrayData = module['simpleArrayData'] as js.JSFunction;
    _makeAudioSource = module['makeAudioSource'] as js.JSFunction;
    _makeAudioReader = module['makeAudioReader'] as js.JSFunction;
    _audioReaderRead = module['audioReaderRead'] as js.JSFunction;
    _unrefAudioSource = module['unrefAudioSource'] as js.JSFunction;
    _unrefAudioReader = module['unrefAudioReader'] as js.JSFunction;
    _playAudioSource = module['playAudioSource'] as js.JSFunction;
    _unrefAudioSound = module['unrefAudioSound'] as js.JSFunction;
    _stopAudioSound = module['stopAudioSound'] as js.JSFunction;
    _getSoundVolume = module['getSoundVolume'] as js.JSFunction;
    _getSoundCompleted = module['getSoundCompleted'] as js.JSFunction;
    _setSoundVolume = module['setSoundVolume'] as js.JSFunction;
    _engineInitLevelMonitor = module['engineInitLevelMonitor'] as js.JSFunction;
    _engineLevel = module['engineLevel'] as js.JSFunction;
    _makeBufferedAudioSource =
        module['makeBufferedAudioSource'] as js.JSFunction;
    _bufferedAudioSamples = module['bufferedAudioSamples'] as js.JSFunction;
    _heapViewU8 = module['heapViewU8'] as js.JSFunction;
    _heapViewF32 = module['heapViewF32'] as js.JSFunction;
  }

  @override
  void dispose() {
    _unrefAudioEngine.callAsFunction(null, nativePtr.toJS);
    nativePtr = 0;
  }

  static Uint8List wasmHeapUint8(int ptr, int length) =>
      (_heapViewU8.callAsFunction(null, ptr.toJS, length.toJS)
              as js.JSUint8Array)
          .toDart;

  static Float32List wasmHeapFloat32(int ptr, int length) =>
      (_heapViewF32.callAsFunction(null, ptr.toJS, length.toJS)
              as js.JSFloat32Array)
          .toDart;

  @override
  int get timeInFrames =>
      (_engineTime.callAsFunction(null, nativePtr.toJS) as js.JSNumber)
          .toDartInt;

  @override
  AudioSound play(AudioSource source, int engineStartTime, int engineEndTime,
      int soundStartTime) {
    if (source is! AudioSourceWasm) {
      throw UnsupportedError('Tried to play an unsupported AudioSource.');
    }
    return AudioSoundWasm(
      (_playAudioSource.callAsFunction(
        null,
        (source as AudioSourceWasm).nativePtr.toJS,
        nativePtr.toJS,
        engineStartTime.toJS,
        engineEndTime.toJS,
        soundStartTime.toJS,
      ) as js.JSNumber)
          .toDartInt,
      sampleRate,
    );
  }

  @override
  void monitorLevels() => _engineInitLevelMonitor.callAsFunction(
        null,
        nativePtr.toJS,
      );

  @override
  double level(int channel) =>
      (_engineLevel.callAsFunction(null, nativePtr.toJS, channel.toJS)
              as js.JSNumber)
          .toDartDouble;
}

StreamingAudioSource loadAudioSource(Uint8List bytes) {
  var simpleArrayUint8 = (_makeAudioSourceBuffer.callAsFunction(
          null, bytes.length.toJS) as js.JSNumber)
      .toDartInt;

  var data = AudioEngineWasm.wasmHeapUint8(
      (_simpleArrayData.callAsFunction(null, simpleArrayUint8.toJS)
              as js.JSNumber)
          .toDartInt,
      bytes.length);
  data.setAll(0, bytes);

  return StreamingAudioSourceWasm(
    (_makeAudioSource.callAsFunction(null, simpleArrayUint8.toJS)
            as js.JSNumber)
        .toDartInt,
  );
}

AudioEngine? initAudioDevice(int channels, int sampleRate) {
  var engine = (_makeAudioEngine.callAsFunction(
    null,
    channels.toJS,
    sampleRate.toJS,
  ) as js.JSNumber)
      .toDartInt;

  if (engine == 0) {
    return null;
  }
  return AudioEngineWasm(
    engine,
    channels: (_numChannels.callAsFunction(null, engine.toJS) as js.JSNumber)
        .toDartInt,
    sampleRate: (_sampleRate.callAsFunction(null, engine.toJS) as js.JSNumber)
        .toDartInt,
  );
}
