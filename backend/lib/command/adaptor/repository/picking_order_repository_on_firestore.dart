import 'package:backend/command/adaptor/proto_translate/picking_order_event_translate.dart';
import 'package:backend/command/adaptor/repository/repository_on_firestore.dart';
import 'package:backend/command/adaptor/repository/repository_tx_on_firestore.dart';
import 'package:backend/command/adaptor/repository/storable_event.dart';
import 'package:backend/command/model/picking_order/event.dart';
import 'package:backend/command/model/picking_order/picking_order.dart';
import 'package:backend/command/model/picking_order/repository.dart';
import 'package:backend/event_store/event/correlation_id.dart';
import 'package:backend/event_store/event/event_header.dart';
import 'package:backend/event_store/event/event_publish_source.dart';
import 'package:backend/event_store/event_store.dart';
import 'package:backend/event_store/firestore/event_store.dart';
import 'package:dart_firebase_admin/firestore.dart';
import 'package:fpdart/fpdart.dart';
import 'package:event_schema/warehouse_sample/event/picking_order/v1/picking_order.pb.dart'
    as pb;

class PickingOrderRepositoryOnFirestore
    with
        AggregateRootRepositoryOnDefaultImpl<PickingOrderEvent,
            PickingOrder>
    implements
        PickingOrderRepository,
        AggregateRootRepositoryOnFirestore<PickingOrderEvent, PickingOrder> {
  final PickingOrderEventTranslate _eventTranslate;
  final Firestore _firestore;

  static const _pickingOrderType = 'picking_order';

  final EventStoreOnFirestore _eventStore;

  PickingOrderRepositoryOnFirestore(
    this._eventTranslate,
    this._eventStore,
    this._firestore,
  );

  @override
  PickingOrder applyVersion1Event(PickingOrderEvent event) {
    return PickingOrder(event as PickingOrderReceived);
  }

  @override
  PickingOrderEvent decodeEventAsAggregateRootEvent(
      EventHeader header, Map<String, dynamic> payload) {
    final protoEvent = pb.PickingOrderEvent()..mergeFromProto3Json(payload);
    return _eventTranslate.fromProtoToModel(protoEvent);
  }

  @override
  EventStoreOnFirestore get eventStore => _eventStore;

  @override
  StorableEvent eventToStorableEvent(PickingOrderEvent event) {
    final protoEvent = _eventTranslate.fromModelToProto(event);
    return StorableEvent.fromProtoMessage(
      EventHeader(
        EventPublishSource(
            aggregateRootId: event.header.pickingOrderId,
            aggregateRootType: _pickingOrderType,
            aggregateRootVersion: event.header.pickingOrderVersion),
        CorrelationId(event.header.correlationId),
        event.header.occurrenceTime,
      ),
      protoEvent,
    );
  }

  @override
  Task<Option<PickingOrder>> getSnapshots(
    covariant PickingOrderId aggregateRootId, {
    covariant RepositoryTxOnFirestore? tx,
  }) {
    return Task(() async {
      try {
        final pickingOrder = await _firestore
            .collection(aggregateRootId.aggregateRootType)
            .doc(aggregateRootId.asString)
            .withConverter(fromFirestore: (doc) {
          return PickingOrder.fromJson(
            doc.data(),
          );
        }, toFirestore: (_) {
          throw UnimplementedError();
        }).get(tx: tx?.firestoreTx);
        return optionOf(pickingOrder.data());
      } on StateError catch (_) {
        return Option.none();
      }
    });
  }

  @override
  Task<()> saveSnapshots(
    PickingOrder aggregateRoot, {
    required covariant RepositoryTxOnFirestore tx,
  }) {
    tx.firestoreTx.set(
      tx.firestoreTx.firestore
          .collection(aggregateRoot.aggregateRootId.aggregateRootType)
          .doc(aggregateRoot.aggregateRootId.asString),
      aggregateRoot.toJsonForSnapshot(),
    );

    return Task.of(());
  }

  @override
  EventPersistenceTransaction getEventPersistenceTransaction(
      covariant RepositoryTxOnFirestore tx) {
    return EventPersistenceTxForFirestore(tx.firestoreTx);
  }
}
