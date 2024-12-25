import 'package:backend/command/model/picking/picking.dart';
import 'package:backend/command/model/picking/event.dart';
import 'package:backend/command/model/repository_tx.dart';
import 'package:fpdart/fpdart.dart';

abstract interface class PickingRepository {
  TaskOption<Picking> getById(String pickingId);

  Task<()> store(RepositoryTx tx, Picking picking, List<PickingEvent> events);

  Task<List<Picking>> listByPickingOrderId(String pickingOrderId);
}
