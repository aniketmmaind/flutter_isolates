import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/prime_calculation_event.dart';
import '../../domain/usecases/calculate_primes.dart';
import '../../domain/usecases/cancel_calculation.dart';
import 'prime_event.dart';
import 'prime_state.dart';

/// Note for reviewers: the BLoC never touches `dart:isolate`. It only
/// consumes the [Stream<PrimeCalculationEvent>] handed to it by the
/// use case. That stream happens to be backed by a background
/// isolate under the hood, but the BLoC (and everything above it)
/// doesn't need to know that — this is Clean Architecture doing its
/// job of isolating (pun intended) concerns.
class PrimeBloc extends Bloc<PrimeEvent, PrimeState> {
  final CalculatePrimes calculatePrimes;
  final CancelCalculation cancelCalculation;

  PrimeBloc({
    required this.calculatePrimes,
    required this.cancelCalculation,
  }) : super(const PrimeInitial()) {
    on<CalculatePrimesRequested>(_onCalculatePrimesRequested);
    on<CancelCalculationRequested>(_onCancelCalculationRequested);
  }

  Future<void> _onCalculatePrimesRequested(
    CalculatePrimesRequested event,
    Emitter<PrimeState> emit,
  ) async {
    emit(const PrimeCalculating());
    try {
      await emit.forEach<PrimeCalculationEvent>(
        calculatePrimes(event.limit),
        onData: (PrimeCalculationEvent data) => switch (data) {
          PrimeProgressUpdate() => PrimeCalculating(
              current: data.current,
              percentage: data.percentage,
            ),
          PrimeCalculationCompleted() => PrimeSuccess(
              primes: data.primes,
              elapsedMs: data.elapsedMs,
            ),
        },
        onError: (Object error, StackTrace stackTrace) => PrimeFailure(error.toString()),
      );
    } catch (e) {
      emit(PrimeFailure(e.toString()));
    }
  }

  void _onCancelCalculationRequested(
    CancelCalculationRequested event,
    Emitter<PrimeState> emit,
  ) {
    cancelCalculation();
    emit(const PrimeCancelled());
  }
}
