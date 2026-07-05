import 'package:equatable/equatable.dart';

/// Business-layer representation of what can happen while primes are
/// being calculated. This is pure Dart — it knows nothing about
/// isolates, ports, or messages. That knowledge is confined to the
/// data layer.
sealed class PrimeCalculationEvent extends Equatable {
  const PrimeCalculationEvent();
}

/// Emitted repeatedly while the background isolate is still working.
class PrimeProgressUpdate extends PrimeCalculationEvent {
  final int current;
  final double percentage;

  const PrimeProgressUpdate({required this.current, required this.percentage});

  @override
  List<Object?> get props => [current, percentage];
}

/// Emitted exactly once, when the isolate has finished.
class PrimeCalculationCompleted extends PrimeCalculationEvent {
  final List<int> primes;
  final int elapsedMs;

  const PrimeCalculationCompleted({required this.primes, required this.elapsedMs});

  @override
  List<Object?> get props => [primes, elapsedMs];
}
