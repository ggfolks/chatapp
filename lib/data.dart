library data;

import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';

part 'data.g.dart';

enum ProfileType { person, game, channel }

abstract class Profiled {
  String get profileId;
}

abstract class Profile implements Built<Profile, ProfileBuilder> {

  String get uuid;
  ProfileType get type;
  String get name;
  String get photo;

  factory Profile ([updates(ProfileBuilder b)]) = _$Profile;
  Profile._();
}

final unknownPerson = Profile(
  (b) => b..uuid = ""
          ..type = ProfileType.person
          ..name = "?"
          ..photo = "https://api.adorable.io/avatars/128/unknownperson.png"
);

final unknownGame = Profile(
  (b) => b..uuid = ""
          ..type = ProfileType.game
          ..name = "?"
          ..photo = "https://api.adorable.io/avatars/128/unknowngame.png"
);

final unknownChannel = Profile(
  (b) => b..uuid = ""
          ..type = ProfileType.channel
          ..name = "?"
          ..photo = "https://api.adorable.io/avatars/128/unknownchannel.png"
);

abstract class ChannelStatus implements Profiled, Built<ChannelStatus, ChannelStatusBuilder> {

  String get uuid;
  String get latestMessage;
  DateTime get latestMessageTime;

  String get profileId => uuid;

  factory ChannelStatus ([updates(ChannelStatusBuilder b)]) = _$ChannelStatus;
  ChannelStatus._();
}

// TODO: should this just be channel status? with extra stuff? can we extend Built classes?
abstract class GameStatus implements Profiled, Built<GameStatus, GameStatusBuilder> {

  String get uuid;
  String get latestMessage;
  DateTime get latestMessageTime;

  String get profileId => uuid;

  factory GameStatus ([updates(GameStatusBuilder b)]) = _$GameStatus;
  GameStatus._();
}

abstract class Message implements Profiled, Built<Message, MessageBuilder> {

  String get uuid;
  String get authorId;
  String get text;
  DateTime get sentTime;
  @nullable DateTime get editedTime;
  BuiltList<String> get attachments;

  String get profileId => authorId;

  factory Message ([updates(MessageBuilder b)]) = _$Message;
  Message._();
}
