import 'dart:async';
import 'dart:isolate';

/// A small, reusable wrapper around [Isolate] that sets up a
/// bidirectional communication channel with a spawned isolate.
///
/// This is the piece that actually demonstrates "how isolates work":
/// - [spawn] starts a brand new isolate (its own memory heap, its own
///   event loop) running [entryPoint].
/// - The child isolate sends its [SendPort] back through the port we
///   gave it, which is how the two isolates learn how to talk to
///   each other (isolates share **no memory**, only messages).
/// - [send] lets the main isolate push commands into the child.
/// - [messages] is a broadcast stream of everything the child isolate
///   sends back (progress updates, results, errors).
///
/// Usage:
/// ```dart
/// final manager = IsolateManager();
/// await manager.spawn(myTopLevelEntryPoint);
/// await manager.ready;
/// manager.messages.listen((msg) => print(msg));
/// manager.send({'limit': 1000000});
/// ```
class IsolateManager {
  Isolate? _isolate;
  final ReceivePort _receivePort = ReceivePort();
  SendPort? _isolateSendPort;
  final StreamController<dynamic> _messageController = StreamController<dynamic>.broadcast();
  final Completer<void> _readyCompleter = Completer<void>();

  /// Every message the spawned isolate sends back to the main isolate.
  Stream<dynamic> get messages => _messageController.stream;

  /// Completes once the spawned isolate has handed us its [SendPort],
  /// meaning it is ready to receive commands via [send].
  Future<void> get ready => _readyCompleter.future;

  /// Spawns [entryPoint] on a new isolate.
  ///
  /// IMPORTANT: [entryPoint] must be a top-level function or a static
  /// method. Isolates do not share memory, so closures that capture
  /// local state cannot be sent across the isolate boundary.
  Future<void> spawn(void Function(SendPort) entryPoint) async {
    _isolate = await Isolate.spawn<SendPort>(
      entryPoint,
      _receivePort.sendPort,
      debugName: 'isolate_bloc_demo-worker',
    );

    _receivePort.listen((dynamic data) {
      if (data is SendPort) {
        _isolateSendPort = data;
        if (!_readyCompleter.isCompleted) {
          _readyCompleter.complete();
        }
      } else {
        _messageController.add(data);
      }
    });
  }

  /// Sends [message] to the spawned isolate.
  ///
  /// Only primitive values, Lists/Maps of primitives, SendPorts and a
  /// few other "transferable" types can cross the isolate boundary.
  void send(dynamic message) {
    final SendPort? sendPort = _isolateSendPort;
    if (sendPort == null) {
      throw StateError('IsolateManager: isolate is not ready yet. Await `ready` first.');
    }
    sendPort.send(message);
  }

  /// Kills the isolate immediately and releases every resource.
  /// Safe to call multiple times.
  void dispose() {
    _isolate?.kill(priority: Isolate.immediate);
    _isolate = null;
    _receivePort.close();
    if (!_messageController.isClosed) {
      _messageController.close();
    }
  }
}
