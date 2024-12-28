import 'package:backend/command/model/model_constraint_error.dart';

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

sealed class PickingOrderCommandError implements ModelConstraintError {}

class PickingOrderAlreadyReceived
    with EasyMessageForModelConstraintError
    implements PickingOrderCommandError {}

class PickingOrderAlreadyCancelled
    with EasyMessageForModelConstraintError
    implements PickingOrderCommandError {}

class PickingOrderNotFound
    with EasyMessageForModelConstraintError
    implements PickingOrderCommandError {}
