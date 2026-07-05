import '../entities/prime_calculation_event.dart';
import '../repositories/prime_repository.dart';

/// Single-responsibility use case: validates input and delegates to
/// the repository. Kept as a callable class (`call` method) so it can
/// be used as `calculatePrimes(limit)` from the BLoC, which is the
/// common Flutter Clean Architecture convention.
class CalculatePrimes {
  final PrimeRepository repository;

  const CalculatePrimes(this.repository);

  Stream<PrimeCalculationEvent> call(int limit) {
    if (limit < 2) {
      throw ArgumentError.value(limit, 'limit', 'Must be greater than or equal to 2');
    }
    return repository.calculatePrimes(limit);
  }
}
