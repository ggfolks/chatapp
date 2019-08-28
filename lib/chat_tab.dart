// import 'dart:developer' as dev;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

import 'data.dart';
import 'stores.dart';
import 'message_view.dart';
import 'channel_page.dart';

Widget statusView (BuildContext ctx, Profile profile, Message latest) {
  return Container(
    padding: const EdgeInsets.all(8),
    // TODO: fixed height
    child: Row(children: <Widget>[
      ProfileImage(profile),
      Container(
        padding: const EdgeInsets.only(left: 5),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
          // TODO: display time in upper right?
          Container(
            padding: const EdgeInsets.only(bottom: 5),
            child: Text(profile.name)
          ),
          Text(latest.text, style: Theme.of(ctx).textTheme.subhead),
        ])
      )
    ])
  );
}

class ChatTab extends StatelessWidget {
  const ChatTab ([this.app]);

  final AppStore app;

  @override
  Widget build (BuildContext ctx) {
    return DefaultTextStyle(
      style: Theme.of(ctx).textTheme.title,
      textAlign: TextAlign.left,
      child: Observer(
        builder: (ctx) {
          // TODO: if channel data is not yet available, show a loading indicator?
          List<ChannelStore> channels =
            List.from(app.channels.values.where((cs) => cs.profile.type != ProfileType.person))
                ..sort((a, b) => a.profile.name.compareTo(b.profile.name));
          List<ChannelStore> privates =
            List.from(app.channels.values.where((cs) => cs.profile.type == ProfileType.person))
                ..sort((a, b) => a.profile.name.compareTo(b.profile.name));
          final chancount = channels.length, privcount = privates.length;
          return ListView.builder(
            itemCount: chancount + privcount + 2,
            itemBuilder: (ctx, index) {
              if (index == 0 || index == chancount+1) {
                return Container(
                  padding: const EdgeInsets.only(top: 10, left: 8, right: 8),
                  decoration: BoxDecoration(border: Border(
                    bottom: BorderSide(width: 1.0, color: Theme.of(ctx).dividerColor),
                  )),
                  child: Text(index == 0 ? "Channels" : "People",
                              textAlign: TextAlign.left,
                              style: Theme.of(ctx).textTheme.headline)
                );
              } else {
                final isChan = (index <= chancount);
                final cs = isChan ? channels[index-1] : privates[index-chancount-2];
                return GestureDetector(
                  onTap: () {
                    Navigator.of(ctx).push(
                      CupertinoPageRoute<void>(
                        title: cs.profile.name,
                        builder: (ctx) => ChannelPage(app, cs)
                      )
                    );
                  },
                  child: statusView(ctx, cs.profile, cs.latest)
                );
              }
            }
          );
        }
      ),
    );
  }
}
