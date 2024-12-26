import 'package:backend/command/model/picking/repository.dart';
import 'package:backend/command/use_case/use_case_transaction.dart';
import 'package:clock/clock.dart';
import 'package:fpdart/fpdart.dart';

import '../model/picking/command.dart';

class CancelPickingUseCase {
  final PickingRepository _pickingRepository;

  final Clock clock;

  CancelPickingUseCase(
    this._pickingRepository,
    this.clock,
  );

  TaskEither<List<dynamic>, ()> execute(
    UseCaseTransaction transaction,
    String pickingId, {
    required String correlationId,
  }) {
    return _pickingRepository
        .getById(pickingId)
        .toTaskEither<List<PickingCommandError>>(() => [
              PickingNotFound(),
            ])
        .flatMap((picking) {
      return picking
          .process(CancelPicking(
            pickingId: pickingId,
            correlationId: correlationId,
          ))
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
