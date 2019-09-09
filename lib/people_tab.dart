import "package:flutter/cupertino.dart";
import "package:flutter/material.dart";
import "package:flutter_mobx/flutter_mobx.dart";

import "data.dart";
import "stores.dart";
import "ui.dart";

class PeopleTab extends AuthedTab {
  PeopleTab (AppStore app) : super(app);

  @override Widget buildAuthed (BuildContext ctx) {
    return SafeArea(child: Observer(builder: (ctx) {
      // filter the people list into friends, invited, declined, none
      final friends = List<Widget>();
      final invited = List<Widget>();
      final declined = List<Widget>();
      final strangers = List<Widget>();
      for (final p in app.profiles.people) {
        final status = app.user.friends[p.uuid] ?? FriendStatus.none;
        if (p.uuid == app.user.id) continue;
        switch (status) {
          case FriendStatus.none:
            strangers.add(new ProfileRow(p)
                     ..addIcon(CupertinoIcons.plus_circled, () => app.user.inviteFriend(p.uuid)));
            break;
          case FriendStatus.sent:
            invited.add(new ProfileRow(p)
                   ..addIcon(CupertinoIcons.mail, () => app.user.rescindInvite(p.uuid)));
            break;
          case FriendStatus.received:
            invited.add(new ProfileRow(p)
                   ..addIcon(CupertinoIcons.plus_circled, () => app.user.acceptInvite(p.uuid))
                   ..addIcon(CupertinoIcons.minus_circled, () => app.user.declineInvite(p.uuid)));
            break;
          case FriendStatus.declined:
            declined.add(new ProfileRow(p)..addIcon(CupertinoIcons.clear, () {})); // TODO: undecline?
            break;
          case FriendStatus.accepted:
            friends.add(new ProfileRow(p)
                   ..addIcon(CupertinoIcons.conversation_bubble, () => UI.navigateToFriend(ctx, app, p))
                   ..addIcon(CupertinoIcons.clear, () {})); // TODO: confirm unfriend
            break;
        }
      }

      final slivers = List<Widget>();
      if (!friends.isEmpty) {
        slivers.add(UI.makeHeader(ctx, "Friends"));
        slivers.add(SliverSafeArea(
          minimum: const EdgeInsets.all(10),
          sliver: SliverList(delegate: SliverChildListDelegate(friends))));
      }
      if (!invited.isEmpty) {
        slivers.add(UI.makeHeader(ctx, "Pending Invites"));
        slivers.add(SliverSafeArea(
          minimum: const EdgeInsets.all(10),
          sliver: SliverList(delegate: SliverChildListDelegate(invited))));
      }
      if (!strangers.isEmpty) {
        slivers.add(UI.makeHeader(ctx, "People"));
        slivers.add(SliverSafeArea(
          minimum: const EdgeInsets.all(10),
          sliver: SliverList(delegate: SliverChildListDelegate(strangers))));
      }
      if (!declined.isEmpty) {
        slivers.add(UI.makeHeader(ctx, "Declined"));
        slivers.add(SliverSafeArea(
          minimum: const EdgeInsets.all(10),
          sliver: SliverList(delegate: SliverChildListDelegate(declined))));
      }
      return CustomScrollView(slivers: slivers);
    }));
  }

  @override String get unauthedMessage => "Log in to find friends!";
}
