import 'package:backend/command/model/aggregate_root.dart';
import 'package:backend/command/model/picking/command.dart';
import 'package:backend/command/model/picking/event.dart';
import 'package:clock/clock.dart';
import 'package:fpdart/fpdart.dart';
import 'package:meta/meta.dart';

class Picking
    implements
        EventSourcingAggregateRoot<PickingEvent, PickingCommand,
            PickingCommandError, Picking> {
  @visibleForTesting
  @override
  Picking apply(PickingEvent event) {
    switch (event) {
      case PickingOrdered():
        throw StateError('Picking is already ordered');
      case PickingCancelled():
        return _copyWith(isCancelled: true);
      case PickingItemPicked():
      // TODO: Handle this case.
      case PickingItemStockOut():
      // TODO: Handle this case.
      case PickingItemReset():
      // TODO: Handle this case.
    }

    throw UnimplementedError();
  }

  final bool _isCancelled;
  final int _version;
  final String _pickingId;

  String get pickingId => _pickingId;

  Picking _copyWith({
    bool? isCancelled,
    int? version,
  }) {
    return Picking._(
      isCancelled: isCancelled ?? _isCancelled,
      version: version ?? _version,
      pickingId: _pickingId,
    );
  }

  @override
  Either<List<PickingCommandError>, (Picking, List<PickingEvent>)> process(
    PickingCommand command,
  ) {
    switch (command) {
      case OrderPicking():
        throw StateError('Picking is already ordered');
      case CancelPicking():
        return cancel(
          clock: clock,
          correlationId: command.correlationId,
        );
    }
  }

  static Either<List<OrderPickingError>, (Picking, List<PickingEvent>)> order({
    required String pickingId,
    required String pickingOrderId,
    required Clock clock,
    required String correlationId,
    required String itemName,
    required int quantity,
  }) {
    final ordered = PickingOrdered(
      PickingEventHeader(
        pickingId: pickingId,
        pickingVersion: 1,
        occurrenceTime: clock.now(),
        correlationId: correlationId,
        pickingOrderId: pickingOrderId,
      ),
      itemName,
      quantity,
    );
    return right(
      (
        Picking.fromOrdered(ordered: ordered),
        [ordered],
      ),
    );
  }

  factory Picking._({
    required bool isCancelled,
    required int version,
    required String pickingId,
  }) {
    return Picking._(
      isCancelled: isCancelled,
      version: version,
      pickingId: pickingId,
    );
  }

  factory Picking.fromOrdered({
    required PickingOrdered ordered,
  }) {
    return Picking._(
      isCancelled: false,
      version: ordered.header.pickingVersion,
      pickingId: ordered.header.pickingId,
    );
  }

  Picking(
    this._isCancelled,
    this._version,
    this._pickingId,
  );

  @visibleForTesting
  Either<List<PickingCommandError>, (Picking, List<PickingEvent>)> cancel({
    required Clock clock,
    required String correlationId,
  }) {
    if (_isCancelled) {
      return left([PickingAlreadyCancelled()]);
    }

    final cancelled = PickingCancelled(
      PickingEventHeader(
        pickingId: _pickingId,
        pickingVersion: _version + 1,
        occurrenceTime: clock.now(),
        correlationId: correlationId,
        pickingOrderId: _pickingId,
      ),
    );
    return right(
      (
        _copyWith(isCancelled: true),
        [cancelled],
      ),
    );
  }
}
