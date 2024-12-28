import 'package:backend/command/use_case/command_use_case_transaction.dart';
import 'package:fpdart/fpdart.dart';

import 'command_use_case_error.dart';

typedef RunnableCommandUseCaseContext = ({
  String correlationId,
  CommandUseCaseTransaction transaction,
});

typedef RunnableCommandUseCase = TaskEither<CommandUseCaseError, ()> Function(
    RunnableCommandUseCaseContext ctx);

class TransactionException {
  final Exception exception;
  final StackTrace stackTrace;

  TransactionException(
    this.exception,
    this.stackTrace,
  );
}

abstract interface class CommandUseCaseTransactionManager {
  TaskEither<TransactionException, CommandUseCaseTransaction>
      beginTransaction();

  TaskEither<TransactionException, ()> commitTransaction(
    CommandUseCaseTransaction transaction,
  );

  TaskEither<TransactionException, ()> rollbackTransaction(
    CommandUseCaseTransaction transaction,
  );
}

abstract interface class CorrelationIdProvider {
  Task<String> getCorrelationId();
}

abstract class RunCommandUseCaseDependencies {
  final CommandUseCaseTransactionManager transactionManager;
  final CorrelationIdProvider correlationIdProvider;

  RunCommandUseCaseDependencies(
    this.transactionManager,
    this.correlationIdProvider,
  );
}

ReaderTaskEither<RunCommandUseCaseDependencies, CommandUseCaseError, ()>
    runCommandUseCase(
  RunnableCommandUseCase fn,
) {
  return ReaderTaskEither((e) {
    final correlationId = e.correlationIdProvider
        .getCorrelationId()
        .toTaskEither()
        .mapLeft<CommandUseCaseError>((e) {
      return UnexpectedErrorOccurred.unreachable();
    });

    final beginTransaction =
        e.transactionManager.beginTransaction().mapLeft((e) {
      return UnexpectedErrorOccurred(
        e.exception,
        e.stackTrace,
      );
    });

    final runT = correlationId.map2(beginTransaction, (correlationId, tx) {
      return (correlationId, tx);
    }).flatMap((correlationIdTx) {
      final (correlationId, tx) = correlationIdTx;
      return fn((correlationId: correlationId, transaction: tx))
          .map((_) {
            return tx;
          })
          .flatMap((tx) {
            return e.transactionManager.commitTransaction(tx).mapLeft((e) {
              return UnexpectedErrorOccurred(
                e.exception,
                e.stackTrace,
              );
            });
          })
          .swap()
          .flatMap<CommandUseCaseError>((useCaseError) {
            if (useCaseError.contains(TransactionException)) {
              return TaskEither.right(useCaseError);
            }

            final rollback = e.transactionManager
                .rollbackTransaction(tx)
                .mapLeft<CommandUseCaseError>((rollbackError) {
              return MultipleErrorsOccurred(
                [
                  UnexpectedErrorOccurred(
                    rollbackError.exception,
                    rollbackError.stackTrace,
                  ),
                  useCaseError
                ],
              );
            }).map((_) => useCaseError);

            return rollback.match(identity, identity).toTaskEither();
          })
          .swap();
    });
    return runT.run();
  });
}

class RunCommandUseCase {
  final RunCommandUseCaseDependencies _dependencies;

  RunCommandUseCase(
    this._dependencies,
  );

  TaskEither<CommandUseCaseError, ()> run(
    RunnableCommandUseCase fn,
  ) {
    return TaskEither(() => runCommandUseCase(fn).run(_dependencies));
  }
}
