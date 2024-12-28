import 'dart:math';

import 'package:backend/command/model/picking/picking.dart';
import 'package:backend/command/model/picking/repository.dart';
import 'package:backend/command/model/picking_order/repository.dart';
import 'package:clock/clock.dart';
import 'package:fpdart/fpdart.dart';
import 'package:backend/command/model/picking_order/picking_order.dart';

import 'command_use_case_transaction.dart';

class SendPickingOrderUseCase {
  final PickingOrderRepository _pickingOrderRepository;
  final PickingRepository _pickingRepository;
  final Clock _clock;

  SendPickingOrderUseCase(
    this._pickingOrderRepository,
    this._pickingRepository,
    this._clock,
  );

  TaskEither<List<dynamic>, ()> execute(
    CommandUseCaseTransaction transaction,
    List<PickingItem> items, {
    required String correlationId,
  }) {
    final pickingOrderId = Random().nextInt(1000000).toString();

    final (orderPickingErrors, orderPickingResults) = items.map((item) {
      return Picking.order(
        pickingId: Random().nextInt(1000000).toString(),
        itemName: item.itemName,
        quantity: item.quantity,
        correlationId: correlationId,
        pickingOrderId: pickingOrderId,
        clock: _clock,
      );
    }).partitionEithersEither();

    if (orderPickingErrors.isNotEmpty) {
      return TaskEither.left(orderPickingErrors);
    }

    final (pickingOrder, pickingOrderEvents) = PickingOrder.receive(
      pickingOrderId: pickingOrderId,
      orderedPickingIds: orderPickingResults
          .map(
            (result) => result.$1.pickingId,
          )
          .toList(),
      correlationId: correlationId,
      clock: _clock,
    );

    final tasks = [
      _pickingOrderRepository.store(
        transaction.repositoryTx,
        pickingOrder,
        pickingOrderEvents,
      ),
      ...orderPickingResults.map((result) {
        return _pickingRepository.store(
          transaction.repositoryTx,
          result.$1,
          result.$2,
        );
      })
    ];

    return Task.traverseList(tasks, identity)
        .map((_) => ())
        .toTaskEither<List<dynamic>>();
  }
}

typedef PickingItem = ({String itemName, int quantity});
