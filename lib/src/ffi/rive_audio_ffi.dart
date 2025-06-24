import 'dart:async';
import 'dart:collection';
import 'dart:ffi';

import 'package:flutter/foundation.dart';
import 'package:rive_native/rive_audio.dart';
import 'package:rive_native/src/ffi/dynamic_library_helper.dart';

final DynamicLibrary _nativeLib = DynamicLibraryHelper.nativeLib;

final Pointer<Void> Function(
  int numChannels,
  int sampleRate,
) makeAudioEngine = _nativeLib
    .lookup<
        NativeFunction<
            Pointer<Void> Function(
              Uint32,
              Uint32,
            )>>('makeAudioEngine')
    .asFunction();

final int Function(
  Pointer<Void> engine,
) engineTime = _nativeLib
    .lookup<
        NativeFunction<
            Uint64 Function(
              Pointer<Void>,
            )>>('engineTime')
    .asFunction();

final void Function(
  Pointer<Void> engine,
) engineInitLevelMonitor = _nativeLib
    .lookup<
        NativeFunction<
            Void Function(
              Pointer<Void>,
            )>>('engineInitLevelMonitor')
    .asFunction();

final double Function(Pointer<Void> engine, int channel) engineLevel =
    _nativeLib
        .lookup<
            NativeFunction<
                Float Function(
                  Pointer<Void>,
                  Uint32,
                )>>('engineLevel')
        .asFunction();

final int Function(
  Pointer<Void> engine,
) engineNumChannels = _nativeLib
    .lookup<
        NativeFunction<
            Uint32 Function(
              Pointer<Void>,
            )>>('numChannels')
    .asFunction();

final int Function(
  Pointer<Void> engine,
) engineSampleRate = _nativeLib
    .lookup<
        NativeFunction<
            Uint32 Function(
              Pointer<Void>,
            )>>('sampleRate')
    .asFunction();

final int Function(
  Pointer<Void> engine,
) audioSourceNumChannels = _nativeLib
    .lookup<
        NativeFunction<
            Uint32 Function(
              Pointer<Void>,
            )>>('audioSourceNumChannels')
    .asFunction();

final int Function(
  Pointer<Void> engine,
) audioSourceSampleRate = _nativeLib
    .lookup<
        NativeFunction<
            Uint32 Function(
              Pointer<Void>,
            )>>('audioSourceSampleRate')
    .asFunction();

final int Function(
  Pointer<Void> engine,
) audioSourceFormat = _nativeLib
    .lookup<
        NativeFunction<
            Uint32 Function(
              Pointer<Void>,
            )>>('audioSourceFormat')
    .asFunction();

final void Function(
  Pointer<Void> engine,
) unrefAudioEngine = _nativeLib
    .lookup<
        NativeFunction<
            Void Function(
              Pointer<Void>,
            )>>('unrefAudioEngine')
    .asFunction();

final void Function(
  Pointer<Void> engine,
) unrefAudioSound = _nativeLib
    .lookup<
        NativeFunction<
            Void Function(
              Pointer<Void>,
            )>>('unrefAudioSound')
    .asFunction();

final Pointer<SimpleUint8Array> Function(
  int length,
) makeAudioSourceBuffer = _nativeLib
    .lookup<
        NativeFunction<
            Pointer<SimpleUint8Array> Function(
              Uint64,
            )>>('makeAudioSourceBuffer')
    .asFunction();

final Pointer<Void> Function(
  Pointer<SimpleUint8Array>,
) makeAudioSource = _nativeLib
    .lookup<
        NativeFunction<
            Pointer<Void> Function(
              Pointer<SimpleUint8Array>,
            )>>('makeAudioSource')
    .asFunction();

final Pointer<Void> Function(
  Pointer<Void> nativeAudioSource,
  Pointer<Void> engine,
  int,
  int,
  int,
) playAudioSource = _nativeLib
    .lookup<
        NativeFunction<
            Pointer<Void> Function(
              Pointer<Void>,
              Pointer<Void>,
              Uint64,
              Uint64,
              Uint64,
            )>>('playAudioSource')
    .asFunction();

final void Function(
  Pointer<Void>,
  int,
) stopAudioSound = _nativeLib
    .lookup<
        NativeFunction<
            Void Function(
              Pointer<Void>,
              Uint64,
            )>>('stopAudioSound')
    .asFunction();

