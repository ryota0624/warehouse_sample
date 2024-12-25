sealed class PickingOrderCommand {
  final String pickingOrderId;
  final String correlationId;

  PickingOrderCommand({
    required this.pickingOrderId,
    required this.correlationId,
  });
}

class SendPickingOrder extends PickingOrderCommand {
  SendPickingOrder({
    required super.pickingOrderId,
    required super.correlationId,
  });
}

class CancelPickingOrder extends PickingOrderCommand {
  CancelPickingOrder({
    required super.pickingOrderId,
    required super.correlationId,
  });
}

sealed class PickingOrderCommandError {}
class PickingOrderAlreadyReceived implements PickingOrderCommandError {}

class PickingOrderAlreadyCancelled implements PickingOrderCommandError {}
class PickingOrderNotFound implements PickingOrderCommandError {}
