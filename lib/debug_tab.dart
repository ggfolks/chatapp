import "package:flutter/cupertino.dart";
import "package:flutter/material.dart";
import "package:flutter_mobx/flutter_mobx.dart";

import "data.dart";
import "message_view.dart";
import "stores.dart";
import "ui.dart";
import "uuid.dart";

int friendCount (Map<Uuid, FriendStatus> friends, FriendStatus status) =>
  friends.values.where((s) => s == status).length;

List<Widget> testUserRows (AppStore app) {
  final rows = List<Widget>();
  for (final id in app.debug.testers) {
    rows.add(Observer(builder: (ctx) {
      final profile = app.profiles.getProfile(id);
      final amTesting = app.user.id == id;
      return new ProfileRow(profile)..addIcon(
        amTesting ? CupertinoIcons.minus_circled : CupertinoIcons.plus_circled,
        () => app.user.setUser(amTesting ? app.user.authId: id),
        // ..addIcon(
        //   CupertinoIcons.delete,
        //   () {
        //     print("TODO: delete");
        //   })
      );
    }));
  }
  if (rows.length == 0) rows.add(Text("No test users."));
  rows.add(TestUserAdder(app));
  return rows;
}

List<Widget> testChannelRows (AppStore app) {
  final rows = List<Widget>();
  for (final id in app.profiles.channels.keys) {
    rows.add(Observer(builder: (ctx) {
      final profile = app.profiles.getProfile(id);
      final amMember = app.user.channels.contains(id);
      return new ProfileRow(profile)..addIcon(
        amMember ? CupertinoIcons.minus_circled : CupertinoIcons.plus_circled,
        () {
          if (amMember) app.user.leaveChannel(id);
          else app.user.joinChannel(id);
        }
      );
    }));
  }
  if (rows.length == 0) rows.add(Text("No channels."));
  rows.add(TestChannelAdder(app));
  return rows;
}

class TestUserAdder extends StatefulWidget {
  TestUserAdder (this.app);
  final AppStore app;
  @override _TestUserAdderState createState () => _TestUserAdderState(app);
}

class _TestUserAdderState extends State<TestUserAdder> {
  _TestUserAdderState(this.app);
  final AppStore app;
  final textController = TextEditingController();

  @override void dispose () {
    textController.dispose();
    super.dispose();
  }

  @override Widget build (BuildContext ctx) {
    return Row(
      children: [
        Expanded(child: TextField(
          controller: textController,
          decoration: InputDecoration(border: InputBorder.none, hintText: "Test user name"),
        )),
        RaisedButton(child: const Text("Create"), onPressed: () {
          final name = textController.text.trim();
          if (name.length > 0) {
            textController.text = "";
            app.debug.createTestUser(name);
          }
        })
      ]
    );
  }
}

class TestChannelAdder extends StatefulWidget {
  TestChannelAdder (this.app);
  final AppStore app;
  @override _TestChannelAdderState createState () => _TestChannelAdderState(app);
}

class _TestChannelAdderState extends State<TestChannelAdder> {
  _TestChannelAdderState(this.app);
  final AppStore app;
  final textController = TextEditingController();

  @override void dispose () {
    textController.dispose();
    super.dispose();
  }

  @override Widget build (BuildContext ctx) {
    return Row(
      children: [
        Expanded(child: TextField(
          controller: textController,
          decoration: InputDecoration(border: InputBorder.none, hintText: "Test channel name"),
        )),
        RaisedButton(child: const Text("Create"), onPressed: () {
          final name = textController.text.trim();
          if (name.length > 0) {
            textController.text = "";
            app.debug.createTestChannel(name);
          }
        })
      ]
    );
  }
}

