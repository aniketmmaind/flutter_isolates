import '../repositories/prime_repository.dart';

class CancelCalculation {
  final PrimeRepository repository;

  const CancelCalculation(this.repository);

  void call() => repository.cancelCalculation();
}
