// import 'dart:developer' as dev;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

import 'data.dart';
import 'stores.dart';
import 'dates.dart';
import 'message_view.dart';
import 'channel_page.dart';

class _ChannelHeaderDelegate extends SliverPersistentHeaderDelegate {
  _ChannelHeaderDelegate([this.child]);
  final Widget child;
  @override double get minExtent => 40;
  @override double get maxExtent => 40;
  @override
  Widget build (BuildContext context, double shrinkOffset, bool overlapsContent) => child;
  @override
  bool shouldRebuild (_ChannelHeaderDelegate oldDelegate) => (child != oldDelegate.child);
}

class ChatTab extends StatelessWidget {
  ChatTab ([this.app]);

  final AppStore app;
  final rdfmt = RelativeDateFormatter();

  SliverPersistentHeader makeHeader (BuildContext ctx, String headerText) {
    final theme = Theme.of(ctx);
    return SliverPersistentHeader(
      // pinned: true,
      delegate: _ChannelHeaderDelegate(Container(
        padding: const EdgeInsets.only(top: 10, left: 8, right: 8),
        decoration: BoxDecoration(border: Border(
          bottom: BorderSide(width: 1.0, color: theme.dividerColor),
        )),
        child: Text(headerText, textAlign: TextAlign.left, style: theme.textTheme.headline)
      )),
    );
  }

  SliverList makeChannelList (BuildContext ctx, bool pred (ChannelStore cs)) {
    final theme = Theme.of(ctx);
    final List<ChannelStore> channels =
      List.from(app.channels.values.where(pred))
          ..sort((a, b) => a.profile.name.compareTo(b.profile.name));
    final List<Widget> rows = List.from(channels.map((cs) => GestureDetector(
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
    return SliverList(delegate: SliverChildListDelegate(rows));
  }

  @override
  Widget build (BuildContext ctx) {
    return Observer(builder: (ctx) {
      // TODO: if channel data is not yet available, show a loading indicator?
      final slivers = List<Widget>();
      slivers.add(makeHeader(ctx, "Channels"));
      slivers.add(makeChannelList(ctx, (cs) => cs.profile.type != ProfileType.person));
      slivers.add(makeHeader(ctx, "People"));
      slivers.add(makeChannelList(ctx, (cs) => cs.profile.type == ProfileType.person));
      return SafeArea(child: CustomScrollView(slivers: slivers));
    });
  }
}
