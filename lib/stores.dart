import "package:cloud_firestore/cloud_firestore.dart";
import "package:firebase_analytics/firebase_analytics.dart";
import "package:firebase_analytics/observer.dart";
import "package:firebase_auth/firebase_auth.dart";
import "package:firebase_core/firebase_core.dart";
import "package:google_sign_in/google_sign_in.dart";
import "package:mobx/mobx.dart";

import "uuid.dart";
import "data.dart";
import "dates.dart";

part "stores.g.dart";

// bits to sync between Firebase sets (arrays) & maps and MobX sets & maps
abstract class Codec<T> {
  dynamic encode (T value);
  T decode (dynamic value);
}

void syncSetFrom<E> (ObservableSet<E> set, DocumentSnapshot snap, String propName,
                     Codec<E> elemCodec) {
  List<dynamic> sourceData = snap.data[propName];
  if (sourceData != null) {
    for (var oelem in set) if (!sourceData.contains(elemCodec.encode(oelem))) set.remove(oelem);
    for (var elem in sourceData) set.add(elemCodec.decode(elem));
  }
}

void syncMapFrom<K,V> (ObservableMap<K,V> map, DocumentSnapshot snap, String propName,
                       Codec<K> keyCodec, Codec<V> valueCodec) {
  Map<dynamic, dynamic> sourceData = snap.data[propName];
  if (sourceData != null) {
    for (K ok in map.keys) if (!sourceData.containsKey(keyCodec.encode(ok))) map.remove(ok);
    sourceData.forEach((k, v) => map[keyCodec.decode(k)] = valueCodec.decode(v));
  }
}

Dispose syncMapTo<K,V> (ObservableMap<K,V> map, DocumentReference doc, String propName,
                        Codec<K> keyCodec, Codec<V> valueCodec) {
  // TODO
  return map.observe((change) {
    switch (change.type) {
      case OperationType.add:
      case OperationType.update:
      case OperationType.remove:
    }
  });
}

class IdentCodec extends Codec<dynamic> {
  dynamic encode (dynamic value) => value;
  dynamic decode (dynamic value) => value;
}
final identCodec = new IdentCodec();

class UuidCodec extends Codec<Uuid> {
  String encode (Uuid key) => Uuid.toBase62(key);
  Uuid decode (dynamic raw) => Uuid.fromBase62(raw);
}
final uuidCodec = new UuidCodec();

class FriendStatusCodec extends Codec<FriendStatus> {
  int encode (FriendStatus value) => encodeFriendStatus(value);
  FriendStatus decode (dynamic raw) => decodeFriendStatus(raw);
}
final friendStatusCodec = new FriendStatusCodec();

class Schema {
  final Firestore store;
  Schema(this.store);

  DocumentReference authRef (String fbid) => store.collection("auth").document(fbid);
  DocumentReference userRef (Uuid id) =>  store.collection("users").document(id.toString());
  DocumentReference profileRef (Uuid id) => store.collection("profiles").document(id.toString());
  DocumentReference privatesRef (Uuid id) => store.collection("privates").document(id.toString());

  Message messageFromDoc (DocumentSnapshot doc) => Message(
    (b) => b..uuid = Uuid.fromBase62(doc.documentID)
            ..text = doc.data["text"]
            ..authorId = Uuid.fromBase62(doc.data["sender"])
            ..sentTime = fromTimestamp(doc.data["sent"])
            ..editedTime = fromTimestamp(doc.data["edited"])
    // TODO: attachments
  );
}

class UserStore = _UserStore with _$UserStore;
abstract class _UserStore with Store {
  _UserStore (this._schema);

  final _privChannelStores = Map<Uuid, ChannelStore>();

  /// The id of the user for whom we manage data.
  @observable Uuid id = Uuid.zero;

  /// The id of the user we are authenticated as.
  /// This may differ from `id` if we've adopted the persona of a test user.
  @observable Uuid authId = Uuid.zero;

