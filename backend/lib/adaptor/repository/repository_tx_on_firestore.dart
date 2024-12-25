import 'package:backend/command/model/repository_tx.dart';
import 'package:dart_firebase_admin/firestore.dart';

class RepositoryTxOnFirestore implements RepositoryTx {
  final Transaction firestoreTx;

  RepositoryTxOnFirestore(this.firestoreTx);
}