final double Function(
  Pointer<Void>,
) getSoundVolume = _nativeLib
    .lookup<
        NativeFunction<
            Float Function(
              Pointer<Void>,
            )>>('getSoundVolume')
    .asFunction();

final bool Function(
  Pointer<Void>,
) getSoundCompleted = _nativeLib
    .lookup<
        NativeFunction<
            Bool Function(
              Pointer<Void>,
            )>>('getSoundCompleted')
    .asFunction();

final void Function(
  Pointer<Void>,
  double,
) setSoundVolume = _nativeLib
    .lookup<
        NativeFunction<
            Void Function(
              Pointer<Void>,
              Float,
            )>>('setSoundVolume')
    .asFunction();

final void Function(
  Pointer<Void> nativeAudioSource,
) unrefAudioSource = _nativeLib
    .lookup<
        NativeFunction<
            Void Function(
              Pointer<Void>,
            )>>('unrefAudioSource')
    .asFunction();

final Pointer<Void> Function(
  Pointer<Void> source,
  int,
  int,
) makeAudioReader = _nativeLib
    .lookup<
        NativeFunction<
            Pointer<Void> Function(
              Pointer<Void>,
              Uint32,
              Uint32,
            )>>('makeAudioReader')
    .asFunction();

final SamplesSpan Function(
  Pointer<Void> reader,
) audioReaderRead = _nativeLib
    .lookup<NativeFunction<SamplesSpan Function(Pointer<Void>)>>(
        'audioReaderRead')
    .asFunction();

final Pointer<Void> Function(
  Pointer<Void> decodeWork,
  int,
  int,
) makeBufferedAudioSource = _nativeLib
    .lookup<
        NativeFunction<
            Pointer<Void> Function(
              Pointer<Void>,
              Uint32,
              Uint32,
            )>>('makeBufferedAudioSource')
    .asFunction();

final SamplesSpan Function(
  Pointer<Void> audioSource,
) bufferedAudioSamples = _nativeLib
    .lookup<NativeFunction<SamplesSpan Function(Pointer<Void>)>>(
        'bufferedAudioSamples')
    .asFunction();

final void Function(
  Pointer<Void> nativeAudioSource,
) unrefAudioReader = _nativeLib
    .lookup<
        NativeFunction<
            Void Function(
              Pointer<Void>,
            )>>('unrefAudioReader')
    .asFunction();

final int Function(
  Pointer<Void> nativeAudioSource,
) audioReaderLength = _nativeLib
    .lookup<
        NativeFunction<
            Uint64 Function(
              Pointer<Void>,
            )>>('audioReaderLength')
    .asFunction();

AudioEngine? initAudioDevice(int channels, int sampleRate) {
  var engine = makeAudioEngine(
    channels,
    sampleRate,
  );

  if (engine == nullptr) {
    return null;
  }
  return AudioEngineFFI(
    engine,
    channels: engineNumChannels(engine),
    sampleRate: engineSampleRate(engine),
  );
}

StreamingAudioSource loadAudioSource(Uint8List bytes) {
  var buffer = makeAudioSourceBuffer(bytes.length);
  var data = buffer.ref.data;
  for (int i = 0; i < bytes.length; i++) {
    data[i] = bytes[i];
  }

  var audioSourcePointer = makeAudioSource(buffer);

  return StreamingAudioSourceFFI(audioSourcePointer);
}

class AudioSoundFFI extends AudioSound {
  Pointer<Void> nativePtr;
  int sampleRate;
  AudioSoundFFI(this.nativePtr, this.sampleRate);

  @override
  void stop({Duration fadeTime = Duration.zero}) {
    stopAudioSound(
        nativePtr, (fadeTime.inMicroseconds * 1e-6 * sampleRate).round());
  }

  @override
  void dispose() {
    unrefAudioSound(nativePtr);
    nativePtr = nullptr;
  }

  @override
  double get volume => getSoundVolume(nativePtr);

  @override
  set volume(double value) => setSoundVolume(nativePtr, value);

  @override
  bool get completed => getSoundCompleted(nativePtr);
}

class AudioEngineFFI extends AudioEngine {
  Pointer<Void> nativePtr;

