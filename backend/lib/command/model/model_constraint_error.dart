abstract interface class ModelConstraintError {
  String get message;
}

mixin EasyMessageForModelConstraintError implements ModelConstraintError {
  @override
  String get message => 'constraint error: $runtimeType';
}
