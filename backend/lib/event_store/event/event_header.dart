import 'correlation_id.dart';
import 'event_publish_source.dart';

class EventHeader {
  final EventPublishSource publishSource;
  final CorrelationId correlationId;
  final DateTime occurrenceTime;

  EventHeader(
    this.publishSource,
    this.correlationId,
    this.occurrenceTime,
  );
}
