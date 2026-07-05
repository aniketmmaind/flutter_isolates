import 'package:equatable/equatable.dart';

/// Base class for all domain-level failures.
///
/// Kept deliberately small: this demo favors throwing/catching typed
/// exceptions over an Either-based result type, to keep the isolate
/// mechanics front and center. Swap in `dartz`'s `Either` here if your
/// team's convention requires it — the rest of the architecture does
/// not need to change.
sealed class Failure extends Equatable {
  final String message;
  const Failure(this.message);

  @override
  List<Object?> get props => [message];
}

class ComputationFailure extends Failure {
  const ComputationFailure(super.message);
}

class InvalidInputFailure extends Failure {
  const InvalidInputFailure(super.message);
}
