import 'event_header.dart';

abstract class Event {
  EventHeader get header;

  Map<String, dynamic> get payload;
}
