import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../repositories/event_repository.dart';

// part 'providers.g.dart';

// @riverpod
// // 4. update the declaration
// EventService eventsProvider(EventsProviderRef ref) {
//   return EventService();
// }

// @riverpod
// MyEventRepository eventsRepository(EventsRepositoryRef ref) {
//   return MyEventRepository();
// }

final myEventsFutureProvider = FutureProvider((ref) async {
  return ref.watch(eventProvider).getEventsWithinMinutes(minutes: 15);
});
