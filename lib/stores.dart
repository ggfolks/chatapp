import 'dart:developer' as dev;
import 'package:mobx/mobx.dart';

import 'uuid.dart';
import 'data.dart';
import 'fake.dart';

part 'stores.g.dart';

class ProfilesStore = _ProfilesStore with _$ProfilesStore;
abstract class _ProfilesStore with Store {

  final profiles = ObservableMap<String, Profile>();

  /// Returns the name of the specified entity, or `?` if the entity is unknown.
  String name (String uuid) => profiles[uuid]?.name ?? unknownPerson.name;

  /// Compares two profiled entities by their profile names.
  int compareNames (Profiled a, Profiled b) => name(a.profileId).compareTo(name(b.profileId));

  // TODO: actions to request that profiles be resolveed
}

class AppStore = _AppStore with _$AppStore;
abstract class _AppStore with Store {

  @observable
  Profile self = unknownPerson;

  /// Resolved profile information.
  final profiles = new ProfilesStore();

  /// Messages for each channel.
  final channels = ObservableMap<String, ChannelStore>();
}

class GamesStore = _GamesStore with _$GamesStore;
abstract class _GamesStore with Store {

  /// Status of games this player has played.
  final games = ObservableMap<String, GameStatus>();

  /// Status of a small number of games we think this player might like.
  final discover = ObservableMap<String, GameStatus>();
}

class ChannelStore = _ChannelStore with _$ChannelStore;
abstract class _ChannelStore with Store {
  _ChannelStore ([this.profile]);

  final Profile profile;

  @observable
  Message latest;

  ObservableMap<String, Message> messages = ObservableMap();

  void sendMessage (Profile self, String text) {
    final trimmed = text.trim();
    if (trimmed.length > 0) {
      // TEMP: just add it to the local store
      final msg =   Message(
        (b) => b..uuid = Uuid.generateV4()
                ..authorId = self.uuid
                ..text = text
                ..sentTime = DateTime.now()
      );
      messages[msg.uuid] = msg;
      latest = msg;
    }
  }

  @override
  String toString () => 'Channel[name=${profile.name}, msgs=${messages.length}]';
}
