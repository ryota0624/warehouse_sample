import 'package:fpdart/fpdart.dart';

abstract interface class EventSourcingAggregateRoot<Event, Command, CommandErr,
    Self extends EventSourcingAggregateRoot<Event, Command, CommandErr, Self>> {
  Self apply(Event event);

  Either<List<CommandErr>, (Self, List<Event>)> process(Command command);
}

abstract interface class CommandProcessor<
    Command,
    CommandErr,
    Event,
    AggregateRoot extends EventSourcingAggregateRoot<Event, Command, CommandErr,
        AggregateRoot>> {
  Future<void> process(Command command);
}
