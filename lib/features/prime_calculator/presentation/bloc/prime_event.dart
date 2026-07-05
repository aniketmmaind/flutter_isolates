import 'package:equatable/equatable.dart';

sealed class PrimeEvent extends Equatable {
  const PrimeEvent();

  @override
  List<Object?> get props => [];
}

class CalculatePrimesRequested extends PrimeEvent {
  final int limit;

  const CalculatePrimesRequested(this.limit);

  @override
  List<Object?> get props => [limit];
}

class CancelCalculationRequested extends PrimeEvent {
  const CancelCalculationRequested();
}
