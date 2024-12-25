import 'package:backend/adaptor/proto_translate/picking_order_event_translate.dart';
import 'package:backend/adaptor/repository/repository_tx_on_firestore.dart';
import 'package:backend/adaptor/repository/storable_event.dart';
import 'package:backend/command/model/picking_order/event.dart';
import 'package:backend/command/model/picking_order/picking_order.dart';
import 'package:backend/command/model/picking_order/repository.dart';
import 'package:backend/event_store/event/correlation_id.dart';
import 'package:backend/event_store/event/event_header.dart';
import 'package:backend/event_store/event/event_publish_source.dart';
import 'package:backend/event_store/firestore/event_store.dart';
import 'package:dart_firebase_admin/firestore.dart';
import 'package:fpdart/fpdart.dart';
import 'package:event_schema/serverpod_app/event/picking_order/v1/picking_order.pb.dart'
    as pb;

class PickingOrderRepositoryOnFirestore implements PickingOrderRepository {
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
  Task<Option<PickingOrder>> getById(String pickingOrderId, {Transaction? tx}) {
    final pickingOrder = Task<Option<PickingOrder>>(() async {
      try {
        final pickingOrder = await _firestore
            .collection(_pickingOrderType)
            .doc(pickingOrderId)
            .withConverter(fromFirestore: (doc) {
          return PickingOrder.fromJson(
            doc.data(),
          );
        }, toFirestore: (_) {
          throw UnimplementedError();
        }).get(tx: tx);
        return optionOf(pickingOrder.data());
      } on StateError catch (_) {
        return Option.none();
      }
    });

    return pickingOrder.flatMap((pickingOrderOpt) {
      return Task(() async {
        final events = await _eventStore.getEventsByAggregateIdSinceVersion(
          aggregateRootId: pickingOrderId,
          aggregateRootType: _pickingOrderType,
          aggregateRootVersion: pickingOrderOpt.map((pickingOrder) {
            return pickingOrder.version + 1;
          }).getOrElse(() => 1),
        );

        final modelEvents = events.map((event) {
          return event.decode((header, payload) {
            final protoEvent = pb.PickingOrderEvent()
              ..mergeFromProto3Json(payload);
            return _eventTranslate.fromProtoToModel(protoEvent);
          });
        }).toList();

        if (modelEvents.isEmpty && pickingOrderOpt.isNone()) {
          return Option.none();
        }

        return pickingOrderOpt.fold(() {
          return Option.of(PickingOrder.fromEvents(modelEvents));
        }, (pickingOrder) {
          return Option.of(
            modelEvents.fold(pickingOrder, (po, e) => po.apply(e)),
          );
        });
      });
    });
  }

  @override
  Task<()> store(
    covariant RepositoryTxOnFirestore tx,
    PickingOrder pickingOrder,
    List<PickingOrderEvent> events,
  ) {
    return Task(() async {
      final persistEvents = events.map((event) {
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
      }).toList();

      await Future.wait(persistEvents.map((event) {
        return _eventStore.persistEvent(
            EventPersistenceTxForFirestore(
              tx.firestoreTx,
            ),
            event);
      }));

      tx.firestoreTx.set(
        tx.firestoreTx.firestore
            .collection(_pickingOrderType)
            .doc(pickingOrder.pickingOrderId),
        pickingOrder.toJson(),
      );

      return ();
    });
  }
}
