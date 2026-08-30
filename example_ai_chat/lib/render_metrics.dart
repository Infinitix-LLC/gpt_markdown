import 'dart:math' as math;

import 'package:flutter/scheduler.dart';

/// Frame and throughput numbers for one streamed reply.
///
/// This is the point of the harness: a reply rendered through `GptMarkdown`
/// is only "fast" if the UI thread keeps up while the text grows, so the
/// numbers that matter are per-frame build+raster time during the stream, not
/// a stopwatch around the whole answer.
class RenderMetrics {
  RenderMetrics({
    required this.timeToFirstToken,
    required this.elapsed,
    required this.characters,
    required this.chunks,
    required this.frames,
    required this.avgFrameMs,
    required this.p95FrameMs,
    required this.worstFrameMs,
    required this.jankFrames,
  });

  const RenderMetrics.empty()
    : timeToFirstToken = null,
      elapsed = Duration.zero,
      characters = 0,
      chunks = 0,
      frames = 0,
      avgFrameMs = 0,
      p95FrameMs = 0,
      worstFrameMs = 0,
      jankFrames = 0;

  /// Latency until the first content delta arrived — network and model, not
  /// rendering. Shown so it is not mistaken for render cost.
  final Duration? timeToFirstToken;

  /// Wall clock from send to the end of the stream.
  final Duration elapsed;

  /// Characters of Markdown rendered.
  final int characters;

  /// Content deltas received — each one is a `GptMarkdown` rebuild.
  final int chunks;

  /// Frames produced while the reply was streaming.
  final int frames;

  /// Mean of build + raster across those frames, in milliseconds.
  final double avgFrameMs;

  /// 95th percentile frame — where a stutter shows up that the mean hides.
  final double p95FrameMs;

  final double worstFrameMs;

  /// Frames over 16.7 ms, i.e. dropped at 60 Hz.
  final int jankFrames;

  /// Characters per second across the whole stream.
  double get charsPerSecond {
    final ms = elapsed.inMilliseconds;
    return ms <= 0 ? 0 : characters * 1000 / ms;
  }

  /// Fraction of frames that missed the 60 Hz budget.
  double get jankRatio => frames == 0 ? 0 : jankFrames / frames;
}

/// Collects [FrameTiming] between [start] and [stop].
///
/// Frame timings arrive from the engine after the fact, so a short drain
/// window on [stop] keeps the last few frames of the reply from being lost.
class RenderMetricsRecorder {
  final List<double> _frameMs = [];
  Stopwatch? _watch;
  Duration? _firstToken;
  int _characters = 0;
  int _chunks = 0;
  bool _recording = false;

  bool get isRecording => _recording;

  void start() {
    _frameMs.clear();
    _firstToken = null;
    _characters = 0;
    _chunks = 0;
    _watch = Stopwatch()..start();
    if (!_recording) {
      _recording = true;
      SchedulerBinding.instance.addTimingsCallback(_onTimings);
    }
  }

  /// Records one arriving content delta.
  void onChunk(String delta, int totalCharacters) {
    _chunks++;
    _characters = totalCharacters;
    _firstToken ??= _watch?.elapsed;
  }

  /// Stops recording and returns the run's numbers.
  Future<RenderMetrics> stop() async {
    final watch = _watch;
    watch?.stop();
    // Let the engine deliver the timings for the frames just drawn.
    await Future<void>.delayed(const Duration(milliseconds: 120));
    if (_recording) {
      _recording = false;
      SchedulerBinding.instance.removeTimingsCallback(_onTimings);
    }
    return _snapshot(watch?.elapsed ?? Duration.zero);
  }

  /// The numbers so far, for the live readout during a stream.
  RenderMetrics get live => _snapshot(_watch?.elapsed ?? Duration.zero);

  void dispose() {
    if (_recording) {
      _recording = false;
      SchedulerBinding.instance.removeTimingsCallback(_onTimings);
    }
  }

  RenderMetrics _snapshot(Duration elapsed) {
    if (_frameMs.isEmpty) {
      return RenderMetrics(
        timeToFirstToken: _firstToken,
        elapsed: elapsed,
        characters: _characters,
        chunks: _chunks,
        frames: 0,
        avgFrameMs: 0,
        p95FrameMs: 0,
        worstFrameMs: 0,
        jankFrames: 0,
      );
    }
    final sorted = List<double>.from(_frameMs)..sort();
    final total = sorted.fold<double>(0, (a, b) => a + b);
    // Nearest-rank p95, clamped so a short run still points at a real sample.
    final index = math.min(
      sorted.length - 1,
      (sorted.length * 0.95).ceil() - 1,
    );
    return RenderMetrics(
      timeToFirstToken: _firstToken,
      elapsed: elapsed,
      characters: _characters,
      chunks: _chunks,
      frames: sorted.length,
      avgFrameMs: total / sorted.length,
      p95FrameMs: sorted[math.max(0, index)],
      worstFrameMs: sorted.last,
      jankFrames: sorted.where((ms) => ms > 16.7).length,
    );
  }

  void _onTimings(List<FrameTiming> timings) {
    for (final timing in timings) {
      final ms =
          (timing.buildDuration.inMicroseconds +
              timing.rasterDuration.inMicroseconds) /
          1000.0;
      _frameMs.add(ms);
    }
  }
}
