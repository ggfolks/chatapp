library data;

import 'package:built_value/built_value.dart';
import 'uuid.dart';

part 'data.g.dart';

// NOTE: these are persisted by index in the enum, do not reorder or delete, appending is OK
enum FriendStatus { none, sent, received, declined, accepted }
int encodeFriendStatus (FriendStatus status) => FriendStatus.values.indexOf(status);
FriendStatus decodeFriendStatus (int status) => FriendStatus.values[status];

enum ProfileType { pending, person, game, channel, npc }
int encodeProfileType (ProfileType type) => ProfileType.values.indexOf(type);
ProfileType decodeProfileType (int type) {
  try {
    return ProfileType.values[type];
  } catch (error) {
    print("Failed to decode profile type ($type): $error");
    return ProfileType.person;
  }
}

abstract class Profiled {
  Uuid get profileId;
}

abstract class Profile implements Built<Profile, ProfileBuilder> {

  Uuid get uuid;
  ProfileType get type;
  String get name;
  String get photo;

  factory Profile ([updates(ProfileBuilder b)]) = _$Profile;
  Profile._();
}

final unknownPerson = Profile(
  (b) => b..uuid = Uuid.zero
          ..type = ProfileType.person
          ..name = "?"
          ..photo = "https://api.adorable.io/avatars/128/unknownperson.png"
);

final unknownGame = Profile(
  (b) => b..uuid = Uuid.zero
          ..type = ProfileType.game
          ..name = "?"
          ..photo = "https://api.adorable.io/avatars/128/unknowngame.png"
);

final unknownChannel = Profile(
  (b) => b..uuid = Uuid.zero
          ..type = ProfileType.channel
          ..name = "?"
          ..photo = "https://api.adorable.io/avatars/128/unknownchannel.png"
);

abstract class ChannelStatus implements Profiled, Built<ChannelStatus, ChannelStatusBuilder> {

  Uuid get uuid;
  String get latestMessage;
  DateTime get latestMessageTime;

  Uuid get profileId => uuid;

  factory ChannelStatus ([updates(ChannelStatusBuilder b)]) = _$ChannelStatus;
  ChannelStatus._();
}

// TODO: should this just be channel status? with extra stuff? can we extend Built classes?
abstract class GameStatus implements Profiled, Built<GameStatus, GameStatusBuilder> {

  Uuid get uuid;
  String get latestMessage;
  DateTime get latestMessageTime;

  Uuid get profileId => uuid;

  factory GameStatus ([updates(GameStatusBuilder b)]) = _$GameStatus;
  GameStatus._();
}

abstract class Message implements Profiled, Built<Message, MessageBuilder> {

  Uuid get uuid;
  Uuid get authorId;
  String get text;
  DateTime get sentTime;
  @nullable DateTime get editedTime;
  @nullable String get imageUrl;
  @nullable String get linkUrl;

  Uuid get profileId => authorId;

  factory Message ([updates(MessageBuilder b)]) = _$Message;
  Message._();
}
