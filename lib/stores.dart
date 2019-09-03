import 'dart:developer' as dev;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_analytics/observer.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:mobx/mobx.dart';

import 'uuid.dart';
import 'data.dart';
import 'dates.dart';

part 'stores.g.dart';

class ProfilesStore = _ProfilesStore with _$ProfilesStore;
abstract class _ProfilesStore with Store {
  _ProfilesStore (this._store);

  /// Resolved profile information.
  final profiles = ObservableMap<Uuid, Profile>();

  final Firestore _store;

  /// Returns the name of the specified entity, or `?` if the entity is unknown.
  String name (Uuid uuid) => profiles[uuid]?.name ?? unknownPerson.name;

  /// Compares two profiled entities by their profile names.
  int compareNames (Profiled a, Profiled b) => name(a.profileId).compareTo(name(b.profileId));

  /// Requests that the profile for the specified user be resolved. A placeholder profile will
  /// become available immediately and will be replaced by the real profile data when it's
  /// available. It's OK to call this method repeatedly for the same profile id.
  resolveProfile (Uuid id, ProfileType type) async {
    if (profiles.containsKey(id)) return;
    // put a "pending" placeholder into the profiles map
    profiles[id] = Profile(
      (b) => b..uuid = id
              ..type = type
              ..name = '...'
              ..photo = "https://api.adorable.io/avatars/128/pending.png" // TODO
    );
    // TODO: maintain a set of queries so that we get profile updates?
    final profile = await _profileDoc(id).get();
    if (profile.exists) profiles[id] = Profile(
      (b) => b..uuid = id
              ..type = type
              ..name = profile.data['name']
              ..photo = profile.data['photo']
    );
    else dev.log("Asked to resolve non-existent profile: $id");
  }

  Future<Profile> _userDidAuth (String fbid, String name, String photo) async {
    // see if we already have a mapping from the Firebase id to tfw uuid
    final authRef = _store.collection("auth").document(fbid);
    var id = Uuid.zero;
    await _store.runTransaction((tx) async {
      final selfDoc = await tx.get(authRef);
      if (selfDoc.exists) {
        id = Uuid.fromBase62(selfDoc.data['id']);
        // we have to write something in a transaction, so write a last authed timestamp... meh
        await tx.update(authRef, {'lastAuth': FieldValue.serverTimestamp()});
      } else {
        id = Uuid.makeV1();
        await tx.set(authRef, {'id': id.toBase62(), 'lastAuth': FieldValue.serverTimestamp()});
        // TODO: also add email, auth provider type, other stuff?
      }
    });

    // TODO: look up profile data from our sources, don't use the Google stuff
    final self = Profile(
      (b) => b..uuid = id
              ..type = ProfileType.person
              ..name = name
              ..photo = photo
    );

    // TEMP: just update our profile data with the latest Googly bits
    _profileDoc(id).setData({
      'name': name,
      'photo': photo,
      // TODO: or maybe we just have one email that we store here?
    }, merge: true);

    profiles[self.uuid] = self;
    return self;
  }

  DocumentReference _profileDoc (Uuid id) => _store.collection('profiles').document(id.toBase62());
}

class UserStore = _UserStore with _$UserStore;
abstract class _UserStore with Store {
  _UserStore (Firestore store, this.id) {
    // TODO: subscribe to user document, populate reactive data therefrom
    // TODO: listen to changes to reactive data, write back to firestore
  }

  /// The id of the user for whom we manage data.
  final Uuid id;

  /// The status of this user's friendships.
  final friends = ObservableMap<Uuid, FriendStatus>();

}

class AppStore extends _AppStore with _$AppStore {

  static Future<AppStore> create (FirebaseOptions opts) async {
    final FirebaseApp app = await FirebaseApp.configure(name: 'tfwchat', options: opts);
    final Firestore store = Firestore(app: app);
    await store.settings(timestampsInSnapshotsEnabled: true);
    final analytics = FirebaseAnalytics();
    return AppStore._(app, store, analytics);
  }

  AppStore._ ([this.app, this.store, this.analytics]) :
    observer = FirebaseAnalyticsObserver(analytics: analytics),
    profiles = new ProfilesStore(store)
  {
    googleSignIn.onCurrentUserChanged.listen((account) async {
      if (account == null) _clearUser();
      else {
        await analytics.setUserId(account.id);
        self = await profiles._userDidAuth(account.id, account.displayName, account.photoUrl);
      }
    });
    googleSignIn.signInSilently();
  }

  /// Firebase services.
  final FirebaseApp app;
  final Firestore store;
  final FirebaseAnalytics analytics;
  final FirebaseAnalyticsObserver observer;

  final GoogleSignIn googleSignIn = GoogleSignIn(
    scopes: <String>[
      // 'email',
      // 'https://www.googleapis.com/auth/contacts.readonly',
    ],
  );

  /// Resolved profile information.
  final ProfilesStore profiles;

  /// Messages for each channel.
  final channels = ObservableMap<Uuid, ChannelStore>();

  Future<void> sendAnalyticsEvent(String name, Map<String, dynamic> params) async {
    return await analytics.logEvent(name: name, parameters: params);
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
  final games = ObservableMap<Uuid, GameStatus>();

  /// Status of a small number of games we think this player might like.
  final discover = ObservableMap<Uuid, GameStatus>();
}

bool shouldAggregate (Message earlier, Message later) {
  return (earlier.authorId == later.authorId &&
          later.sentTime.difference(earlier.sentTime).inMinutes < 5);
}

class ChannelStore = _ChannelStore with _$ChannelStore;
abstract class _ChannelStore with Store {
  _ChannelStore ([this.profile]);

  final Profile profile;

  ObservableMap<Uuid, Message> messages = ObservableMap();

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
        (b) => b..uuid = Uuid.makeV1()
                ..authorId = self.uuid
                ..text = text
                ..sentTime = DateTime.now()
      );
      messages[msg.uuid] = msg;
      latest = msg;
    }
  }

  @override
  String toString () => "Channel[name=${profile.name}, msgs=${messages.length}]";
}