  /// The status of this user's friendships.
  final friends = ObservableMap<Uuid, FriendStatus>();

  /// The channels to which this user is subscribed.
  final channels = ObservableMap<Uuid, FriendStatus>();

  void inviteFriend (Uuid fid) {
    final status = friends[fid];
    if (status != null && status != FriendStatus.none) {
      print("Existing status for invite $fid, have $status.");
    } else {
      print("Sent friend request from $id to $fid");
      _updateFriendStatus(id, fid, FriendStatus.sent);
      _updateFriendStatus(fid, id, FriendStatus.received);
    }
  }

  void rescindInvite (Uuid fid) {
    final status = friends[fid];
    if (status != FriendStatus.sent) {
      print("No sent invite for rescind $fid, status: $status.");
    } else {
      _updateFriendStatus(id, fid, FriendStatus.none);
      _updateFriendStatus(fid, id, FriendStatus.none);
    }
  }

  void acceptInvite (Uuid fid) {
    final status = friends[fid];
    if (status != FriendStatus.received) {
      print("No received invite for accept $fid, status: $status.");
    } else {
      _updateFriendStatus(id, fid, FriendStatus.accepted);
      _updateFriendStatus(fid, id, FriendStatus.accepted);
    }
  }

  void declineInvite (Uuid fid) {
    final status = friends[fid];
    if (status != FriendStatus.received) {
      print("No received invite for decline $fid, status: $status.");
    } else {
      _updateFriendStatus(id, fid, FriendStatus.declined);
      _updateFriendStatus(fid, id, FriendStatus.declined);
    }
  }

  /// Returns the store for the private channel between this user and `friendId`.
  ChannelStore privateChannel (Uuid friendId) {
    assert(id != Uuid.zero);
    return _privChannelStores.putIfAbsent(id, () => PrivateChannelStore(_schema, friendId, id));
  }

  _updateFriendStatus (Uuid id, Uuid fid, FriendStatus status) =>
    _schema.userRef(id).updateData({"friends.$fid": encodeFriendStatus(status)});

  final Schema _schema;
  final _onClear = List<Dispose>();

  setUser (Uuid newId) {
    if (id != Uuid.zero) {
      id = Uuid.zero;
      friends.clear();
      channels.clear();
      _privChannelStores.clear();
      for (final fn in _onClear) fn();
      _onClear.clear();
    }

    if (newId != Uuid.zero) {
      id = newId;

      final userRef = _schema.userRef(newId);
      // _onClear.add(syncMapTo(friends, userRef, 'friends', Uuid.toBase62, encodeFriendStatus));
      final userSub = userRef.snapshots().listen((snap) {
        if (!snap.exists) {
          userRef.setData({"friends": {}, "created": FieldValue.serverTimestamp()}, merge: true);
        } else {
          // if (snap.data["channels"] == null) userRef.updateData({"channels": {}});
          syncMapFrom(friends, snap, "friends", uuidCodec, friendStatusCodec);
          // TODO: ChannelSyncer
        }
      }, onError: (error) {
        print("Subscription error: $error"); // TODO: better error handling
      });
      _onClear.add(() => userSub.cancel());

      final privMsgsRef = _schema.privatesRef(newId).collection("msgs");
      final pmSub = privMsgsRef.snapshots().listen((snap) {
        print("Got msgs snap [docs=${snap.documents.length}, changes=${snap.documentChanges.length}]");
        for (final change in snap.documentChanges) {
          switch (change.type) {
            case DocumentChangeType.added:
            case DocumentChangeType.modified:
              _gotMsgsPrivate(change.document);
              break;
            case DocumentChangeType.removed:
              print("TODO: messgae was removed? ${change.document}");
              break;
          }
        }
      });
      _onClear.add(() => pmSub.cancel());

      final privSentRef = _schema.privatesRef(newId).collection("sent");
      final psSub = privSentRef.snapshots().listen((snap) {
        print("Got sent snap [docs=${snap.documents.length}, changes=${snap.documentChanges.length}]");
        for (final change in snap.documentChanges) {
          switch (change.type) {
            case DocumentChangeType.added:
            case DocumentChangeType.modified:
              _gotSentPrivate(change.document);
              break;
            case DocumentChangeType.removed:
              print("TODO: messgae was removed? ${change.document}");
              break;
          }
        }
      });
      _onClear.add(() => psSub.cancel());
    }
  }

