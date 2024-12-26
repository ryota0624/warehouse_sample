import 'dart:convert';

import 'package:backend/event_store/event/correlation_id.dart';
import 'package:backend/event_store/event/event.dart';
import 'package:backend/event_store/event/event_publish_source.dart';
import 'package:backend/event_store/event_store.dart';
import 'package:crypto/crypto.dart';
import 'package:dart_firebase_admin/firestore.dart' hide Timestamp;
import 'package:backend/event_store/event/event_header.dart';
import 'package:event_schema/google/protobuf/timestamp.pb.dart';

class EventPersistenceTxForFirestore implements EventPersistenceTransaction {
  final Transaction _firestoreTx;

  EventPersistenceTxForFirestore(this._firestoreTx);
}

extension EventPersistenceCtxForFirestoreTx on Transaction {
  EventPersistenceTxForFirestore get eventPersistenceCtx =>
      EventPersistenceTxForFirestore(this);
}

class EventStoreOnFirestore implements EventStore {
  final Firestore _firestore;

  EventStoreOnFirestore(this._firestore);

  CollectionReference<DocumentData> _eventRef({
    required String aggregateRootId,
    required String aggregateRootType,
  }) {
    return _firestore
        .collection('event_store')
        .doc(aggregateRootType)
        .collection('aggregate_roots')
        .doc(aggregateRootId)
        .collection('event_store_events');
  }

  @override
  Future<List<PreDecodeEvent>> getEventsByAggregateIdSinceVersion({
    required String aggregateRootId,
    required String aggregateRootType,
    required int aggregateRootVersion,
  }) {
    final events = _eventRef(
      aggregateRootId: aggregateRootId,
      aggregateRootType: aggregateRootType,
    )
        .where(
          'aggregateRootVersion',
          WhereFilter.greaterThanOrEqual,
          aggregateRootVersion,
        )
        .orderBy(
          'aggregateRootVersion',
          descending: false,
        )
        .withConverter<PreDecodeEvent>(
          fromFirestore: (s) =>
              PreDecodeEventOnFirestore.fromDocument(s.data()),
          toFirestore: (_) {
            throw UnimplementedError();
          },
        );

    return events.get().then(
          (snapshot) => snapshot.docs.map((doc) => doc.data()).toList(),
        );
  }

  @override
  Future<void> persistEvent(
    covariant EventPersistenceTxForFirestore tx,
    Event event,
  ) {
    final events = _eventRef(
      aggregateRootId: event.header.publishSource.aggregateRootId,
      aggregateRootType: event.header.publishSource.aggregateRootType,
    );
    var documentId = sha256
        .convert(utf8.encode(
          '${event.header.publishSource.aggregateRootType}_${event.header.publishSource.aggregateRootId}_${event.header.publishSource.aggregateRootVersion}',
        ))
        .toString();
    tx._firestoreTx.create<Map<String, dynamic>>(
      events.doc(documentId),
      EventTranslator().toFirestore(event),
    );
    return Future.value();
  }
}

class PreDecodeEventOnFirestore implements PreDecodeEvent {
  final Map<String, dynamic> _document;
  @override
  final EventHeader header;

  PreDecodeEventOnFirestore.fromDocument(Map<String, dynamic> document)
      : _document = document,
        header = EventHeader(
          EventPublishSource(
            aggregateRootId: document['aggregateRootId'],
            aggregateRootType: document['aggregateRootType'],
            aggregateRootVersion: document['aggregateRootVersion'],
          ),
          CorrelationId(document['correlationId']),
          (document['occurrenceTime'] as Timestamp).toDateTime(),
        );

  @override
  T decode<T>(
    T Function(EventHeader header, Map<String, dynamic> payload)
        fromHeaderAndPayload,
  ) {
    return fromHeaderAndPayload(
      header,
      _document['payload'],
    );
  }
}

class EventTranslator {
  Map<String, dynamic> toFirestore(Event event) {
    return {
      'aggregateRootId': event.header.publishSource.aggregateRootId,
      'aggregateRootType': event.header.publishSource.aggregateRootType,
      'aggregateRootVersion': event.header.publishSource.aggregateRootVersion,
      'occurrenceTime': event.header.occurrenceTime,
      'correlationId': event.header.correlationId.value,
      'payload': event.payload,
    };
  }
}
