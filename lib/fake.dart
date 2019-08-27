import 'uuid.dart';
import 'data.dart';
import 'stores.dart';

var testy = Profile(
  (b) => b..uuid = Uuid.generateV4()
          ..type = ProfileType.person
          ..name = "Testy Testerson"
          ..photo = "");

var elvis = Profile(
  (b) => b..uuid = Uuid.generateV4()
          ..type = ProfileType.person
          ..name = "Elvis Presley"
          ..photo = "");

var rancho = Profile(
  (b) => b..uuid = Uuid.generateV4()
          ..type = ProfileType.channel
          ..name = "Rancho Kukamonga"
          ..photo = "");

var pinball = Profile(
  (b) => b..uuid = Uuid.generateV4()
          ..type = ProfileType.channel
          ..name = "Pinball Wizards"
          ..photo = "");

ProfileStore fakeProfileStore () {
  var store = ProfileStore();
  store.profiles[testy.uuid] = testy;
  store.profiles[elvis.uuid] = elvis;
  store.profiles[rancho.uuid] = rancho;
  store.profiles[pinball.uuid] = pinball;
  return store;
}

var testyElvisChat = [
  Message(
    (b) => b..uuid = Uuid.generateV4()
            ..authorID = testy.uuid
            ..text = "Hey Elvis, does it smell like updog in here to you?"
            ..sentTime = DateTime(2019, 8, 27, 10, 18)),
  Message(
    (b) => b..uuid = Uuid.generateV4()
            ..authorID = elvis.uuid
            ..text = "What's updog?"
            ..sentTime = DateTime(2019, 8, 27, 10, 20)),
  Message(
    (b) => b..uuid = Uuid.generateV4()
            ..authorID = testy.uuid
            ..text = "Not much, what's up with you?"
            ..sentTime = DateTime(2019, 8, 27, 10, 21)),
];

var ranchoChat = [
  Message(
    (b) => b..uuid = Uuid.generateV4()
            ..authorID = testy.uuid
            ..text = "This ranch is the best. I love all our little monchies!"
            ..sentTime = DateTime(2019, 8, 27, 10, 18)),
  Message(
    (b) => b..uuid = Uuid.generateV4()
            ..authorID = elvis.uuid
            ..text = "Yeah, they are pretty cute."
            ..sentTime = DateTime(2019, 8, 27, 10, 20)),
  Message(
    (b) => b..uuid = Uuid.generateV4()
            ..authorID = testy.uuid
            ..text = "Did you see when little Billy puked up a furball in Fluffy's water dish?"
            ..sentTime = DateTime(2019, 8, 27, 10, 22)),
  Message(
    (b) => b..uuid = Uuid.generateV4()
            ..authorID = testy.uuid
            ..text = "So adorbs!"
            ..sentTime = DateTime(2019, 8, 27, 10, 23)),
  Message(
    (b) => b..uuid = Uuid.generateV4()
            ..authorID = elvis.uuid
            ..text = "Then Fluffy at it. OMG, lol!"
            ..sentTime = DateTime(2019, 8, 27, 10, 24)),
];

var pinballChat = [
  Message(
    (b) => b..uuid = Uuid.generateV4()
            ..authorID = testy.uuid
            ..text = "This ranch is the best. I love all our little monchies!"
            ..sentTime = DateTime(2019, 8, 27, 10, 18)),
  Message(
    (b) => b..uuid = Uuid.generateV4()
            ..authorID = elvis.uuid
            ..text = "Yeah, they are pretty cute."
            ..sentTime = DateTime(2019, 8, 27, 10, 20)),
  Message(
    (b) => b..uuid = Uuid.generateV4()
            ..authorID = testy.uuid
            ..text = "Did you see when little Billy puked up a furball in Fluffy's water dish?"
            ..sentTime = DateTime(2019, 8, 27, 10, 22)),
  Message(
    (b) => b..uuid = Uuid.generateV4()
            ..authorID = testy.uuid
            ..text = "So adorbs!"
            ..sentTime = DateTime(2019, 8, 27, 10, 23)),
  Message(
    (b) => b..uuid = Uuid.generateV4()
            ..authorID = elvis.uuid
            ..text = "Then Fluffy at it. OMG, lol!"
            ..sentTime = DateTime(2019, 8, 27, 10, 24)),
];

ChannelStatus fakeStatus (String uuid, List<Message> messages) {
  return ChannelStatus(
    (b) => b..uuid = uuid
            ..latestMessage = messages.last.text
            ..latestMessageTime = messages.last.sentTime
  );
}

ChannelsStore fakeChannelsStore () {
  var store = ChannelsStore();
  store.channels[rancho.uuid] = fakeStatus(rancho.uuid, ranchoChat);
  store.channels[pinball.uuid] = fakeStatus(pinball.uuid, pinballChat);
  store.privates[elvis.uuid] = fakeStatus(elvis.uuid, testyElvisChat);
  return store;
}