  Future<Uuid> _userDidAuth (String fbid) async {
    // see if we already have a mapping from the Firebase id to tfw uuid
    final authRef = _schema.authRef(fbid);
    var id = Uuid.zero;
    await _schema.store.runTransaction((tx) async {
      final selfDoc = await tx.get(authRef);
      if (selfDoc.exists) {
        id = Uuid.fromBase62(selfDoc.data["id"]);
        // we have to write something in a transaction, so write a last authed timestamp... meh
        await tx.update(authRef, {"lastAuth": FieldValue.serverTimestamp()});
      } else {
        id = Uuid.makeV1();
        await tx.set(authRef, {"id": id.toString(), "lastAuth": FieldValue.serverTimestamp()});
        // TODO: also add email, auth provider type, other stuff?
      }
    });
    authId = id;
    setUser(id);
    return id;
  }

  _userDidUnauth () {
    if (id == authId) setUser(Uuid.zero);
    authId = Uuid.zero;
  }

  _gotMsgsPrivate (DocumentSnapshot doc) {
    final msg = _schema.messageFromDoc(doc);
    privateChannel(msg.authorId).receiveMessage(msg);
  }

  _gotSentPrivate (DocumentSnapshot doc) {
    final recipId = Uuid.fromBase62(doc.data["recip"]);
    privateChannel(recipId).receiveMessage(Message(
      (b) => b..uuid = Uuid.fromBase62(doc.documentID)
              ..text = doc.data["text"]
              ..authorId = id
              ..sentTime = fromTimestamp(doc.data["sent"])
              ..editedTime = fromTimestamp(doc.data["edited"])
      // TODO: attachments
    ));
  }
}

class ProfilesStore = _ProfilesStore with _$ProfilesStore;
abstract class _ProfilesStore with Store {
  _ProfilesStore (this._schema, this._user) {
    reaction((_) => _user.id, (Uuid id) {
      if (id != Uuid.zero) resolveProfile(id);
    }, fireImmediately: true);
  }

  /// The profile that represents the authed user.
  @computed Profile get self => profiles[_user.id] ?? unknownPerson;

  /// Resolved profile information.
  final profiles = ObservableMap<Uuid, Profile>();

  final Schema _schema;
  final UserStore _user;

  /// Returns the name of the specified entity, or `?` if the entity is unknown.
  String name (Uuid uuid) => profiles[uuid]?.name ?? unknownPerson.name;

  /// Compares two profiled entities by their profile names.
  int compareNames (Profiled a, Profiled b) => name(a.profileId).compareTo(name(b.profileId));

  /// Returns the ids of all resolved people profiles. NOTE: we have to operate using keys otherwise
  /// we won't get notifications from MobX about changes.
  @computed List<Profile> get people {
    final ids = profiles.keys.where((k) => profiles[k].type == ProfileType.person);
    return ids.map((id) => profiles[id]).toList()..sort((a, b) => a.name.compareTo(b.name));
  }

