import 'package:backend/command/model/repository_tx.dart';

abstract interface class UseCaseTransaction {
  RepositoryTx get repositoryTx;
}
