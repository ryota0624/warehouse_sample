import 'package:backend/command/model/picking_order/event.dart';
import 'package:event_schema/google/protobuf/timestamp.pb.dart';
import 'package:event_schema/warehouse_sample/event/picking_order/v1/picking_order.pb.dart'
    as pb;
import 'package:event_schema/warehouse_sample/event/v1/header.pb.dart' as pb;

class PickingOrderEventTranslate {
  PickingOrderEvent fromProtoToModel(pb.PickingOrderEvent proto) {
    final header = PickingOrderEventHeader(
      pickingOrderId: proto.header.eventHeader.publishSource.aggregateRootId,
      pickingOrderVersion:
          proto.header.eventHeader.publishSource.aggregateRootVersion,
      occurrenceTime: proto.header.eventHeader.occurrenceTime.toDateTime(),
      correlationId: proto.header.eventHeader.correlationId,
    );
    switch (proto.whichPayload()) {
      case pb.PickingOrderEvent_Payload.received:
        return PickingOrderReceived(
          header,
          orderedPickingIds: proto.received.orderedPickingIds,
        );
      case pb.PickingOrderEvent_Payload.cancelled:
        return PickingOrderCancelled(
          header,
          orderedPickingIds: proto.received.orderedPickingIds,
        );
      case pb.PickingOrderEvent_Payload.notSet:
        throw Exception('Payload not set');
    }
  }

  pb.PickingOrderEvent fromModelToProto(PickingOrderEvent model) {
    final header = pb.PickingOrderEventHeader(
      eventHeader: pb.EventHeader(
        publishSource: pb.EventPublishSource(
          aggregateRootId: model.header.pickingOrderId,
          aggregateRootVersion: model.header.pickingOrderVersion,
        ),
        occurrenceTime: Timestamp.fromDateTime(model.header.occurrenceTime),
        correlationId: model.header.correlationId,
      ),
    );
    switch (model) {
      case PickingOrderReceived():
        return pb.PickingOrderEvent(
          header: header,
          received: pb.PickingOrderReceived(
            orderedPickingIds: model.orderedPickingIds,
          ),
        );
      case PickingOrderCancelled():
        return pb.PickingOrderEvent(
          header: header,
          cancelled: pb.PickingOrderCancelled(
            orderedPickingIds: model.orderedPickingIds,
          ),
        );
    }
  }
}