  /// Requests that the profile for the specified user be resolved. A placeholder profile will
  /// become available immediately and will be replaced by the real profile data when it's
  /// available. It's OK to call this method repeatedly for the same profile id.
  resolveProfile (Uuid id) async {
    if (profiles.containsKey(id)) return;
    // put a "pending" placeholder into the profiles map
    profiles[id] = Profile(
      (b) => b..uuid = id
              ..type = ProfileType.pending
              ..name = "..."
              ..photo = "https://api.adorable.io/avatars/128/pending.png" // TODO
    );
    // TODO: maintain a set of queries so that we get profile updates?
    final profile = await _schema.profileRef(id).get();
    if (profile.exists) profiles[id] = _makeProfile(id, profile);
    else print("Asked to resolve non-existent profile: $id");
  }

  /// HACK: slurps the all people profiles onto the client; we use this right now for the people
  /// tab because I don't want to bother with implementing incremental search and blah blah.
  resolveAllPeople () async {
    final people = await _schema.store.collection("profiles").
      where("type", isEqualTo: 1).getDocuments();
    for (final doc in people.documents) {
      final id = Uuid.fromBase62(doc.documentID);
      profiles[id] = _makeProfile(id, doc);
    }
  }

  Future<void> updateProfile (Uuid id, ProfileType type, String name, String photo) async =>
    _schema.profileRef(id).setData({
      "type": encodeProfileType(type), "name": name, "photo": photo
    }, merge: true);

  void _userDidAuth (Uuid id, String name, String photo) async {
    // TEMP: update our profile data with the latest Googly bits
    updateProfile(id, ProfileType.person, name, photo);
  }

  Profile _makeProfile (Uuid id, DocumentSnapshot snap) => Profile(
    (b) => b..uuid = id
            ..type = decodeProfileType(snap.data["type"])
            ..name = snap.data["name"]
            ..photo = snap.data["photo"]
  );
}

class DebugStore = _DebugStore with _$DebugStore;
abstract class _DebugStore with Store {
  _DebugStore (this._schema) : _testersRef = _schema.store.collection("debug").document("testers") {
    _testersRef.snapshots().listen((snap) {
      if (snap.exists) {
        syncSetFrom(testers, snap, "ids", uuidCodec);
      } else {
        _testersRef.setData({"ids": FieldValue.arrayUnion([])}, merge: true);
      }
    });
  }

  final Schema _schema;
  final DocumentReference _testersRef;

  /// Known test users.
  final testers = ObservableSet<Uuid>();

  void createTestUser (String name) {
    final id = Uuid.makeV1();
    _schema.userRef(id).setData({"created": FieldValue.serverTimestamp()});
    _schema.profileRef(id).setData({
      "name": name,
      "type": ProfileType.person,
      "photo": "https://api.adorable.io/avatars/128/$id.png"
    });
    _testersRef.setData({"ids": FieldValue.arrayUnion([id.toString()])}, merge: true);
  }
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

class ChannelStore extends _ChannelStore with _$ChannelStore {
  ChannelStore ([this.id]);
  final Uuid id;

  void receiveMessage (Message msg) {
    messages[msg.uuid] = msg;
  }

  void sendMessage (Profile self, String text) {
    final trimmed = text.trim();
    if (trimmed.length > 0) {
      final msg = Message(
        (b) => b..uuid = Uuid.makeV1()
                ..authorId = self.uuid
                ..text = text
                ..sentTime = DateTime.now()
      );
      // add it to the local store and pass it on to be sent
      messages[msg.uuid] = msg;
      // TODO: have messages include a sent status & replace this message with the received one when
      // we hear back from the server...
      _didSendMessage(msg);
    }
  }

  void _didSendMessage (Message msg) {}

  @override
  String toString () => "Channel[id=$id, msgs=${messages.length}]";
}
abstract class _ChannelStore with Store {
  _ChannelStore () {
    messages.observe((change) {
      if (change.type == OperationType.add) {
        if (latest == null || latest.sentTime.isBefore(change.newValue.sentTime)) {
          latest = change.newValue;
        }
      }
    });
  }

  ObservableMap<Uuid, Message> messages = ObservableMap();

  @observable
  Message latest;

