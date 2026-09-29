import 'package:flutter/animation.dart';

/// The splash's timing, in seconds from the first frame, as the design's
/// keyframes write it (`btDraw`, `btPop`, `btFadeUp`, `btRing`, `btBar`).
/// One clock drives it all: [length] is when the design moves on.
class SplashTimeline {
  SplashTimeline._();

  static const Duration length = Duration(milliseconds: 3500);

  static const Cubic draw = Cubic(.6, 0, .2, 1);
  static const Cubic drop = Cubic(.3, 1.5, .5, 1);
  static const Cubic pop = Cubic(.3, 1.6, .5, 1);
  static const Cubic fadeUp = Cubic(.2, .7, .2, 1);

  static const double drawFor = .9;
  static const double dropFor = .5;
  static const double popFor = .55;
  static const double fadeFor = .7;
  static const double ringFor = 2.6;

  static const double roofAt = .25;
  static const double wallsAt = .55;
  static const double doorAt = .85;
  static const double awningAt = 1.1;
  static const double leafAt = 1.35;
  static const double birdAt = 1.55;
  static const double titleAt = 1.7;
  static const double capsAt = 1.95;
  static const double taglineAt = 2.2;

  /// The two rings, each repeating every [ringFor].
  static const List<double> ringsAt = [1.0, 2.3];

  static const double barAt = .2;
  static const double barFor = 3;

  /// Where [clock] (0–1 over [length]) is, in seconds.
  static double secondsOf(Animation<double> clock) =>
      clock.value * length.inMilliseconds / 1000;

  /// 0–1 through a step that starts at [start] and lasts [duration].
  static double progress(double seconds, double start, double duration) =>
      ((seconds - start) / duration).clamp(0.0, 1.0);

  /// [progress] through [curve]; 0 until the step starts. The pops
  /// overshoot past 1 on the way, as the design's springs do.
  static double eased(
    Curve curve,
    double seconds,
    double start,
    double duration,
  ) {
    final t = progress(seconds, start, duration);
    return t == 0 ? 0 : curve.transform(t);
  }
}
