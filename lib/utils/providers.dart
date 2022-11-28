import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:universal_frontend/data_models/generation_message.dart';
import 'package:universal_frontend/services/network_service.dart';
import 'package:universal_frontend/utils/emojis.dart';
import 'package:universal_frontend/utils/util.dart';

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

// final myEventsFutureProvider = FutureProvider.family<List<Event>, int>((ref, minutes) async {
//   return ref.watch(dataProvider).getEventsWithinMinutes(minutes: minutes);
// });

final myEventsFutureProvider = FutureProvider((ref) async {
  return ref.watch(dataProvider).getEventsWithinMinutes(minutes: 60);
});
final myCitiesCountFutureProvider = FutureProvider((ref) async {
  return ref.watch(dataProvider).countCities();
});

final myPlacesCountFutureProvider = FutureProvider((ref) async {
  return ref.watch(dataProvider).countPlaces();
});
final myUsersCountFutureProvider = FutureProvider((ref) async {
  return ref.watch(dataProvider).countUsers();
});
final myCityAggregateFutureProvider = FutureProvider((ref) async {
  return ref.watch(apiProvider).getCityAggregates(minutes: 60);
});

final myCityEventGeneratorProvider =
    FutureProvider.family<Future<GenerationMessage>, GenerateEventsByCityParams>((ref, params) async {
  p('$brocolli inside myCityEventGeneratorProvider ... cityId ${params.cityId}');
  return ref.watch(apiProvider).generateEventsByCity(cityId: params.cityId, count: params.count);
});
