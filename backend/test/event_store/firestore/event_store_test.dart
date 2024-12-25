import 'dart:math';

import 'package:backend/event_store/event/correlation_id.dart';
import 'package:backend/event_store/event/event.dart';
import 'package:backend/event_store/event/event_header.dart';
import 'package:backend/event_store/event/event_publish_source.dart';
import 'package:backend/event_store/firestore/event_store.dart';
import 'package:dart_firebase_admin/firestore.dart';
import 'package:test/test.dart';

import '../../utils/firestore.dart';

void main() {
  group('Firestore', () {
    late Firestore firestore;
    late EventStoreOnFirestore eventStore;

    setUp(() {
      firestore = createFirestore();
      eventStore = EventStoreOnFirestore(firestore);
    });

    test('永続化したイベントは取得できる', () async {
      final aggregateRoot = (
        aggregateRootId: Random().nextInt(100000).toString(),
        aggregateRootType: 'aggregateRootType',
      );

      await firestore.runTransaction((tx) async {
        final ctx = tx.eventPersistenceCtx;
        final events = List.generate(4, (i) {
          final version = i + 1;
          return _TestEvent(
            header: EventHeader(
              EventPublishSource(
                aggregateRootId: aggregateRoot.aggregateRootId,
                aggregateRootType: aggregateRoot.aggregateRootType,
                aggregateRootVersion: version,
              ),
              CorrelationId('aaa'),
              DateTime.now(),
            ),
            payload: {
              'version': version,
            },
          );
        });
        for (final event in events) {
          await eventStore.persistEvent(ctx, event);
        }
      });

      final events = await eventStore.getEventsByAggregateIdSinceVersion(
        aggregateRootId: aggregateRoot.aggregateRootId,
        aggregateRootType: aggregateRoot.aggregateRootType,
        aggregateRootVersion: 2,
      );

      for (var e in events) {
        print(e.header.publishSource.aggregateRootVersion);
      }
      expect(events, hasLength(3));
    });
  });
}

class _TestEvent implements Event {
  @override
  final EventHeader header;
  @override
  final Map<String, dynamic> payload;

  _TestEvent({
    required this.header,
    required this.payload,
  });
}
