// import 'dart:developer' as dev;
import 'package:mobx/mobx.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_analytics/observer.dart';

import 'uuid.dart';
import 'data.dart';

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

class AppStore extends _AppStore with _$AppStore {

  factory AppStore () {
    final analytics = FirebaseAnalytics();
    return AppStore._(analytics, FirebaseAnalyticsObserver(analytics: analytics));
  }

  AppStore._ ([this.analytics, this.observer]);

  final FirebaseAnalytics analytics;
  final FirebaseAnalyticsObserver observer;

  /// Resolved profile information.
  final profiles = new ProfilesStore();

  /// Messages for each channel.
  final channels = ObservableMap<String, ChannelStore>();

  Future<void> setUserId (String uuid) async {
    await analytics.setUserId(uuid);
    // TODO: look up profile data?
    this.self = Profile(
      (b) => b..uuid = uuid
              ..type = ProfileType.person
              ..name = "?"
              ..photo = "https://api.adorable.io/avatars/128/$uuid.png"
    );
  }

  Future<void> sendAnalyticsEvent(String name, Map<String, dynamic> params) async {
    return await analytics.logEvent(name: name, parameters: params);
  }
}

abstract class _AppStore with Store {
  @observable
  Profile self = unknownPerson;
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
