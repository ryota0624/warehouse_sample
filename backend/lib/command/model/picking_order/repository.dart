import 'package:backend/command/model/picking_order/event.dart';
import 'package:backend/command/model/picking_order/picking_order.dart';
import 'package:backend/command/model/repository_tx.dart';
import 'package:dart_firebase_admin/firestore.dart';
import 'package:fpdart/fpdart.dart';

abstract interface class PickingOrderRepository {
  Task<Option<PickingOrder>> getById(String pickingOrderId, {Transaction? tx});

  Task<()> store(RepositoryTx tx, PickingOrder pickingOrder,
      List<PickingOrderEvent> events);
}
