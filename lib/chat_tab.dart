import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'data.dart';
import 'stores.dart';
import 'dates.dart';
import 'channel_page.dart';
import 'ui.dart';

class ChatTab extends AuthedTab {
  ChatTab (AppStore app) : super(app);

  final rdfmt = RelativeDateFormatter();

  SliverList makeChannelList (BuildContext ctx, bool pred (ChannelStore cs), String emptyText) {
    final List<ChannelStore> channels =
      List.from(app.channels.values.where(pred))
          ..sort((a, b) => a.profile.name.compareTo(b.profile.name));
    final rows = List<Widget>(), theme = Theme.of(ctx);
    channels.forEach((cs) => rows.add(GestureDetector(
      onTap: () {
        Navigator.of(ctx).push(
          CupertinoPageRoute<void>(
            title: cs.profile.name,
            builder: (ctx) => ChannelPage(app, cs)
          )
        );
      },
      child: Container(
        padding: const EdgeInsets.all(8),
        child: Row(children: [
          ProfileImage(cs.profile),
          SizedBox(width: 5),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(children: [
                Expanded(child: Text(cs.profile.name, style: theme.textTheme.title)),
                Text(rdfmt.formatLatest(cs.latest.sentTime)),
              ]),
              SizedBox(height: 5),
              Text(cs.latest.text, style: theme.textTheme.subhead),
            ]))
        ])
      )
    )));
    if (rows.length == 0) rows.add(Container(margin: EdgeInsets.all(10), child: Text(emptyText)));
    return SliverList(delegate: SliverChildListDelegate(rows));
  }

  @override Widget buildAuthed (BuildContext ctx) {
    // TODO: if channel data is not yet available, show a loading indicator?
    final slivers = List<Widget>();
    slivers.add(UI.makeHeader(ctx, "Channels"));
    slivers.add(makeChannelList(ctx, (cs) => cs.profile.type != ProfileType.person,
                                "Subscribe to game channels on the News or Game tab."));
    slivers.add(UI.makeHeader(ctx, "Friends"));
    slivers.add(makeChannelList(ctx, (cs) => cs.profile.type == ProfileType.person,
                                "Find friends on the People tab."));
    return SafeArea(child: CustomScrollView(slivers: slivers));
  }

  @override String unauthedMessage () => "Log in to Chat!";
}
