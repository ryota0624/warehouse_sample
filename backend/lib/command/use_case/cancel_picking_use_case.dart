import 'package:backend/command/model/picking/repository.dart';
import 'package:backend/command/use_case/command_use_case_transaction.dart';
import 'package:clock/clock.dart';
import 'package:fpdart/fpdart.dart';

import 'package:backend/command/model/picking/command.dart';

import 'command_use_case_error.dart';

class CancelPickingUseCase {
  final PickingRepository _pickingRepository;

  final Clock clock;

  CancelPickingUseCase(
    this._pickingRepository,
    this.clock,
  );

  TaskEither<CommandUseCaseError, ()> execute(
    CommandUseCaseTransaction transaction,
    String pickingId, {
    required String correlationId,
  }) {
    return _pickingRepository
        .getById(pickingId)
        .toTaskEither<CommandUseCaseError>(
          () => ModelConstraintErrorOccurred(
            PickingNotFound(),
          ),
        )
        .flatMap((picking) {
      return picking
          .process(CancelPicking(
            pickingId: pickingId,
            correlationId: correlationId,
          ))
          .mapLeft(
            ModelConstraintErrorOccurred.listOf,
          )
          .toTaskEither();
    }).flatMap((cancelled) {
      final (picking, events) = cancelled;
      return _pickingRepository
          .store(
            transaction.repositoryTx,
            picking,
            events,
          )
          .toTaskEither();
    });
  }
}
