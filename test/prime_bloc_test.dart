import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isolate_bloc_demo/features/prime_calculator/domain/entities/prime_calculation_event.dart';
import 'package:isolate_bloc_demo/features/prime_calculator/domain/repositories/prime_repository.dart';
import 'package:isolate_bloc_demo/features/prime_calculator/domain/usecases/calculate_primes.dart';
import 'package:isolate_bloc_demo/features/prime_calculator/domain/usecases/cancel_calculation.dart';
import 'package:isolate_bloc_demo/features/prime_calculator/presentation/bloc/prime_bloc.dart';
import 'package:isolate_bloc_demo/features/prime_calculator/presentation/bloc/prime_event.dart';
import 'package:isolate_bloc_demo/features/prime_calculator/presentation/bloc/prime_state.dart';

class _FakePrimeRepository implements PrimeRepository {
  bool cancelled = false;

  @override
  Stream<PrimeCalculationEvent> calculatePrimes(int limit) async* {
    yield const PrimeProgressUpdate(current: 1, percentage: 0.1);
    yield const PrimeCalculationCompleted(primes: [2, 3], elapsedMs: 5);
  }

  @override
  void cancelCalculation() {
    cancelled = true;
  }
}

void main() {
  late _FakePrimeRepository repository;

  setUp(() {
    repository = _FakePrimeRepository();
  });

  PrimeBloc buildBloc() => PrimeBloc(
        calculatePrimes: CalculatePrimes(repository),
        cancelCalculation: CancelCalculation(repository),
      );

  blocTest<PrimeBloc, PrimeState>(
    'emits [Calculating, Calculating(progress), Success] on CalculatePrimesRequested',
    build: buildBloc,
    act: (bloc) => bloc.add(const CalculatePrimesRequested(10)),
    expect: () => [
      const PrimeCalculating(),
      const PrimeCalculating(current: 1, percentage: 0.1),
      const PrimeSuccess(primes: [2, 3], elapsedMs: 5),
    ],
  );

  blocTest<PrimeBloc, PrimeState>(
    'emits [Cancelled] and calls repository.cancelCalculation on CancelCalculationRequested',
    build: buildBloc,
    act: (bloc) => bloc.add(const CancelCalculationRequested()),
    expect: () => [const PrimeCancelled()],
    verify: (_) => expect(repository.cancelled, isTrue),
  );
}
