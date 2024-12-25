import 'package:backend/event_store/event/event.dart';
import 'package:backend/event_store/event/event_header.dart';
import 'package:protobuf/protobuf.dart' as pb;

class StorableEvent implements Event {
  @override
  final EventHeader header;

  @override
  final Map<String, dynamic> payload;

  StorableEvent({
    required this.header,
    required this.payload,
  });

  factory StorableEvent.fromProtoMessage(
    EventHeader header,
    pb.GeneratedMessage protoEvent,
  ) {
    return StorableEvent(
      header: header,
      payload: protoEvent.toProto3Json() as Map<String, dynamic>,
    );
  }
}
