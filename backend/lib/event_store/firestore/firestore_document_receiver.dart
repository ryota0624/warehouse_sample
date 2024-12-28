import 'package:backend/event_store/event/event_header.dart';
import 'package:backend/event_store/firestore/event_store.dart';

abstract interface class EventHandlerForFirestoreDocument<T> {
  T? decodeEvent(EventHeader header, Map<String, dynamic> payload);

  Future<void> handleEvent(T event);
}

class EventReceiverOnFirestore {
  final EventHandlerForFirestoreDocument eventHandler;

  EventReceiverOnFirestore(this.eventHandler);

  Future<void> receiveDocument(Map<String, dynamic> document) async {
    final preDecodeEvent = PreDecodeEventOnFirestore.fromDocument(document);
    final event = preDecodeEvent.decode(eventHandler.decodeEvent);
    if (event != null) {
      await eventHandler.handleEvent(event);
    }
  }
}

extension EventHandlerForFirestoreDocumentExtension
    on EventHandlerForFirestoreDocument {
  EventReceiverOnFirestore get asEventReceiver =>
      EventReceiverOnFirestore(this);
}
