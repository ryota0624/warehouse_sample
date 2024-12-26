import 'package:backend/adaptor/use_case_execute/use_case_transaction_on_firestore.dart';

import 'package:backend/command/model/picking_order/event.dart';
import 'package:backend/command/use_case/cancel_picking_use_case.dart';
import 'package:backend/event_store/event/event_header.dart';
import 'package:dart_firebase_admin/firestore.dart';
import 'package:fpdart/fpdart.dart';
import 'package:backend/adaptor/proto_translate/picking_order_event_translate.dart';
import 'package:backend/adaptor/event_handler/firestore_document_receiver.dart';
import 'package:event_schema/warehouse_sample/event/picking_order/v1/picking_order.pb.dart'
    as pb;

class CancelPickingWhenPickingOrderCancelled
    implements EventHandlerForFirestoreDocument<PickingOrderCancelled> {
  final Firestore _firestore;
  final CancelPickingUseCase _cancelPickingUseCase;
  final PickingOrderEventTranslate _eventTranslate;

  CancelPickingWhenPickingOrderCancelled(
    this._firestore,
    this._cancelPickingUseCase,
    this._eventTranslate,
  );

  @override
  Future<void> handleEvent(PickingOrderCancelled cancelled) {
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

  @override
  PickingOrderCancelled? decodeEvent(
    EventHeader header,
    Map<String, dynamic> payload,
  ) {
    final protoEvent = pb.PickingOrderEvent()..mergeFromProto3Json(payload);
    final modelEvent = _eventTranslate.fromProtoToModel(
      protoEvent,
    );

    if (modelEvent is PickingOrderCancelled) {
      return modelEvent;
    }

    return null;
  }
}
