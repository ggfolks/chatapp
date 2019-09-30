import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

import 'channel_page.dart';
import 'data.dart';
import 'dates.dart';
import 'stores.dart';
import 'ui.dart';

class ChatContents extends StatefulWidget {
  final AppStore app;
  ChatContents (this.app);
  _ChatContentsState createState () => _ChatContentsState(app);
}

class _ChatContentsState extends State<ChatContents> {
  _ChatContentsState(this.app) {}

  final AppStore app;
  final rdfmt = RelativeDateFormatter();

  SliverList makeChannelList (BuildContext ctx, List<ChannelStore> channels, String emptyText) {
    channels.sort((a, b) => app.profiles.name(a.id).compareTo(app.profiles.name(b.id)));
    final rows = List<Widget>(), theme = Theme.of(ctx);
    channels.forEach((cs) {
      app.profiles.resolveProfile(cs.id);
      rows.add(Container(
        padding: const EdgeInsets.all(8),
        child: GestureDetector(
          onTap: () => Navigator.of(ctx).push(
            pageRoute<void>(
              title: app.profiles.profiles[cs.id].name,
              builder: (ctx) => ChannelPage(app, cs)
            )
          ),
          child: Observer(builder: (ctx) {
            final profile = app.profiles.profiles[cs.id];
            return Row(children: [
              ProfileImage(profile),
              SizedBox(width: 5),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(children: [
                    Expanded(child: Text(profile.name, style: theme.textTheme.title)),
                    Text(cs.latest == null ? "" : rdfmt.formatLatest(cs.latest.sentTime)),
                  ]),
                  SizedBox(height: 5),
                  Text(cs.latest == null ? "" : cs.latest.text, style: theme.textTheme.subhead),
                ]))
            ]);
          }))));
    });
    if (rows.length == 0) rows.add(Container(margin: EdgeInsets.all(10), child: Text(emptyText)));
    return SliverList(delegate: SliverChildListDelegate(rows));
  }

  @override Widget build (BuildContext ctx) {
    return Observer(builder: (ctx) {
      // if a channel notif is set, pop our navigator to the root then push the appropriate channel
      final nc = app.notifChannel;
      if (nc != null) {
        print("Notif channel changed ${nc}");
        app.notifChannel = null;
        Future.delayed(const Duration(milliseconds: 500), () {
          final channelId = nc.channelId;
          ChannelStore store;
          if (nc.type == ProfileType.channel) {
            store = app.user.gameChannel(channelId);
          } else if (nc.type == ProfileType.person) {
            store = app.user.privateChannel(channelId);
          }
          if (store != null) {
            final route = pageRoute<void>(
              title: app.profiles.profiles[store.id].name,
              builder: (ctx) => ChannelPage(app, store)
            );
            // TODO: we may need to pop back to the root?
            if (Navigator.canPop(context)) Navigator.of(context).pushReplacement(route);
            else Navigator.of(context).push(route);
          } else print("Unable to find channel store for ${nc}");
        });
      }

      // TODO: if channel data is not yet available, show a loading indicator?
      final slivers = List<Widget>();
      slivers.add(UI.makeHeader(ctx, "Channels"));
      final channels = app.user.channels.map((id) => app.user.gameChannel(id)).toList();
      slivers.add(makeChannelList(ctx, channels, "Subscribe to game channels on the Game tab."));
      slivers.add(UI.makeHeader(ctx, "Friends"));
      final privates = app.user.friends.keys
                          .where((id) => app.user.friends[id] == FriendStatus.accepted)
                          .map((id) => app.user.privateChannel(id))
                          .toList();
      slivers.add(makeChannelList(ctx, privates, "Find friends on the People tab."));
      return SafeArea(child: CustomScrollView(slivers: slivers));
    });
  }
}

class ChatTab extends AuthedTab {
  ChatTab (AppStore app) : super(app);
  @override Widget buildAuthed (BuildContext ctx) => new ChatContents(app);
  @override String get unauthedMessage => "Log in to chat!";
}