List<List<Message>> testMessages () => [[
  Message(
    (b) => b..uuid = Uuid.makeV1()
            ..text = "This is a test of the message rendering system."
            ..authorId = Uuid.fromBase62("4Xmju8MzbGw3OegRJCqPon")
            ..sentTime = DateTime.now()
  ),
  Message(
    (b) => b..uuid = Uuid.makeV1()
            ..text = "Do not pass go, do not collect \$200."
            ..authorId = Uuid.fromBase62("4Xmju8MzbGw3OegRJCqPon")
            ..sentTime = DateTime.now()
  )
], [
  Message(
    (b) => b..uuid = Uuid.makeV1()
            ..text = "How about another message? Who doesn't love a message?"
            ..authorId = Uuid.fromBase62("6UCKQwTbWNLUUfnsyBwpFE")
            ..sentTime = DateTime.now()
  )
], [
  Message(
    (b) => b..uuid = Uuid.makeV1()
            ..text = "Here comes one with an image!"
            ..authorId = Uuid.fromBase62("7814oAqssE3c8PNMDeldiw")
            ..sentTime = DateTime.now()
            ..imageUrl = "https://i.chzbgr.com/full/9121469696/hFA370D5B/"
  )
], [
  Message(
    (b) => b..uuid = Uuid.makeV1()
            ..text = "Image with a link. What fun!"
            ..authorId = Uuid.fromBase62("6UCKQwTbWNLUUfnsyBwpFE")
            ..sentTime = DateTime.now()
            ..imageUrl = "https://i.chzbgr.com/full/9121467904/h7A3C17BB/"
            ..linkUrl = "https://cheezburger.com/4665861/17-adorable-baby-owls-that-are-too-cute-to-handle"
  )
]];

class DebugTab extends StatelessWidget {
  const DebugTab([this.app]);
  final AppStore app;

  @override Widget build (BuildContext ctx) {
    final friends = app.user.friends;
    return SafeArea(
      child: CustomScrollView(slivers: [
        UI.makeHeader(ctx, "User Info"),
        Observer(builder: (ctx) => SliverSafeArea(
          minimum: const EdgeInsets.all(10),
          sliver: SliverList(delegate: SliverChildListDelegate([
            Text("User ID: ${app.user.id}"),
            Text("Auth status: ${app.authStatus}"),
            Text("Name: ${app.profiles.self.name}"),
            Text("Friend count: ${friendCount(friends, FriendStatus.accepted)}"),
            Text("Pending sent invites: ${friendCount(friends, FriendStatus.sent)}"),
            Text("Pending received invites: ${friendCount(friends, FriendStatus.received)}"),
            Text("Channel count: ${app.user.channels.length}"),
            RaisedButton(child: const Text("Sign out"), onPressed: () => app.signOut()),
          ]))
        )),
        UI.makeHeader(ctx, "Test Users"),
        Observer(builder: (ctx) => SliverSafeArea(
          minimum: const EdgeInsets.all(10),
          sliver: SliverList(delegate: SliverChildListDelegate(testUserRows(app)))
        )),
        UI.makeHeader(ctx, "Test Channels"),
        Observer(builder: (ctx) => SliverSafeArea(
          minimum: const EdgeInsets.all(10),
          sliver: SliverList(delegate: SliverChildListDelegate(testChannelRows(app)))
        )),
        UI.makeHeader(ctx, "Test Notifications"),
        Observer(builder: (ctx) => SliverSafeArea(
          minimum: const EdgeInsets.all(10),
          sliver: SliverList(delegate: SliverChildListDelegate([
            Text("Notif channel: ${app.notifChannel}"),
            RaisedButton(child: const Text("Set test notif"),
                         onPressed: () => app.debug.setTestNotif(app)),
          ]))
        )),
        UI.makeHeader(ctx, "Test Message Views"),
        SliverSafeArea(
          minimum: const EdgeInsets.all(10),
          sliver: SliverList(delegate: SliverChildListDelegate(
            testMessages().map((msgs) => MessageView(app, msgs)).toList()
          ))
        ),
      ]),
    );
  }
}
