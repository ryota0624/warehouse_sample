import 'dart:math';

import 'package:backend/adaptor/proto_translate/picking_order_event_translate.dart';
import 'package:backend/adaptor/repository/picking_order_repository_on_firestore.dart';
import 'package:backend/adaptor/repository/repository_tx_on_firestore.dart';
import 'package:backend/command/model/picking_order/command.dart';
import 'package:backend/command/model/picking_order/picking_order.dart';
import 'package:backend/event_store/firestore/event_store.dart';
import 'package:clock/clock.dart';
import 'package:dart_firebase_admin/firestore.dart';
import 'package:test/test.dart';

import '../../utils/firestore.dart';

void main() {
  late PickingOrderRepositoryOnFirestore repositoryOnFirestore;
  group('PickingOrderRepositoryOnFirestore', () {
    late Firestore firestore;
    late EventStoreOnFirestore eventStore;

    setUp(() {
      firestore = createFirestore();
      eventStore = EventStoreOnFirestore(firestore);
      repositoryOnFirestore = PickingOrderRepositoryOnFirestore(
        PickingOrderEventTranslate(),
        eventStore,
        firestore,
      );
    });
    test('version1を永続化できる', () async {
      final pickingOrderId = Random().nextInt(100000).toString();
      final (pickingOrder, events) = PickingOrder.receive(
        pickingOrderId: pickingOrderId,
        orderedPickingIds: [Random().nextInt(100000).toString()],
        clock: Clock(),
        correlationId: Random().nextInt(100000).toString(),
      );
      await firestore.runTransaction((tx) async {
        await repositoryOnFirestore
            .store(RepositoryTxOnFirestore(tx), pickingOrder, events)
            .run();
      });

      final restoredPickingOrder =
          await repositoryOnFirestore.getById(pickingOrderId).run();

      expect(restoredPickingOrder.isSome(), isTrue);
    });

    test('version2以降を永続化できる', () async {
      final pickingOrderId = Random().nextInt(100000).toString();

      await firestore.runTransaction((tx) async {
        final (pickingOrder, events) = PickingOrder.receive(
          pickingOrderId: pickingOrderId,
          orderedPickingIds: [Random().nextInt(100000).toString()],
          clock: Clock(),
          correlationId: Random().nextInt(100000).toString(),
        );
        await repositoryOnFirestore
            .store(RepositoryTxOnFirestore(tx), pickingOrder, events)
            .run();
      });

      await firestore.runTransaction((tx) async {
        final pickingOrderOpt =
            await repositoryOnFirestore.getById(pickingOrderId).run();

        final pickingOrder = pickingOrderOpt.toNullable()!;

        final (cancelledPickingOrder, events) = pickingOrder
            .process(
          CancelPickingOrder(
            pickingOrderId: pickingOrderId,
            correlationId: Random().nextInt(100000).toString(),
          ),
        )
            .getOrElse((err) {
          throw err;
        });

        await repositoryOnFirestore
            .store(RepositoryTxOnFirestore(tx), cancelledPickingOrder, events)
            .run();
      });

      final restoredPickingOrder =
          await repositoryOnFirestore.getById(pickingOrderId).run();

      expect(restoredPickingOrder.isSome(), isTrue);
      final restoredPickingOrderValue = restoredPickingOrder.toNullable()!;
      expect(restoredPickingOrderValue.version, 2);
    });
  });
}
