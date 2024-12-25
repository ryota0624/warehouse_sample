import 'event/event.dart';
import 'event/event_header.dart';

abstract interface class EventPersistenceTransaction {}

abstract interface class EventStore {
  Future<List<PreDecodeEvent>> getEventsByAggregateIdSinceVersion({
    required String aggregateRootId,
    required String aggregateRootType,
    required int aggregateRootVersion,
  });

  Future<void> persistEvent(EventPersistenceTransaction tx, Event event);
}

abstract interface class PreDecodeEvent {
  EventHeader get header;
  T decode<T>(
    T Function(EventHeader header, Map<String, dynamic> payload)
        fromHeaderAndPayload,
  );
}
