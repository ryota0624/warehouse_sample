import 'package:backend/command/model/model_constraint_error.dart';

sealed class PickingCommand {
  final String correlationId;
  final String pickingId;

  PickingCommand({
    required this.correlationId,
    required this.pickingId,
  });
}

sealed class PickingCommandError implements ModelConstraintError {
}

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

class OrderPickingError with EasyMessageForModelConstraintError implements PickingCommandError {}

class PickingNotFound with EasyMessageForModelConstraintError implements PickingCommandError {}

class CancelPicking extends PickingCommand {
  CancelPicking({
    required super.correlationId,
    required super.pickingId,
  });
}

class PickingAlreadyCancelled with EasyMessageForModelConstraintError implements PickingCommandError {}
