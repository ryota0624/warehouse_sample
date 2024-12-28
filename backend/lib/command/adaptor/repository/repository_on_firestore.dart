import 'package:backend/command/adaptor/repository/storable_event.dart';
import 'package:backend/command/model/repository_tx.dart';
import 'package:backend/event_store/event/event_header.dart';
import 'package:backend/event_store/event_store.dart';
import 'package:fpdart/fpdart.dart';

abstract interface class AggregateRootId<AggregateRoot> {
  String get aggregateRootType;

  String get asString;
}

class AggregateRootVersion {
  final int version;

  AggregateRootVersion(this.version) {
    if (version < 0) {
      throw ArgumentError.value(
        version,
        'version',
        'must be greater than or equal to 0',
      );
    }
  }

  int get asInt => version;
}

abstract interface class AggregateRoot<Event, Self> {
  AggregateRootId<AggregateRoot> get aggregateRootId;

  AggregateRootVersion get aggregateRootVersion;

  Self apply(Event event);

  Map<String, dynamic> toJsonForSnapshot();
}

abstract class AggregateRootRepositoryOnFirestore<AggregateRootEvent,
    A extends AggregateRoot<AggregateRootEvent, A>> {
  EventStore get eventStore;

  Task<Option<A>> getSnapshots(
    AggregateRootId<A> aggregateRootId, {
    RepositoryTx? tx,
  });

  Task<()> saveSnapshots(
    A aggregateRoot, {
    required RepositoryTx tx,
  });

  A applyVersion1Event(AggregateRootEvent event);

  AggregateRootEvent decodeEventAsAggregateRootEvent(
    EventHeader header,
    Map<String, dynamic> payload,
  );

  StorableEvent eventToStorableEvent(AggregateRootEvent event);

  EventPersistenceTransaction getEventPersistenceTransaction(RepositoryTx tx);
}

mixin AggregateRootRepositoryOnDefaultImpl<AggregateRootEvent,
        A extends AggregateRoot<AggregateRootEvent, A>>
    implements AggregateRootRepositoryOnFirestore<AggregateRootEvent, A> {
  Task<Option<A>> getById(
    AggregateRootId<A> aggregateRootId, {
    RepositoryTx? tx,
  }) {
    final aggregateRootSnapshot = getSnapshots(
      aggregateRootId,
      tx: tx,
    );
    return aggregateRootSnapshot.flatMap((snapshotOpt) {
      return Task(() async {
        final events = await eventStore.getEventsByAggregateIdSinceVersion(
          aggregateRootId: aggregateRootId.asString,
          aggregateRootType: aggregateRootId.aggregateRootType,
          aggregateRootVersion: snapshotOpt.map((snapshot) {
            return snapshot.aggregateRootVersion.asInt + 1;
          }).getOrElse(() => 1),
        );

        final modelEvents = events.map((event) {
          return event.decode(decodeEventAsAggregateRootEvent);
        }).toList();
        return modelEvents;
      }).map((events) {
        if (events.isEmpty && snapshotOpt.isNone()) {
          return Option.none();
        }

        final preApplyEvent = snapshotOpt.getOrElse(() {
          return applyVersion1Event(events.first);
        });
        final restored = events.fold(preApplyEvent, (po, e) => po.apply(e));
        return Option.of(restored);
      });
    });
  }

  Task<()> store(
    RepositoryTx tx,
    A aggregateRoot,
    List<AggregateRootEvent> events,
  ) {
    return Task(() async {
      final persistEvents = events.map((event) {
        return eventToStorableEvent(event);
      }).toList();
      await Future.wait(persistEvents.map((event) {
        return eventStore.persistEvent(
          getEventPersistenceTransaction(tx),
          event,
        );
      }));
    }).andThen(() {
      return saveSnapshots(aggregateRoot, tx: tx).map((_) => ());
    });
  }
}
