class PickingOrderEventHeader {
  final String pickingOrderId;
  final int pickingOrderVersion;

  final DateTime occurrenceTime;
  final String correlationId;

  PickingOrderEventHeader({
    required this.pickingOrderId,
    required this.pickingOrderVersion,
    required this.occurrenceTime,
    required this.correlationId,
  });
}

sealed class PickingOrderEvent {
  final PickingOrderEventHeader header;

  PickingOrderEvent(
    this.header,
  );
}

class PickingOrderReceived extends PickingOrderEvent {
  PickingOrderReceived(
    super.header, {
    required this.orderedPickingIds,
  });

  final List<String> orderedPickingIds;
}

class PickingOrderCancelled extends PickingOrderEvent {
  PickingOrderCancelled(
    super.header, {
    required this.orderedPickingIds,
  });

  final List<String> orderedPickingIds;
}
