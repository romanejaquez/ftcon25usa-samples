import 'package:flutter/foundation.dart';

import 'src/ffi/rive_audio_ffi.dart'
    if (dart.library.js_interop) 'src/web/rive_audio_web.dart';

enum AudioFormat { unknown, wav, flac, mp3, vorbis, buffered }

abstract class AudioEngine {
  static const playbackSampleRate = 44100;
  static AudioEngine? init(int channels, int sampleRate) {
    return initAudioDevice(channels, sampleRate);
  }

  static StreamingAudioSource loadSource(Uint8List bytes) {
    return loadAudioSource(bytes);
  }

  void dispose();

  /// Sample rate in hz.
  int get sampleRate;

  /// Number of channels.
  int get channels;

  /// Current playback time in frames.
  int get timeInFrames;

  AudioSound play(
    AudioSource source,
    int engineStartTime,
    int engineEndTime,
    int soundStartTime,
  );

  /// Start monitoring levels.
  void monitorLevels();

  /// Get the current level of a channel.
  double level(int channel);
}

abstract class AudioSound {
  void stop({Duration fadeTime = Duration.zero});
  double get volume;
  set volume(double value);
  void dispose();
  bool get completed;
}

abstract class AudioSource {
  /// Sample rate in hz. This is native stream's sample rate.
  int get sampleRate;

  /// Number of channels. This is native stream's number of channels.
  int get channels;

  /// Retrieves the format of the audio source.
  AudioFormat get format;

  void dispose();
}

abstract class StreamingAudioSource extends AudioSource {
  Future<BufferedAudioSource> makeBuffered({int? channels, int? sampleRate});
}

abstract class BufferedAudioSource extends AudioSource {
  Float32List get samples;

  /// Length in samples.
  int get length;

  Duration get duration =>
      Duration(microseconds: (length / sampleRate / 1e-6).floor());
}
