import 'package:backend/command/adaptor/repository/repository_tx_on_firestore.dart';
import 'package:backend/command/model/repository_tx.dart';
import 'package:backend/command/use_case/command_use_case_transaction.dart';
import 'package:dart_firebase_admin/firestore.dart';
import 'package:fpdart/fpdart.dart';

class UseCaseTransactionOnFirestore implements CommandUseCaseTransaction {
  final FirestoreTransaction _firestoreTransaction;

  UseCaseTransactionOnFirestore(this._firestoreTransaction);

  @override
  RepositoryTx get repositoryTx => RepositoryTxOnFirestore(
        _firestoreTransaction._transaction,
      );

  static TaskEither<dynamic, FirestoreTransaction> begin(Firestore firestore) {
    return TaskEither.tryCatch(
      () => firestore.beginTransaction().then(FirestoreTransaction.new),
      (e, s) => (e, s),
    );
  }
}

class FirestoreTransaction {
  final Transaction _transaction;

  FirestoreTransaction(this._transaction);

  TaskEither<dynamic, void> commit() {
    return TaskEither.tryCatch(
      () => _transaction.commit(),
      (e, s) => (e, s),
    );
  }

  TaskEither<dynamic, void> rollback() {
    return TaskEither.tryCatch(
      () => _transaction.rollback(),
      (e, s) => (e, s),
    );
  }

  TaskEither<dynamic, R> call<L, R>(TaskEither<dynamic, R> task) {
    final doRollback = rollback()
        .flatMap<R>(
          (_) => TaskEither<dynamic, R>.left(()),
        )
        .mapLeft(
          (e) => e,
        );

    doCommit(R r) => commit()
        .mapLeft(
          (e) => e,
        )
        .map((_) => r);

    return task
        .flatMap(
      doCommit,
    )
        .orElse((_) {
      return doRollback;
    });
  }
}
