sealed class PickingCommand {
  final String correlationId;
  final String pickingId;

  PickingCommand({
    required this.correlationId,
    required this.pickingId,
  });
}

sealed class PickingCommandError {}

class OrderPicking extends PickingCommand {
  final String pickingOrderId;
  final String itemName;
  final int quantity;

  OrderPicking({
    required super.correlationId,
    required super.pickingId,
    required this.pickingOrderId,
    required this.itemName,
    required this.quantity,
  });
}

class OrderPickingError implements PickingCommandError {}

class PickingNotFound implements PickingCommandError {}

class CancelPicking extends PickingCommand {
  CancelPicking({
    required super.correlationId,
    required super.pickingId,
  });
}

class PickingAlreadyCancelled implements PickingCommandError {}
