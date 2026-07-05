import 'package:flutter_test/flutter_test.dart';
import 'package:isolate_bloc_demo/features/prime_calculator/domain/entities/prime_calculation_event.dart';
import 'package:isolate_bloc_demo/features/prime_calculator/domain/repositories/prime_repository.dart';
import 'package:isolate_bloc_demo/features/prime_calculator/domain/usecases/calculate_primes.dart';

/// A fake repository that never touches an isolate. Because the
/// domain layer only depends on the [PrimeRepository] abstraction,
/// none of this test needs Flutter widgets or real isolates.
class _FakePrimeRepository implements PrimeRepository {
  @override
  Stream<PrimeCalculationEvent> calculatePrimes(int limit) async* {
    yield const PrimeProgressUpdate(current: 5, percentage: 0.5);
    yield const PrimeCalculationCompleted(primes: [2, 3, 5], elapsedMs: 10);
  }

  @override
  void cancelCalculation() {}
}

void main() {
  late CalculatePrimes useCase;

  setUp(() {
    useCase = CalculatePrimes(_FakePrimeRepository());
  });

  test('throws ArgumentError when limit is less than 2', () {
    expect(() => useCase(1), throwsArgumentError);
  });

  test('emits progress updates followed by a completion event', () async {
    final events = await useCase(10).toList();

    expect(events, [
      const PrimeProgressUpdate(current: 5, percentage: 0.5),
      const PrimeCalculationCompleted(primes: [2, 3, 5], elapsedMs: 10),
    ]);
  });
}
