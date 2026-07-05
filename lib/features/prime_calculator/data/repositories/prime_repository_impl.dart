import '../../domain/entities/prime_calculation_event.dart';
import '../../domain/repositories/prime_repository.dart';
import '../datasources/prime_isolate_datasource.dart';

/// Translates the raw `Map<String, dynamic>` messages coming out of
/// the isolate into strongly-typed [PrimeCalculationEvent]s. This is
/// the boundary where "isolate/message" concerns are converted into
/// "domain/entity" concerns.
class PrimeRepositoryImpl implements PrimeRepository {
  final PrimeIsolateDataSource dataSource;

  const PrimeRepositoryImpl(this.dataSource);

  @override
  Stream<PrimeCalculationEvent> calculatePrimes(int limit) async* {
    await for (final Map<String, dynamic> message in dataSource.calculate(limit)) {
      final String type = message[PrimeIsolateMessageKeys.type] as String;
      switch (type) {
        case PrimeIsolateMessageKeys.progress:
          yield PrimeProgressUpdate(
            current: message[PrimeIsolateMessageKeys.current] as int,
            percentage: message[PrimeIsolateMessageKeys.percentage] as double,
          );
          break;
        case PrimeIsolateMessageKeys.result:
          yield PrimeCalculationCompleted(
            primes: List<int>.from(message[PrimeIsolateMessageKeys.primes] as List),
            elapsedMs: message[PrimeIsolateMessageKeys.elapsedMs] as int,
          );
          break;
        default:
          throw StateError('Unknown isolate message type: $type');
      }
    }
  }

  @override
  void cancelCalculation() => dataSource.cancel();
}
