// import 'dart:developer' as dev;
import 'package:mobx/mobx.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_analytics/observer.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'uuid.dart';
import 'data.dart';
import 'dates.dart';

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

  AppStore._ ([this.analytics, this.observer]) {
    googleSignIn.onCurrentUserChanged.listen((account) {
      if (account == null) _clearUser();
      else _setUser(account.id, account.displayName, account.photoUrl);
    });
    googleSignIn.signInSilently();
  }

  final FirebaseAnalytics analytics;
  final FirebaseAnalyticsObserver observer;

  final GoogleSignIn googleSignIn = GoogleSignIn(
    scopes: <String>[
      // 'email',
      // 'https://www.googleapis.com/auth/contacts.readonly',
    ],
  );

  /// Resolved profile information.
  final profiles = new ProfilesStore();

  /// Messages for each channel.
  final channels = ObservableMap<String, ChannelStore>();

  Future<void> sendAnalyticsEvent(String name, Map<String, dynamic> params) async {
    return await analytics.logEvent(name: name, parameters: params);
  }

  void _setUser (String uuid, String name, String photo) async {
    await analytics.setUserId(uuid);
    // TODO: look up profile data from our sources, don't use the Google stuff
    self = Profile(
      (b) => b..uuid = uuid
              ..type = ProfileType.person
              ..name = name
              ..photo = photo
    );
    // TEMP: stuff this fake profile into our profiles db
    profiles.profiles[self.uuid] = self;
  }

  _clearUser () {
    self = unknownPerson;
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

bool shouldAggregate (Message earlier, Message later) {
  return (earlier.authorId == later.authorId &&
          later.sentTime.difference(earlier.sentTime).inMinutes < 5);
}

class ChannelStore = _ChannelStore with _$ChannelStore;
abstract class _ChannelStore with Store {
  _ChannelStore ([this.profile]);

  final Profile profile;

  ObservableMap<String, Message> messages = ObservableMap();

  @observable
  Message latest;

  /// Groups messages by date & aggregates repeated messages by the same author (within a time
  /// cutoff) into message lists. Returns a list of `DateTime|List<Message>` which it would be great
  /// to tell the type system about, but Dart doesn't support union types or lightweight ADTs, so
  /// dynamic it is!
  @computed
  List<dynamic> aggregateMessages () {
    // TODO: fetch messages on demand, infini-scroll through them...
    final List<Message> sorted = List.from(messages.values)
                                     ..sort((a, b) => a.sentTime.compareTo(b.sentTime));
    final rows = List();
    // intersperse date headers, aggregate messages from same author
    List<Message> row = null;
    if (sorted.length > 0) {
      DateTime headerTime = null;
      for (final msg in sorted) {
        if (headerTime == null || !sameDate(headerTime, msg.sentTime)) {
          headerTime = msg.sentTime;
          rows.add(headerTime);
          row = null;
        }
        if (row == null || !shouldAggregate(row.last, msg)) {
          row = List();
          rows.add(row);
        }
        row.add(msg);
      }
    }
    return rows;
  }

  @action
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