  /// Groups messages by date & aggregates repeated messages by the same author (within a time
  /// cutoff) into message lists. Returns a list of `DateTime|List<Message>` which it would be great
  /// to tell the type system about, but Dart doesn't support union types or lightweight ADTs, so
  /// dynamic it is!
  @computed
  List<dynamic> get aggregateMessages {
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
}

DateTime fromTimestamp (Timestamp stamp) => stamp == null ? null : stamp.toDate().toLocal();
Timestamp toTimestamp (DateTime date) => date == null ? null : Timestamp.fromDate(date.toUtc());

class PrivateChannelStore extends ChannelStore {
  PrivateChannelStore (this._schema, Uuid friendId, this._selfId) : super(friendId);
  final Schema _schema;
  final Uuid _selfId;

  void _didSendMessage (Message msg) {
    final msgKey = Uuid.toBase62(msg.uuid);
    final sent = toTimestamp(msg.sentTime), edited = toTimestamp(msg.editedTime);
    _schema.privatesRef(id).collection("msgs").document(msgKey).setData({
      "text": msg.text, "sender": Uuid.toBase62(msg.authorId), "sent": sent, "edited": edited
      // TODO: attachments
    });
    _schema.privatesRef(_selfId).collection("sent").document(msgKey).setData({
      "text": msg.text, "recip": Uuid.toBase62(id), "sent": sent, "edited": edited
      // TODO: attachments
    });
  }
}

class AppStore extends _AppStore with _$AppStore {

  static Future<AppStore> create (FirebaseOptions opts) async {
    final app = await FirebaseApp.configure(name: "tfwchat", options: opts);
    final store = Firestore(app: app);
    final schema = new Schema(store);
    await store.settings(timestampsInSnapshotsEnabled: true);
    return AppStore._(app, FirebaseAuth.fromApp(app), store, schema, new UserStore(schema),
                      FirebaseAnalytics());
  }

  AppStore._ ([this.app, this.auth, this.store, this.schema, this.user, this.analytics]) :
    observer = FirebaseAnalyticsObserver(analytics: analytics),
    profiles = new ProfilesStore(schema, user),
    debug = new DebugStore(schema)
  {
    _googleSignIn.onCurrentUserChanged.listen((account) async {
      if (account == null) user._userDidUnauth();
      else {
        await analytics.setUserId(account.id);
        final id = await user._userDidAuth(account.id);
        await profiles._userDidAuth(id, account.displayName, account.photoUrl);
      }
    });
    _googleSignIn.signInSilently();
  }

  /// Firebase services.
  final FirebaseApp app;
  final FirebaseAuth auth;
  final Firestore store;
  final FirebaseAnalytics analytics;
  final FirebaseAnalyticsObserver observer;

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: <String>[
      // "email",
      // "https://www.googleapis.com/auth/contacts.readonly",
    ],
  );

  /// Defines some basic aspects of our Firestore schema.
  final Schema schema;

  /// Tracks private info for authed user.
  final UserStore user;

  /// Tracks profile info for all users.
  final ProfilesStore profiles;

  /// Handles debug information users.
  final DebugStore debug;

  /// Messages for each channel.
  final channels = ObservableMap<Uuid, ChannelStore>();

  Future<void> sendAnalyticsEvent(String name, Map<String, dynamic> params) async {
    return await analytics.logEvent(name: name, parameters: params);
  }

  Future<void> signIn () async {
    try {
      await _googleSignIn.signIn();
    } catch (error) {
      // TODO: stick error somewhere useful
      print(error);
    }
  }

  Future<void> signOut () async {
    // TODO: if we're signed in via username/password we need to sign out differently?

    // if we're acting as a test user, clear that first
    if (user.id != user.authId) {
      user.setUser(user.authId);
    } else try {
      await _googleSignIn.signOut();
    } catch (error) {
      // TODO: stick error somewhere useful
      print(error);
    }
  }
}

abstract class _AppStore with Store {
}
