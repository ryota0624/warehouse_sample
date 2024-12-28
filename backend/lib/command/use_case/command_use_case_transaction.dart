import 'package:backend/command/model/repository_tx.dart';

abstract interface class CommandUseCaseTransaction {
  RepositoryTx get repositoryTx;
}
