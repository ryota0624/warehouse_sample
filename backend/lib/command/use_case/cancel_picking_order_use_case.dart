import 'package:backend/command/model/picking_order/command.dart';
import 'package:backend/command/model/picking_order/repository.dart';
import 'package:backend/command/use_case/use_case_transaction.dart';
import 'package:clock/clock.dart';
import 'package:fpdart/fpdart.dart';

class CancelPickingOrderUseCase {
  final PickingOrderRepository _pickingOrderRepository;

  final Clock clock;

  CancelPickingOrderUseCase(
    this._pickingOrderRepository,
    this.clock,
  );

  TaskEither<List<dynamic>, ()> execute(
    UseCaseTransaction transaction,
    String pickingOrderId, {
    required String correlationId,
  }) {
    return _pickingOrderRepository
        .getById(pickingOrderId)
        .toTaskEither<List<PickingOrderCommandError>>()
        .flatMap((pickingOrder) {
      return pickingOrder.fold(
        () => TaskEither.left([
          PickingOrderNotFound(),
        ]),
        (pickingOrder) {
          return pickingOrder
              .process(CancelPickingOrder(
                pickingOrderId: pickingOrderId,
                correlationId: correlationId,
              ))
              .toTaskEither();
        },
      );
    }).flatMap((cancelled) {
      final (pickingOrder, events) = cancelled;
      return _pickingOrderRepository
          .store(
            transaction.repositoryTx,
            pickingOrder,
            events,
          )
          .toTaskEither();
    });
  }
}
