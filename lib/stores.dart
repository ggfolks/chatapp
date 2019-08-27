import 'package:mobx/mobx.dart';
import 'data.dart';

part 'stores.g.dart';

class ProfileStore = _ProfileStore with _$ProfileStore;
abstract class _ProfileStore with Store {

  ObservableMap<String, Profile> profiles = ObservableMap();

  // DO: actions to request that profiles be resolveed
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