  static HashMap<int, AudioEngineFFI> lookup = HashMap<int, AudioEngineFFI>();

  @override
  final int channels;

  @override
  final int sampleRate;

  AudioEngineFFI(
    this.nativePtr, {
    required this.channels,
    required this.sampleRate,
  }) {
    lookup[nativePtr.address] = this;
  }

  @override
  void dispose() {
    lookup.remove(nativePtr.address);
    var p = nativePtr;
    nativePtr = nullptr;
    unrefAudioEngine(p);
  }

  @override
  int get timeInFrames => engineTime(nativePtr);

  @override
  AudioSound play(AudioSource source, int engineStartTime, int engineEndTime,
      int soundStartTime) {
    if (source is! AudioSourceFFI) {
      throw UnsupportedError('Tried to play an unsupported AudioSource.');
    }
    return AudioSoundFFI(
      playAudioSource(
        (source as AudioSourceFFI).nativePtr,
        nativePtr,
        engineStartTime,
        engineEndTime,
        soundStartTime,
      ),
      sampleRate,
    );
  }

  @override
  void monitorLevels() => engineInitLevelMonitor(nativePtr);

  @override
  double level(int channel) => engineLevel(nativePtr, channel);
}

final class SimpleUint8Array extends Struct {
  external Pointer<Uint8> data;
  @Size()
  external int size;
}

final class SamplesSpan extends Struct {
  external Pointer<Float> samples;
  @Uint64()
  external int sampleCount;
}

mixin AudioSourceFFI {
  Pointer<Void> get nativePtr;
  set nativePtr(Pointer<Void> value);
  int get sampleRate => audioSourceSampleRate(nativePtr);
  int get channels => audioSourceNumChannels(nativePtr);

  AudioFormat get format => AudioFormat.values[audioSourceFormat(nativePtr)];

  void dispose() {
    unrefAudioSource(nativePtr);
    nativePtr = nullptr;
  }
}

class BufferedAudioSourceFFI extends BufferedAudioSource with AudioSourceFFI {
  @override
  Pointer<Void> nativePtr;

  BufferedAudioSourceFFI(
    this.nativePtr,
    this.length,
    this.samples,
  );

  @override
  final int length;

  @override
  final Float32List samples;
}

class StreamingAudioSourceFFI extends StreamingAudioSource with AudioSourceFFI {
  @override
  Pointer<Void> nativePtr;

  @override
  int get sampleRate => audioSourceSampleRate(nativePtr);

  @override
  int get channels => audioSourceNumChannels(nativePtr);

  StreamingAudioSourceFFI(this.nativePtr);

  @override
  void dispose() {
    unrefAudioSource(nativePtr);
    nativePtr = nullptr;
  }

  static int _bufferingCount = 0;
  @visibleForTesting
  static bool get isBuffering => _bufferingCount > 0;

  @override
  Future<BufferedAudioSource> makeBuffered({int? channels, int? sampleRate}) {
    _bufferingCount++;
    var decodeChannels = channels ?? this.channels;
    var decodeWorkPtr = makeAudioReader(
      nativePtr,
      decodeChannels,
      sampleRate ?? this.sampleRate,
    );
    final completer = Completer<BufferedAudioSource>();
    Timer.periodic(
      const Duration(milliseconds: 10),
      (timer) {
        var samplesSpan = audioReaderRead(decodeWorkPtr);
        if (samplesSpan.samples != nullptr) {
          timer.cancel();

          var nativeBufferedSource = makeBufferedAudioSource(
            decodeWorkPtr,
            decodeChannels,
            sampleRate ?? this.sampleRate,
          );

          // Decode worker can be nuked now.
          unrefAudioReader(decodeWorkPtr);

          var samplesSpan = bufferedAudioSamples(nativeBufferedSource);

          _bufferingCount--;
          completer.complete(
            BufferedAudioSourceFFI(
              nativeBufferedSource,
              samplesSpan.sampleCount ~/ decodeChannels,
              samplesSpan.samples.asTypedList(samplesSpan.sampleCount),
            ),
          );
        }
      },
    );
    return completer.future;
  }

  @override
  AudioFormat get format => AudioFormat.values[audioSourceFormat(nativePtr)];
}
