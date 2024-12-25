import 'package:backend/adaptor/use_case_execute/use_case_transaction_on_firestore.dart';

import 'package:backend/command/model/picking_order/event.dart';
import 'package:backend/command/use_case/cancel_picking_use_case.dart';
import 'package:dart_firebase_admin/firestore.dart';
import 'package:fpdart/fpdart.dart';

class CancelPickingWhenPickingOrderCancelled {
  final Firestore _firestore;
  final CancelPickingUseCase _cancelPickingUseCase;

  CancelPickingWhenPickingOrderCancelled(
    this._firestore,
    this._cancelPickingUseCase,
  );

  Future<void> execute(PickingOrderCancelled cancelled) {
    return UseCaseTransactionOnFirestore.begin(_firestore).flatMap((tx) {
      final useCaseTx = UseCaseTransactionOnFirestore(tx);
      final task =
          TaskEither.traverseList(cancelled.orderedPickingIds, (pickingId) {
        return _cancelPickingUseCase.execute(
          useCaseTx,
          pickingId,
          correlationId: cancelled.header.correlationId,
        );
      });
      return tx(task);
    }).run();
  }
}
