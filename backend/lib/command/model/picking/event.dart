class PickingEventHeader {
  final String pickingId;
  final int pickingVersion;
  final String pickingOrderId;

  final DateTime occurrenceTime;
  final String correlationId;

  PickingEventHeader({
    required this.pickingId,
    required this.pickingVersion,
    required this.pickingOrderId,
    required this.occurrenceTime,
    required this.correlationId,
  });
}

sealed class PickingEvent {
  final PickingEventHeader header;

  PickingEvent(
    this.header,
  );
}

class PickingOrdered extends PickingEvent {
  final int quantity;
  final String itemName;

  PickingOrdered(
    super.header,
    this.itemName,
    this.quantity,
  );
}

class PickingCancelled extends PickingEvent {
  PickingCancelled(
    super.header,
  );
}

class PickingItemPicked extends PickingEvent {
  PickingItemPicked(
    super.header,
  );
}

class PickingItemStockOut extends PickingEvent {
  PickingItemStockOut(
    super.header,
  );
}

class PickingItemReset extends PickingEvent {
  PickingItemReset(
    super.header,
  );
}
