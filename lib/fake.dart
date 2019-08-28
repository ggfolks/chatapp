import 'uuid.dart';
import 'data.dart';
import 'stores.dart';

var testy = Profile(
  (b) => b..uuid = Uuid.generateV4()
          ..type = ProfileType.person
          ..name = "Testy Testerson"
          ..photo = "https://api.adorable.io/avatars/128/testytesterson.png");

var elvis = Profile(
  (b) => b..uuid = Uuid.generateV4()
          ..type = ProfileType.person
          ..name = "Elvis Presley"
          ..photo = "https://api.adorable.io/avatars/128/elvispresley.png");

var rancho = Profile(
  (b) => b..uuid = Uuid.generateV4()
          ..type = ProfileType.channel
          ..name = "Rancho Kookamunga"
          ..photo = "https://api.adorable.io/avatars/128/ranchokookamunga.png");

var pinball = Profile(
  (b) => b..uuid = Uuid.generateV4()
          ..type = ProfileType.channel
          ..name = "Pinball Wizards"
          ..photo = "https://api.adorable.io/avatars/128/pinballwizards.png");

ProfilesStore fakeProfilesStore () {
  var store = ProfilesStore();
  store.profiles[testy.uuid] = testy;
  store.profiles[elvis.uuid] = elvis;
  store.profiles[rancho.uuid] = rancho;
  store.profiles[pinball.uuid] = pinball;
  return store;
}

var testyElvisChat = [
  Message(
    (b) => b..uuid = Uuid.generateV4()
            ..authorId = testy.uuid
            ..text = "Hey Elvis, does it smell like updog in here to you?"
            ..sentTime = DateTime(2019, 8, 27, 10, 18)),
  Message(
    (b) => b..uuid = Uuid.generateV4()
            ..authorId = elvis.uuid
            ..text = "What's updog?"
            ..sentTime = DateTime(2019, 8, 27, 10, 20)),
  Message(
    (b) => b..uuid = Uuid.generateV4()
            ..authorId = testy.uuid
            ..text = "Not much, what's up with you?"
            ..sentTime = DateTime(2019, 8, 27, 10, 21)),

  Message(
    (b) => b..uuid = Uuid.generateV4()
            ..authorId = elvis.uuid
            ..text = "Any more jokes today Testy?"
            ..sentTime = DateTime(2019, 8, 28, 8, 20)),
  Message(
    (b) => b..uuid = Uuid.generateV4()
            ..authorId = testy.uuid
            ..text = "Where do polar bears keep their money?"
            ..sentTime = DateTime(2019, 8, 28, 8, 21)),
  Message(
    (b) => b..uuid = Uuid.generateV4()
            ..authorId = testy.uuid
            ..text = "In snow banks!"
            ..sentTime = DateTime(2019, 8, 28, 8, 22)),
  Message(
    (b) => b..uuid = Uuid.generateV4()
            ..authorId = elvis.uuid
            ..text = "🙄"
            ..sentTime = DateTime(2019, 8, 28, 8, 24)),
];

var ranchoChat = [
  Message(
    (b) => b..uuid = Uuid.generateV4()
            ..authorId = testy.uuid
            ..text = "This ranch is the best. I love all our little monchies!"
            ..sentTime = DateTime(2019, 8, 27, 1, 18)),
  Message(
    (b) => b..uuid = Uuid.generateV4()
            ..authorId = elvis.uuid
            ..text = "Yeah, they are pretty cute."
            ..sentTime = DateTime(2019, 8, 27, 1, 20)),
  Message(
    (b) => b..uuid = Uuid.generateV4()
            ..authorId = testy.uuid
            ..text = "Did you see when little Billy puked up a furball in Fluffy's water dish?"
            ..sentTime = DateTime(2019, 8, 27, 1, 22)),
  Message(
    (b) => b..uuid = Uuid.generateV4()
            ..authorId = testy.uuid
            ..text = "So adorbs!"
            ..sentTime = DateTime(2019, 8, 27, 1, 23)),
  Message(
    (b) => b..uuid = Uuid.generateV4()
            ..authorId = elvis.uuid
            ..text = "Then Fluffy ate it. OMG, lol!"
            ..sentTime = DateTime(2019, 8, 27, 1, 24)),
];

var pinballChat = [
  Message(
    (b) => b..uuid = Uuid.generateV4()
            ..authorId = testy.uuid
            ..text = "We are the best wizards!"
            ..sentTime = DateTime(2019, 8, 26, 10, 18)),
  Message(
    (b) => b..uuid = Uuid.generateV4()
            ..authorId = elvis.uuid
            ..text = "I guess. We're pretty good."
            ..sentTime = DateTime(2019, 8, 26, 10, 20)),
  Message(
    (b) => b..uuid = Uuid.generateV4()
            ..authorId = testy.uuid
            ..text = "Srlsy dude. We cast fancy magicks, no?"
            ..sentTime = DateTime(2019, 8, 26, 10, 22)),
  Message(
    (b) => b..uuid = Uuid.generateV4()
            ..authorId = testy.uuid
            ..text = "Our island will live forever!"
            ..sentTime = DateTime(2019, 8, 26, 10, 23)),
  Message(
    (b) => b..uuid = Uuid.generateV4()
            ..authorId = elvis.uuid
            ..text = "True, true. We has wiz skillz."
            ..sentTime = DateTime(2019, 8, 26, 10, 24)),
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

ChannelStore fakeChannelStore (Profile profile, List<Message> messages) {
  var store = ChannelStore(profile);
  for (final msg in messages) store.messages[msg.uuid] = msg;
  return store;
}

ChannelStore channelStore (Profile profile) {
  if (profile.uuid == rancho.uuid) return fakeChannelStore(profile, ranchoChat);
  else if (profile.uuid == pinball.uuid) return fakeChannelStore(profile, pinballChat);
  else if (profile.uuid == elvis.uuid) return fakeChannelStore(profile, testyElvisChat);
  else throw new ArgumentError('No fake store for $profile');
}
