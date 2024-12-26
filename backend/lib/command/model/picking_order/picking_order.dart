import 'package:backend/command/model/aggregate_root.dart';
import 'package:backend/command/model/picking_order/command.dart';
import 'package:backend/command/model/picking_order/event.dart';
import 'package:clock/clock.dart';
import 'package:fpdart/fpdart.dart';
import 'package:meta/meta.dart';

class PickingOrder
    implements
        EventSourcingAggregateRoot<PickingOrderEvent, PickingOrderCommand,
            PickingOrderCommandError, PickingOrder> {
  final bool _isCancelled;
  final int _version;
  final String pickingOrderId;
  final List<String> _orderedPickingIds;

  int get version => _version;

  PickingOrder._({
    required bool isCancelled,
    required int version,
    required this.pickingOrderId,
    required List<String> orderedPickingIds,
  })  : _version = version,
        _isCancelled = isCancelled,
        _orderedPickingIds = orderedPickingIds;

  PickingOrderEventHeader _nextEventHeader(
    String correlationId,
    Clock clock,
  ) {
    return PickingOrderEventHeader(
      pickingOrderId: pickingOrderId,
      pickingOrderVersion: _version + 1,
      occurrenceTime: clock.now(),
      correlationId: correlationId,
    );
  }

  PickingOrder _copyWith({
    bool? isCancelled,
    int? version,
    List<String>? orderedPickingIds,
  }) {
    return PickingOrder._(
      isCancelled: isCancelled ?? _isCancelled,
      version: version ?? _version,
      pickingOrderId: pickingOrderId,
      orderedPickingIds: orderedPickingIds ?? _orderedPickingIds,
    );
  }

  static (PickingOrder, List<PickingOrderEvent>) receive({
    required String pickingOrderId,
    required List<String> orderedPickingIds,
    required Clock clock,
    required String correlationId,
  }) {
    final received = PickingOrderReceived(
      PickingOrderEventHeader(
        pickingOrderId: pickingOrderId,
        pickingOrderVersion: 1,
        occurrenceTime: clock.now(),
        correlationId: correlationId,
      ),
      orderedPickingIds: orderedPickingIds,
    );
    return (
      PickingOrder(received),
      [
        received,
      ]
    );
  }

  factory PickingOrder.fromEvents(
    List<PickingOrderEvent> events,
  ) {
    return events.tail.getOrElse(() => []).fold(
          PickingOrder(events.first as PickingOrderReceived),
          (pickingOrder, event) => pickingOrder.apply(event),
        );
  }

  factory PickingOrder(
    PickingOrderReceived received,
  ) {
    return PickingOrder._(
      isCancelled: false,
      version: received.header.pickingOrderVersion,
      pickingOrderId: received.header.pickingOrderId,
      orderedPickingIds: received.orderedPickingIds,
    );
  }

  @override
  PickingOrder apply(PickingOrderEvent event) {
    assert(event.header.pickingOrderVersion == _version + 1);
    switch (event) {
      case PickingOrderReceived():
        throw StateError('PickingOrder is already received');
      case PickingOrderCancelled():
        return _copyWith(
          isCancelled: true,
          version: event.header.pickingOrderVersion,
        );
    }
  }

  @visibleForTesting
  Either<List<PickingOrderAlreadyCancelled>,
      (PickingOrder, List<PickingOrderEvent>)> cancel({
    required Clock clock,
    required String correlationId,
  }) {
    if (_isCancelled) {
      return Left([
        PickingOrderAlreadyCancelled(),
      ]);
    }
    final cancelled = PickingOrderCancelled(
      _nextEventHeader(
        correlationId,
        clock,
      ),
      orderedPickingIds: _orderedPickingIds,
    );
    return Right((
      apply(cancelled),
      [
        cancelled,
      ],
    ));
  }

  @override
  Either<List<PickingOrderCommandError>,
      (PickingOrder, List<PickingOrderEvent>)> process(
    PickingOrderCommand command,
  ) {
    switch (command) {
      case SendPickingOrder():
        return Left([
          PickingOrderAlreadyReceived(),
        ]);
      case CancelPickingOrder():
        return cancel(
          clock: clock,
          correlationId: command.correlationId,
        );
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'isCancelled': _isCancelled,
      'version': _version,
      'pickingOrderId': pickingOrderId,
      'orderedPickingIds': _orderedPickingIds,
    };
  }

  factory PickingOrder.fromJson(Map<String, dynamic> json) {
    return PickingOrder._(
      isCancelled: json['isCancelled'],
      version: json['version'],
      pickingOrderId: json['pickingOrderId'],
      orderedPickingIds:
          (json['orderedPickingIds'] as List<Object?>).cast<String>(),
    );
  }
}
