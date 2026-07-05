import 'dart:isolate';

import '../../../../core/isolate/isolate_manager.dart';

/// Keys used in the plain `Map<String, dynamic>` messages exchanged
/// with the isolate. Only primitive/transferable types can cross the
/// isolate boundary, so we deliberately avoid sending custom classes.
abstract class PrimeIsolateMessageKeys {
  static const String type = 'type';
  static const String progress = 'progress';
  static const String result = 'result';
  static const String current = 'current';
  static const String percentage = 'percentage';
  static const String primes = 'primes';
  static const String elapsedMs = 'elapsedMs';
}

/// Data source responsible for running the prime search on a
/// background isolate and exposing the raw messages as a stream.
///
/// This is the *only* class in the whole app that knows about
/// isolates directly — everything above it (repository, use case,
/// BLoC, UI) only deals with domain entities.
class PrimeIsolateDataSource {
  IsolateManager? _manager;

  Stream<Map<String, dynamic>> calculate(int limit) async* {
    final IsolateManager manager = IsolateManager();
    _manager = manager;

    await manager.spawn(_primeIsolateEntryPoint);
    await manager.ready;
    manager.send(<String, dynamic>{'limit': limit});

    await for (final dynamic message in manager.messages) {
      final Map<String, dynamic> data = Map<String, dynamic>.from(message as Map);
      yield data;
      if (data[PrimeIsolateMessageKeys.type] == PrimeIsolateMessageKeys.result) {
        break;
      }
    }
  }

  /// Kills the isolate (e.g. the user pressed "Cancel").
  void cancel() {
    _manager?.dispose();
    _manager = null;
  }
}

/// The function that actually runs *inside* the spawned isolate.
///
/// It has its own memory heap: it cannot read or write any variable
/// from the main isolate. It can only receive data through
/// [mainSendPort] and only send data back the same way.
///
/// This MUST be a top-level (or static) function — closures that
/// capture outer state cannot be spawned as isolate entry points.
void _primeIsolateEntryPoint(SendPort mainSendPort) {
  final ReceivePort commandPort = ReceivePort();
  // First message we ever send: hand our SendPort back to the main
  // isolate so it knows how to talk to us.
  mainSendPort.send(commandPort.sendPort);

  commandPort.listen((dynamic command) {
    final int limit = (command as Map)['limit'] as int;
    final Stopwatch stopwatch = Stopwatch()..start();
    final List<int> primes = <int>[];

    // Report progress roughly 100 times over the whole run, so we
    // don't flood the port with messages for large limits.
    final int naiveStep = limit ~/ 100;
    final int reportEvery = naiveStep < 1 ? 1 : naiveStep;

    for (int number = 2; number <= limit; number++) {
      if (_isPrime(number)) {
        primes.add(number);
      }

      if (number % reportEvery == 0) {
        mainSendPort.send(<String, dynamic>{
          PrimeIsolateMessageKeys.type: PrimeIsolateMessageKeys.progress,
          PrimeIsolateMessageKeys.current: number,
          PrimeIsolateMessageKeys.percentage: number / limit,
        });
      }
    }

    stopwatch.stop();
    mainSendPort.send(<String, dynamic>{
      PrimeIsolateMessageKeys.type: PrimeIsolateMessageKeys.result,
      PrimeIsolateMessageKeys.primes: primes,
      PrimeIsolateMessageKeys.elapsedMs: stopwatch.elapsedMilliseconds,
    });
  });
}

bool _isPrime(int n) {
  if (n < 2) return false;
  if (n % 2 == 0) return n == 2;
  for (int i = 3; i * i <= n; i += 2) {
    if (n % i == 0) return false;
  }
  return true;
}
