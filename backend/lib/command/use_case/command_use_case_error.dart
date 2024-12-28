import 'package:backend/command/model/model_constraint_error.dart';

sealed class CommandUseCaseError {
  bool contains(Type type);
}

class MultipleErrorsOccurred implements CommandUseCaseError {
  final List<CommandUseCaseError> errors;

  MultipleErrorsOccurred(this.errors) {
    assert(errors.isNotEmpty);
  }

  @override
  bool contains(Type type) {
    return errors.any((error) => error.contains(type));
  }
}

class ModelConstraintErrorOccurred implements CommandUseCaseError {
  final ModelConstraintError error;

  ModelConstraintErrorOccurred(this.error);

  @override
  bool contains(Type type) {
    return error.runtimeType == type;
  }

  static CommandUseCaseError listOf(List<ModelConstraintError> errors) {
    return MultipleErrorsOccurred(
      errors.map(ModelConstraintErrorOccurred.new).toList(),
    );
  }
}

class UnexpectedErrorOccurred implements CommandUseCaseError {
  final Exception exception;
  final StackTrace stackTrace;

  UnexpectedErrorOccurred(
    this.exception,
    this.stackTrace,
  );

  @override
  bool contains(Type type) {
    return type == exception.runtimeType;
  }

  factory UnexpectedErrorOccurred.unreachable() {
    return UnexpectedErrorOccurred(
      Exception('Unreachable code reached'),
      StackTrace.empty,
    );
  }
}
