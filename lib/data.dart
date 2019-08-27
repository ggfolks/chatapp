library data;

import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';

part 'data.g.dart';

enum ProfileType { person, game, channel }

abstract class Profile implements Built<Profile, ProfileBuilder> {

  String get uuid;
  ProfileType get type;
  String get name;
  String get photo;

  factory Profile ([updates(ProfileBuilder b)]) = _$Profile;
  Profile._();
}

abstract class ChannelStatus implements Built<ChannelStatus, ChannelStatusBuilder> {

  String get uuid;
  String get latestMessage;
  DateTime get latestMessageTime;

  factory ChannelStatus ([updates(ChannelStatusBuilder b)]) = _$ChannelStatus;
  ChannelStatus._();
}

// DO: should this just be channel status? with extra stuff? can we extend Built classes?
abstract class GameStatus implements Built<GameStatus, GameStatusBuilder> {

  String get uuid;
  String get latestMessage;
  DateTime get latestMessageTime;

  factory GameStatus ([updates(GameStatusBuilder b)]) = _$GameStatus;
  GameStatus._();
}

abstract class Message implements Built<Message, MessageBuilder> {

  String get uuid;
  String get authorID;
  String get text;
  DateTime get sentTime;
  DateTime get editedTime;
  BuiltList<String> get attachments;

  factory Message ([updates(MessageBuilder b)]) = _$Message;
  Message._();
}
