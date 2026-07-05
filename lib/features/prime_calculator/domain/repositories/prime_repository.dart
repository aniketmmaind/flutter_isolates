import '../entities/prime_calculation_event.dart';

/// Contract the domain layer relies on. The data layer decides *how*
/// primes are calculated (in this demo: on a background isolate);
/// the domain layer only cares about the stream of events it gets back.
abstract class PrimeRepository {
  /// Streams progress updates followed by a single completion event
  /// while primes up to [limit] are calculated off the UI thread.
  Stream<PrimeCalculationEvent> calculatePrimes(int limit);

  /// Cancels any calculation in progress and tears down the isolate.
  void cancelCalculation();
}
