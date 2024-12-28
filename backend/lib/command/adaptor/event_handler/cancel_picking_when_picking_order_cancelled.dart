
import 'package:backend/command/model/picking_order/event.dart';
import 'package:backend/command/use_case/cancel_picking_use_case.dart';
import 'package:backend/command/use_case/command_use_case.dart';
import 'package:backend/event_store/event/event_header.dart';
import 'package:fpdart/fpdart.dart';
import 'package:backend/command/adaptor/proto_translate/picking_order_event_translate.dart';
import 'package:backend/event_store/firestore/firestore_document_receiver.dart';
import 'package:event_schema/warehouse_sample/event/picking_order/v1/picking_order.pb.dart'
    as pb;

class CancelPickingWhenPickingOrderCancelled
    implements EventHandlerForFirestoreDocument<PickingOrderCancelled> {
  final CancelPickingUseCase _cancelPickingUseCase;
  final PickingOrderEventTranslate _eventTranslate;
  final RunCommandUseCaseDependencies _runCommandUseCaseDependencies;
  final RunCommandUseCase _runCommandUseCase;

  CancelPickingWhenPickingOrderCancelled(
    this._cancelPickingUseCase,
    this._eventTranslate,
    this._runCommandUseCaseDependencies,
    this._runCommandUseCase,
  );

  @override
  Future<void> handleEvent(PickingOrderCancelled cancelled) async {
    await TaskEither.traverseList(cancelled.orderedPickingIds, (pickingId) {
      return _runCommandUseCase.run(
        (ctx) {
          return _cancelPickingUseCase.execute(
            ctx.transaction,
            pickingId,
            correlationId: ctx.correlationId,
          );
        },
      );
    }).map((_) => ()).run();
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
