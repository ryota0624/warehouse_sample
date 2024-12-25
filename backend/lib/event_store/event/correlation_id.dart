class CorrelationId {
  final String value;

  CorrelationId(this.value);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CorrelationId &&
          runtimeType == other.runtimeType &&
          value == other.value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => '$value';
}
