import 'package:get_it/get_it.dart';

import 'features/prime_calculator/data/datasources/prime_isolate_datasource.dart';
import 'features/prime_calculator/data/repositories/prime_repository_impl.dart';
import 'features/prime_calculator/domain/repositories/prime_repository.dart';
import 'features/prime_calculator/domain/usecases/calculate_primes.dart';
import 'features/prime_calculator/domain/usecases/cancel_calculation.dart';
import 'features/prime_calculator/presentation/bloc/prime_bloc.dart';

final GetIt sl = GetIt.instance;

/// Wires up every layer for the prime_calculator feature.
/// Call once from `main()` before `runApp`.
void setupInjection() {
  // Presentation
  sl.registerFactory(
    () => PrimeBloc(calculatePrimes: sl(), cancelCalculation: sl()),
  );

  // Domain
  sl.registerLazySingleton(() => CalculatePrimes(sl()));
  sl.registerLazySingleton(() => CancelCalculation(sl()));

  // Data
  sl.registerLazySingleton<PrimeRepository>(() => PrimeRepositoryImpl(sl()));
  sl.registerLazySingleton(() => PrimeIsolateDataSource());
}
