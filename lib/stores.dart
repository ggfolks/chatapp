import "dart:async";
import "dart:io";

import 'package:flutter/scheduler.dart';
import "package:cloud_firestore/cloud_firestore.dart";
import "package:firebase_analytics/firebase_analytics.dart";
import "package:firebase_analytics/observer.dart";
import "package:firebase_auth/firebase_auth.dart";
import "package:firebase_core/firebase_core.dart";
import 'package:firebase_messaging/firebase_messaging.dart';
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
    List<E> toDelete = null;
    for (var oelem in set) if (!sourceData.contains(elemCodec.encode(oelem))) {
      if (toDelete == null) toDelete = new List();
      toDelete.add(oelem);
    }
    if (toDelete != null) set.removeAll(toDelete);
    for (var elem in sourceData) set.add(elemCodec.decode(elem));
  }
}

void syncMapFrom<K,V> (ObservableMap<K,V> map, DocumentSnapshot snap, String propName,
                       Codec<K> keyCodec, Codec<V> valueCodec) {
  Map<dynamic, dynamic> sourceData = snap.data[propName];
  if (sourceData != null) {
    List<K> toDelete = null;
    for (K ok in map.keys) if (!sourceData.containsKey(keyCodec.encode(ok))) {
      if (toDelete == null) toDelete = new List();
      toDelete.add(ok);
    }
    if (toDelete != null) for (K dk in toDelete) map.remove(dk);
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
  DocumentReference userRef (Uuid id) =>  store.collection("users").document(Uuid.toBase62(id));
  DocumentReference profileRef (Uuid id) => store.collection("profiles").document(Uuid.toBase62(id));
  DocumentReference privatesRef (Uuid id) => store.collection("privates").document(Uuid.toBase62(id));
  DocumentReference channelRef (Uuid id) => store.collection("channels").document(Uuid.toBase62(id));

  Message messageFromDoc (DocumentSnapshot doc) => messageFromDocWith(
    doc, Uuid.fromBase62(doc.data["sender"]));

  Message messageFromDocWith (DocumentSnapshot doc, Uuid authorId) => Message(
    (b) => b..uuid = Uuid.fromBase62(doc.documentID)
             ..authorId = authorId
             ..text = doc.data["text"]
             ..imageUrl = doc.data["image"]
             ..linkUrl = doc.data["link"]
             ..sentTime = fromTimestamp(doc.data["sent"])
             ..editedTime = fromTimestamp(doc.data["edited"])
  );
}

class UserStore = _UserStore with _$UserStore;
abstract class _UserStore with Store {
  _UserStore (this._schema, this._messaging);

  final Schema _schema;
  final FirebaseMessaging _messaging;
  final _onClear = List<Dispose>();
  final _privChannelStores = Map<Uuid, ChannelStore>();
  final _channelStores = Map<Uuid, ChannelStore>();

  /// Tracks whether we've saved a device token for the authed user.
  Uuid _tokenId = Uuid.zero;

  /// The id of the user for whom we manage data.
  @observable Uuid id = Uuid.zero;

  /// The id of the user we are authenticated as.
  /// This may differ from `id` if we've adopted the persona of a test user.
  @observable Uuid authId = Uuid.zero;

  /// The status of this user's friendships.
  final friends = ObservableMap<Uuid, FriendStatus>();

  /// The channels to which this user is subscribed.
  final channels = ObservableSet<Uuid>();

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

  /// Returns the store for the game channel with `id`.
  ChannelStore gameChannel (Uuid id) {
    assert(id != Uuid.zero);
    return _channelStores.putIfAbsent(id, () {
      final store = GameChannelStore(_schema, id);
      _onClear.add(() => store.dispose());
      return store;
    });
  }

  /// Returns the store for the private channel between this user and `friendId`.
  ChannelStore privateChannel (Uuid friendId) {
    assert(id != Uuid.zero);
    return _privChannelStores.putIfAbsent(
      friendId, () => PrivateChannelStore(_schema, friendId, id));
  }

  _updateFriendStatus (Uuid id, Uuid fid, FriendStatus status) =>
    _schema.userRef(id).updateData({"friends.$fid": encodeFriendStatus(status)});

  setUser (Uuid newId) {
    if (id != Uuid.zero) {
      id = Uuid.zero;
      friends.clear();
      channels.clear();
      _privChannelStores.clear();
      _channelStores.clear();
      for (final fn in _onClear) fn();
      _onClear.clear();

      // TODO: clear messaging token from user record
    }

    if (newId != Uuid.zero) {
      id = newId;

      final userRef = _schema.userRef(newId);
      final userSub = userRef.snapshots().listen((snap) {
        if (!snap.exists) {
          userRef.setData({
            "friends": {},
            "channels": FieldValue.arrayUnion([]),
            "created": FieldValue.serverTimestamp()
          }, merge: true);
        } else {
          syncMapFrom(friends, snap, "friends", uuidCodec, friendStatusCodec);
          syncSetFrom(channels, snap, "channels", uuidCodec);
        }
        // only save device tokens for "real" authenticated users, not test users
        if (newId == authId && newId != _tokenId) {
          _tokenId = newId;
          _saveDeviceToken(snap);
        }
      }, onError: (error) {
        print("Subscription error: $error"); // TODO: better error handling
      });
      _onClear.add(() => userSub.cancel());

      final pmsub = _schema.privatesRef(newId).collection("msgs").snapshots().listen((snap) {
        print("Got msgs snap [docs=${snap.documents.length}, changes=${snap.documentChanges.length}]");
        for (final change in snap.documentChanges) {
          switch (change.type) {
            case DocumentChangeType.added:
            case DocumentChangeType.modified:
              _gotMsgsPrivate(change.document);
              break;
            case DocumentChangeType.removed:
              _messageDeleted(Uuid.fromBase62(change.document.documentID));
              print("TODO: message was removed? ${change.document}");
              break;
          }
        }
      });
      _onClear.add(() => pmsub.cancel());

      final pssub = _schema.privatesRef(newId).collection("sent").snapshots().listen((snap) {
        print("Got sent snap [docs=${snap.documents.length}, changes=${snap.documentChanges.length}]");
        for (final change in snap.documentChanges) {
          switch (change.type) {
            case DocumentChangeType.added:
            case DocumentChangeType.modified:
              _gotSentPrivate(change.document);
              break;
            case DocumentChangeType.removed:
              print("TODO: message was removed? ${change.document}");
              break;
          }
        }
      });
      _onClear.add(() => pssub.cancel());
    }
  }

  Future<Uuid> userDidAuth (String fbid) async {
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

  joinChannel (Uuid cid) {
    assert(id != Uuid.zero);
    final batch = _schema.store.batch();
    batch.updateData(_schema.userRef(id), {
      "channels": FieldValue.arrayUnion([Uuid.toBase62(cid)])});
    batch.updateData(_schema.channelRef(cid), {
      "members": FieldValue.arrayUnion([Uuid.toBase62(id)])});
    batch.commit();
  }
  leaveChannel (Uuid cid) {
    assert(id != Uuid.zero);
    final batch = _schema.store.batch();
    batch.updateData(_schema.userRef(id), {
      "channels": FieldValue.arrayRemove([Uuid.toBase62(cid)])});
    batch.updateData(_schema.channelRef(cid), {
      "members": FieldValue.arrayRemove([Uuid.toBase62(id)])});
    batch.commit();
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
    privateChannel(recipId).receiveMessage(_schema.messageFromDocWith(doc, id));
  }

  _messageDeleted (Uuid uuid) {
    // note: because a private message has the same id in the sent and received stores, we end up
    // deleting both when either the sent or deleted message is deleted; then when the counterpart
    // is deleted, there's nothing to delete; we're not going to work too hard to correct this
    // because if you delete a private message, you should really delete both sides
    for (final store in _privChannelStores.values) store.deleteMessage(uuid);
  }

  _saveDeviceToken (DocumentSnapshot user) {
    if (Platform.isIOS) {
      // TODO: is there a better time to request notification permissions?
      // right now this will happen right after you authenticate...
      _messaging.requestNotificationPermissions(IosNotificationSettings());
      final unlisten = _messaging.onIosSettingsRegistered.listen(
        (data) =>  _writeDeviceToken(user));
      _onClear.add(() => unlisten.cancel());
    }
    else if (Platform.isAndroid) _writeDeviceToken(user);
    // else ???
  }

  _writeDeviceToken (DocumentSnapshot user) async {
    try {
      String fcmToken = await _messaging.getToken();
      if (fcmToken != null) {
        print("Got device token ${user.reference.documentID} // $fcmToken");
        final tokens = user.exists && user.data["tokens"] != null ? user.data["tokens"] : [];
        if (!tokens.contains(fcmToken)) {
          // merge in our new token info with the old stuff
          await user.reference.updateData({"tokens": FieldValue.arrayUnion([fcmToken])});
        }
        // TODO: do we want to set a "currently active token" marker to indicate that notifications
        // should only go to the active device?
      }
    } catch (error) {
      print("Failed to get messaging token: $error");
    }
  }
}

class ProfilesStore = _ProfilesStore with _$ProfilesStore;
abstract class _ProfilesStore with Store {
  _ProfilesStore (this._schema, this._user) {
    reaction((_) => _user.id, (Uuid id) {
      if (id != Uuid.zero) _resolveProfile(id);
    }, fireImmediately: true);
  }

  /// The profile that represents the authed user.
  @computed Profile get self => _profiles[_user.id] ?? unknownPerson;

  final _resolving = Set<Uuid>();

  /// Resolved profile information.
  final _profiles = ObservableMap<Uuid, Profile>();

  /// Resolved channel information.
  final channels = ObservableMap<Uuid, Profile>();

  final Schema _schema;
  final UserStore _user;

  /// Returns the name of the specified entity, or `?` if the entity is unknown.
  String name (Uuid uuid) => _profiles[uuid]?.name ?? unknownPerson.name;

  /// Compares two profiled entities by their profile names.
  int compareNames (Profiled a, Profiled b) => name(a.profileId).compareTo(name(b.profileId));

  /// Returns the ids of all resolved people profiles. NOTE: we have to operate using keys otherwise
  /// we won't get notifications from MobX about changes.
  @computed List<Profile> get people {
    final ids = _profiles.keys.where((k) => _profiles[k].type == ProfileType.person);
    return ids.map((id) => _profiles[id]).toList()..sort((a, b) => a.name.compareTo(b.name));
  }

  Profile getProfile (Uuid id) {
    final profile = _profiles[id];
    if (profile != null) return profile;

    final tempProfile = Profile(
      (b) => b..uuid = id
              ..type = ProfileType.pending
              ..name = "..."
              ..photo = "https://api.adorable.io/avatars/128/pending.png"
    );
    if (_resolving.add(id)) {
      // we cannot modify _profiles here or mobx decides to notify every previous and subsequent
      // observer of a particular profile that it needs to change even though it should ostensibly
      // only bind to the specific key we're trying to resolve; I don't fucking know why
      SchedulerBinding.instance.addPostFrameCallback((_) {
        _profiles[id] = tempProfile;
        _resolveProfile(id);
        _resolving.remove(id);
      });
    }
    return tempProfile;
  }

  /// Requests that the profile for the specified user be resolved. A placeholder profile will
  /// become available immediately and will be replaced by the real profile data when it's
  /// available. It's OK to call this method repeatedly for the same profile id.
  _resolveProfile (Uuid id) async {
    // TODO: maintain a set of queries so that we get profile updates?
    final prodoc = await _schema.profileRef(id).get();
    if (prodoc.exists) {
      try {
        final profile = _makeProfile(id, prodoc);
        print("Profile resolved $id / ${profile.name}");
        _profiles[id] = profile;
        if (profile.type == ProfileType.channel) channels[id] = profile;
      } catch (error) {
        print("Failed to decode profile $id: $prodoc");
        print(error);
      }
    }
    else print("Asked to resolve non-existent profile: $id");
  }

  /// HACK: slurps the all people profiles onto the client; we use this right now for the people
  /// tab because I don't want to bother with implementing incremental search and blah blah.
  resolveAllPeople () async {
    final people = await _schema.store.collection("profiles").
      where("type", isEqualTo: encodeProfileType(ProfileType.person)).getDocuments();
    for (final doc in people.documents) {
      final id = Uuid.fromBase62(doc.documentID);
      _profiles[id] = _makeProfile(id, doc);
    }
  }

  resolveAllChannels () async {
    final result = await _schema.store.collection("profiles").
      where("type", isEqualTo: encodeProfileType(ProfileType.channel)).getDocuments();
    for (final doc in result.documents) {
      final id = Uuid.fromBase62(doc.documentID);
      _profiles[id] = _makeProfile(id, doc);
      channels[id] = _makeProfile(id, doc);
    }
  }

  Future<void> updateProfile (Uuid id, ProfileType type, String name, String photo) async =>
    _schema.profileRef(id).setData({
      "type": encodeProfileType(type), "name": name, "photo": photo
    }, merge: true);

  void userDidAuth (Uuid id, String name, String photo) async {
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
  final Schema _schema;
  final DocumentReference _testersRef;

  _DebugStore (this._schema)
    : _testersRef = _schema.store.collection("debug").document("testers")
  {
    _testersRef.snapshots().listen((snap) {
      if (snap.exists) {
        syncSetFrom(testers, snap, "ids", uuidCodec);
      } else {
        _testersRef.setData({"ids": FieldValue.arrayUnion([])}, merge: true);
      }
    });
  }

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

  Uuid createTestChannel (String name) {
    final id = Uuid.makeV1();
    _schema.channelRef(id).setData({
      "created": FieldValue.serverTimestamp(),
      "members": [],
    });
    _schema.profileRef(id).setData({
      "name": name,
      "type": encodeProfileType(ProfileType.channel),
      "photo": "https://api.adorable.io/avatars/128/$id.png"
    });
    return id;
  }

  setTestNotif (AppStore app) {
    if (app.notifChannel != null) {
      app.notifChannel = null;
      return;
    }
    if (!app.user.channels.isEmpty) {
      final channelId = app.user.channels.first;
      app.notifChannel = NotificationChannel(ProfileType.channel, channelId);
    }
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

  void deleteMessage (Uuid id) => messages.remove(id);

  void _didSendMessage (Message msg) {}

  @override String toString () => "Channel[id=$id, msgs=${messages.length}]";
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

  @observable Message latest;

  /// Groups messages by date & aggregates repeated messages by the same author (within a time
  /// cutoff) into message lists. Returns a list of `DateTime|List<Message>` which it would be great
  /// to tell the type system about, but Dart doesn't support union types or lightweight ADTs, so
  /// dynamic it is!
  @computed List<dynamic> get aggregateMessages {
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

class GameChannelStore extends ChannelStore {
  final Schema _schema;
  final _onClear = List<Dispose>();

  GameChannelStore (this._schema, Uuid id) : super(id) {
    final msub = _schema.channelRef(id).collection("msgs").snapshots().listen((snap) {
      print("Got msgs snap [docs=${snap.documents.length}, changes=${snap.documentChanges.length}]");
      for (final change in snap.documentChanges) {
        switch (change.type) {
          case DocumentChangeType.added:
          case DocumentChangeType.modified:
            receiveMessage(_schema.messageFromDoc(change.document));
            break;
          case DocumentChangeType.removed:
            deleteMessage(Uuid.fromBase62(change.document.documentID));
            break;
        }
      }
    });
    _onClear.add(() => msub.cancel());
  }

  void _didSendMessage (Message msg) {
    final msgKey = Uuid.toBase62(msg.uuid), sent = toTimestamp(msg.sentTime);
    _schema.channelRef(id).collection("msgs").document(msgKey).setData({
      "text": msg.text, "sender": Uuid.toBase62(msg.authorId), "sent": sent
    });
  }

  void dispose () {
    _onClear.forEach((disp) => disp());
  }
}

class PrivateChannelStore extends ChannelStore {
  PrivateChannelStore (this._schema, Uuid friendId, this._selfId) : super(friendId);
  final Schema _schema;
  final Uuid _selfId;

  void _didSendMessage (Message msg) {
    final msgKey = Uuid.toBase62(msg.uuid), sent = toTimestamp(msg.sentTime);
    _schema.privatesRef(id).collection("msgs").document(msgKey).setData({
      "text": msg.text, "sender": Uuid.toBase62(msg.authorId), "sent": sent
    });
    _schema.privatesRef(_selfId).collection("sent").document(msgKey).setData({
      "text": msg.text, "recip": Uuid.toBase62(id), "sent": sent
    });
  }
}

class NotificationChannel {
  NotificationChannel([this.type, this.channelId]);
  final ProfileType type;
  final Uuid channelId;
  String toString () => "${channelId}/${type}";
}

class AppStore extends _AppStore with _$AppStore {

  // TODO: sometimes Firebase takes a while to initialize and sync; show some sort of spinny
  // "syncing" indicator at the bottom of all coversations (or on the screen somewhere) to let
  // people know they're seeing out of date info...

  static Future<AppStore> create (FirebaseOptions opts) async {
    final app = await FirebaseApp.configure(name: "tfwchat", options: opts);
    final store = Firestore(app: app);
    final schema = new Schema(store);
    final messaging = FirebaseMessaging();
    await store.settings(timestampsInSnapshotsEnabled: true);
    return AppStore._(app, FirebaseAuth.fromApp(app), store, schema,
                      new UserStore(schema, messaging), FirebaseAnalytics(), messaging);
  }

  AppStore._ ([this.app, this.auth, this.store, this.schema, this.user, this.analytics,
               this.messaging]) :
    observer = FirebaseAnalyticsObserver(analytics: analytics),
    profiles = new ProfilesStore(schema, user),
    debug = new DebugStore(schema)
  {
    auth.onAuthStateChanged.listen((fbuser) async {
      if (fbuser == null) user._userDidUnauth();
      else {
        await analytics.setUserId(fbuser.uid);
        final id = await user.userDidAuth(fbuser.uid);
        // update our profile with the latest bits from Firebase auth
        final displayName = fbuser.displayName ?? "Tester";
        final photoUrl = fbuser.photoUrl ?? "https://api.adorable.io/avatars/128/${id}.png";
        profiles.userDidAuth(id, displayName, photoUrl);
      }
    });
    _googleSignIn.onCurrentUserChanged.listen((account) async {
      if (account != null) {
        final gauth = await account.authentication;
        try {
          await auth.signInWithCredential(GoogleAuthProvider.getCredential(
            idToken: gauth.idToken, accessToken: gauth.accessToken));
          this.authStatus = "Authenticated";
        } catch (error) {
          this.authStatus = error.code;
        }
      }
    });
    _googleSignIn.signInSilently();

    // on iOS the data is merged into msg, on Android it's in a data submap...
    messaging.configure(
      onMessage: (Map<String, dynamic> msg) async {
        // nothing to display if you're already in app, we'll let the new messages
        // indicator take care of notifying you
      },
      onLaunch: (Map<String, dynamic> msg) async {
        _handleNotifyMsg(msg["data"] ?? msg);
      },
      onResume: (Map<String, dynamic> msg) async {
        _handleNotifyMsg(msg["data"] ?? msg);
      },
    );
  }

  /// Firebase services.
  final FirebaseApp app;
  final FirebaseAuth auth;
  final Firestore store;
  final FirebaseAnalytics analytics;
  final FirebaseAnalyticsObserver observer;
  final FirebaseMessaging messaging;

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

  Future<void> sendAnalyticsEvent(String name, Map<String, dynamic> params) async {
    return await analytics.logEvent(name: name, parameters: params);
  }

  Future<void> signInWithGoogle () async {
    try {
      await _googleSignIn.signIn();
    } catch (error) {
      print(error);
      this.authStatus = error.toString();
    }
  }

  Future<void> signOut () async {
    // if we're acting as a test user, clear that first
    if (user.id != user.authId) {
      user.setUser(user.authId);
    } else {
      if (_googleSignIn.currentUser != null) {
        try {
          await _googleSignIn.signOut();
        } catch (error) {
          print(error);
          this.authStatus = error.toString();
        }
      }
      await auth.signOut();
      this.authStatus = "Not authenticated";
      user._userDidUnauth();
    }
  }

  _handleNotifyMsg (Map<String, dynamic> data) {
    final channel = data["channel"];
    if (channel != null) this.notifChannel = new NotificationChannel(
      decodeProfileType(int.parse(data["type"] ?? "1")),
      Uuid.fromBase62(channel));
  }
}
abstract class _AppStore with Store {

  @observable int selTabIdx = 0;

  // set to a value when we get a channel notification, then set back to null after navigating to it
  @observable NotificationChannel notifChannel;

  @observable String authStatus = "";
}
