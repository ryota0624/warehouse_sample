import 'dart:convert';

import 'package:backend/event_store/event/correlation_id.dart';
import 'package:backend/event_store/event/event.dart';
import 'package:backend/event_store/event/event_publish_source.dart';
import 'package:backend/event_store/event_store.dart';
import 'package:crypto/crypto.dart';
import 'package:dart_firebase_admin/firestore.dart';
import 'package:backend/event_store/event/event_header.dart';

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
          fromFirestore: _PreDecodeEvent.fromSnapshot,
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

class _PreDecodeEvent implements PreDecodeEvent {
  final DocumentSnapshot<Map<String, dynamic>> _snapshot;
  @override
  final EventHeader header;

  _PreDecodeEvent.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> snapshot)
      : _snapshot = snapshot,
        header = EventHeader(
          EventPublishSource(
            aggregateRootId: snapshot.data()!['aggregateRootId'],
            aggregateRootType: snapshot.data()!['aggregateRootType'],
            aggregateRootVersion: snapshot.data()!['aggregateRootVersion'],
          ),
          CorrelationId(snapshot.data()!['correlationId']),
          DateTime.fromMillisecondsSinceEpoch(
            (snapshot.data()!['occurrenceTime'] as Timestamp).seconds * 1000,
          ),
        );

  @override
  T decode<T>(
    T Function(EventHeader header, Map<String, dynamic> payload)
        fromHeaderAndPayload,
  ) {
    return fromHeaderAndPayload(
      header,
      _snapshot.data()!['payload'],
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
