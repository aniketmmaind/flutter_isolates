import 'package:equatable/equatable.dart';

sealed class PrimeState extends Equatable {
  const PrimeState();

  @override
  List<Object?> get props => [];
}

class PrimeInitial extends PrimeState {
  const PrimeInitial();
}

class PrimeCalculating extends PrimeState {
  final int current;
  final double percentage;

  const PrimeCalculating({this.current = 0, this.percentage = 0});

  @override
  List<Object?> get props => [current, percentage];
}

class PrimeSuccess extends PrimeState {
  final List<int> primes;
  final int elapsedMs;

  const PrimeSuccess({required this.primes, required this.elapsedMs});

  @override
  List<Object?> get props => [primes, elapsedMs];
}

class PrimeFailure extends PrimeState {
  final String message;

  const PrimeFailure(this.message);

  @override
  List<Object?> get props => [message];
}

class PrimeCancelled extends PrimeState {
  const PrimeCancelled();
}
