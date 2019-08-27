import 'package:mobx/mobx.dart';
import 'data.dart';

part 'stores.g.dart';

class ProfilesStore = _ProfilesStore with _$ProfilesStore;
abstract class _ProfilesStore with Store {

  ObservableMap<String, Profile> profiles = ObservableMap();

  /// Returns the name of the specified entity, or `?` if the entity is unknown.
  String name (String uuid) => profiles[uuid]?.name ?? unknownPerson.name;

  /// Compares two profiled entities by their profile names.
  int compareNames (Profiled a, Profiled b) => name(a.profileId).compareTo(name(b.profileId));

  // TODO: actions to request that profiles be resolveed
}

class ChannelsStore = _ChannelsStore with _$ChannelsStore;
abstract class _ChannelsStore with Store {

  /// Channels to which the player is subscribed.
  ObservableMap<String, ChannelStatus> channels = ObservableMap();

  /// Private chats with other players.
  ObservableMap<String, ChannelStatus> privates = ObservableMap();
}

class GamesStore = _GamesStore with _$GamesStore;
abstract class _GamesStore with Store {

  /// Status of games this player has played.
  ObservableMap<String, GameStatus> games = ObservableMap();

  /// Status of a small number of games we think this player might like.
  ObservableMap<String, GameStatus> discover = ObservableMap();
}

class ChannelStore = _ChannelStore with _$ChannelStore;
abstract class _ChannelStore with Store {
  _ChannelStore ([this.profile]);

  final Profile profile;

  ObservableMap<String, Message> messages = ObservableMap();
}
