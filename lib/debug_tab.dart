import "package:flutter/cupertino.dart";
import "package:flutter/material.dart";
import "package:flutter_mobx/flutter_mobx.dart";

import "uuid.dart";
import "data.dart";
import "stores.dart";
import "ui.dart";

int friendCount (Map<Uuid, FriendStatus> friends, FriendStatus status) =>
  friends.values.where((s) => s == status).length;

List<Widget> testRows (AppStore app) {
  final rows = List<Widget>();
  for (final id in app.debug.testers) {
    app.profiles.resolveProfile(id);
    rows.add(Observer(builder: (ctx) {
      final profile = app.profiles.profiles[id];
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
            Text("Name: ${app.profiles.self.name}"),
            Text("Friend count: ${friendCount(friends, FriendStatus.accepted)}"),
            Text("Pending sent invites: ${friendCount(friends, FriendStatus.sent)}"),
            Text("Pending received invites: ${friendCount(friends, FriendStatus.received)}"),
            Text("Channel count: ${app.user.channels.length}"),
            RaisedButton(child: const Text("Sign out"), onPressed: () => app.signOut()),
          ])))
        ),
        UI.makeHeader(ctx, "Test Users"),
        Observer(builder: (ctx) => SliverSafeArea(
          minimum: const EdgeInsets.all(10),
          sliver: SliverList(delegate: SliverChildListDelegate(testRows(app)))
        )),
      ]),
    );
  }
}