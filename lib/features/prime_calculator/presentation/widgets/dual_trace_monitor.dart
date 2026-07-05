import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// The centerpiece visual of the app: a scrolling two-lane trace,
/// styled like an oscilloscope readout, that makes the whole point of
/// the demo visible at a glance.
///
/// - The **UI THREAD** lane is a perfectly smooth sine wave, driven by
///   nothing but a frame ticker. It never distorts, because it never
///   has to share a thread with the prime search.
/// - The **WORKER ISOLATE** lane is flat while idle and turns into a
///   busy, spiky trace while [isBusy] is true — a stand-in for the
///   background isolate actually crunching numbers.
///
/// Both lanes repaint every frame via a raw [Ticker], independent of
/// the BLoC's state changes, which is exactly why the UI lane never
/// stutters even during a multi-second calculation.
class DualTraceMonitor extends StatefulWidget {
  final bool isBusy;
  final Color uiColor;
  final Color workerColor;
  final Color gridColor;
  final double height;

  const DualTraceMonitor({
    super.key,
    required this.isBusy,
    required this.uiColor,
    required this.workerColor,
    required this.gridColor,
    this.height = 130,
  });

  @override
  State<DualTraceMonitor> createState() => _DualTraceMonitorState();
}

class _DualTraceMonitorState extends State<DualTraceMonitor> with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  Duration _elapsed = Duration.zero;
  Duration _lastTick = Duration.zero;
  double _busyLevel = 0;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick)..start();
  }

  void _onTick(Duration elapsed) {
    final double dt = (elapsed - _lastTick).inMicroseconds / 1e6;
    _lastTick = elapsed;
    final double target = widget.isBusy ? 1.0 : 0.0;
    final double smoothing = (dt * 3.0).clamp(0.0, 1.0);
    setState(() {
      _elapsed = elapsed;
      _busyLevel += (target - _busyLevel) * smoothing;
    });
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double timeSeconds = _elapsed.inMicroseconds / 1e6;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _LaneLabel(
          color: widget.uiColor,
          title: 'UI THREAD',
          status: 'LIVE',
        ),
        SizedBox(
          height: widget.height / 2,
          width: double.infinity,
          child: CustomPaint(
            painter: _TracePainter(
              time: timeSeconds,
              busyLevel: 1.0,
              color: widget.uiColor,
              gridColor: widget.gridColor,
              mode: _TraceMode.smoothWave,
            ),
          ),
        ),
        const SizedBox(height: 10),
        _LaneLabel(
          color: widget.workerColor,
          title: 'WORKER ISOLATE',
          status: widget.isBusy ? 'ACTIVE' : 'IDLE',
        ),
        SizedBox(
          height: widget.height / 2,
          width: double.infinity,
          child: CustomPaint(
            painter: _TracePainter(
              time: timeSeconds,
              busyLevel: _busyLevel,
              color: widget.workerColor,
              gridColor: widget.gridColor,
              mode: _TraceMode.activitySpikes,
            ),
          ),
        ),
      ],
    );
  }
}

class _LaneLabel extends StatelessWidget {
  final Color color;
  final String title;
  final String status;

  const _LaneLabel({required this.color, required this.title, required this.status});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.4,
            ),
          ),
          const Spacer(),
          Text(
            status,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 11,
              color: Color(0xFF7C8AA6),
              letterSpacing: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}

enum _TraceMode { smoothWave, activitySpikes }

class _TracePainter extends CustomPainter {
  final double time;
  final double busyLevel;
  final Color color;
  final Color gridColor;
  final _TraceMode mode;

  _TracePainter({
    required this.time,
    required this.busyLevel,
    required this.color,
    required this.gridColor,
    required this.mode,
  });

  @override
  void paint(Canvas canvas, Size size) {
    _drawGrid(canvas, size);
    switch (mode) {
      case _TraceMode.smoothWave:
        _drawSmoothWave(canvas, size);
      case _TraceMode.activitySpikes:
        _drawActivitySpikes(canvas, size);
    }
  }

  void _drawGrid(Canvas canvas, Size size) {
    final Paint gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;
    const int columns = 10;
    for (int i = 1; i < columns; i++) {
      final double x = size.width * i / columns;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    canvas.drawLine(
      Offset(0, size.height / 2),
      Offset(size.width, size.height / 2),
      Paint()
        ..color = gridColor.withOpacity(0.7)
        ..strokeWidth = 1,
    );
  }

  void _drawSmoothWave(Canvas canvas, Size size) {
    const double amplitude = 0.32;
    const double frequency = 1.4;
    const double speed = 1.2;
    final double midY = size.height / 2;
    final double ampPx = size.height * amplitude;

    final Path path = Path();
    for (double x = 0; x <= size.width; x += 3) {
      final double phase = (x / size.width) * frequency * 2 * math.pi + time * speed;
      final double y = midY - math.sin(phase) * ampPx;
      if (x == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, _glowPaint());
    canvas.drawPath(path, _linePaint());
  }

  void _drawActivitySpikes(Canvas canvas, Size size) {
    const double barWidth = 5;
    const double scrollSpeed = 34;
    final double offset = time * scrollSpeed;
    final double midY = size.height / 2;
    const double baselineAmpFraction = 0.05;
    const double maxAmpFraction = 0.42;
    final double ampPx = size.height * (baselineAmpFraction + (maxAmpFraction - baselineAmpFraction) * busyLevel);

    final Path path = Path();
    bool started = false;
    for (double x = 0; x <= size.width; x += barWidth) {
      final int bucket = ((x + offset) / barWidth).floor();
      final double n = _pseudoRandom(bucket);
      final double y = midY - n * ampPx;
      if (!started) {
        path.moveTo(x, midY);
        started = true;
      }
      path.lineTo(x, y);
      path.lineTo(x + barWidth * 0.7, y);
      path.lineTo(x + barWidth * 0.7, midY);
    }

    canvas.drawPath(path, _glowPaint());
    canvas.drawPath(path, _linePaint());
  }

  Paint _linePaint() {
    return Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
  }

  Paint _glowPaint() {
    return Paint()
      ..color = color.withOpacity(0.35)
      ..strokeWidth = 6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
  }

  /// Deterministic pseudo-random hash so the same bucket index always
  /// produces the same height (classic GLSL-style sine hash),
  /// avoiding the need to keep a growing sample buffer around.
  double _pseudoRandom(int seed) {
    final double n = math.sin(seed * 12.9898) * 43758.5453;
    return n - n.floorToDouble();
  }

  @override
  bool shouldRepaint(covariant _TracePainter oldDelegate) => true;
}
