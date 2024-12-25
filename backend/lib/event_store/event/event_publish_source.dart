class EventPublishSource {
  final String aggregateRootId;
  final String aggregateRootType;
  final int aggregateRootVersion;

  EventPublishSource({
    required this.aggregateRootId,
    required this.aggregateRootType,
    required this.aggregateRootVersion,
  });
}
