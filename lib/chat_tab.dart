import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

import 'data.dart';
import 'stores.dart';
import 'fake.dart';
import 'channel_page.dart';

Widget statusView (BuildContext ctx, String photo, String name, String text, DateTime time) {
  return Container(
    padding: const EdgeInsets.all(8),
    // DO: fixed height
    child: Row(children: <Widget>[
      Icon(CupertinoIcons.conversation_bubble), // DO: proper photo
      Container(
        padding: const EdgeInsets.only(left: 5),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
          // DO: display time in upper right?
          Container(
            padding: const EdgeInsets.only(bottom: 5),
            child: Text(name)
          ),
          Text(text, style: Theme.of(ctx).textTheme.subhead),
        ])
      )
    ])
  );
}

class ChatTab extends StatelessWidget {
  const ChatTab ([this.profiles, this.channels]);

  final ProfilesStore profiles;
  final ChannelsStore channels;

  @override
  Widget build (BuildContext ctx) {
    return DefaultTextStyle(
      style: Theme.of(ctx).textTheme.title,
      textAlign: TextAlign.left,
      child: Observer(
        builder: (_) {
          // DO: if channel data is not yet available, show a loading indicator?
          List<ChannelStatus> chanstats =
            List.from(channels.channels.values)..sort(profiles.compareNames);
          List<ChannelStatus> privstats =
            List.from(channels.privates.values)..sort(profiles.compareNames);
          final chancount = chanstats.length, privcount = privstats.length;
          return ListView.builder(
            itemCount: chancount + privcount + 2,
            itemBuilder: (ctx, index) {
              if (index == 0 || index == chancount+1) {
                return Container(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(index == 0 ? "Channels" : "People",
                              textAlign: TextAlign.center,
                              style: Theme.of(ctx).textTheme.headline)
                );
              } else {
                final isChan = (index <= chancount);
                final cs = isChan ? chanstats[index-1] : privstats[index-chancount-2];
                final p = profiles.profiles[cs.uuid] ?? (isChan ? unknownChannel : unknownPerson);
                return GestureDetector(
                  onTap: () {
                    Navigator.of(ctx).push(
                      CupertinoPageRoute<void>(
                        title: p.name,
                        builder: (ctx) => ChannelPage(channelStore(p))
                      )
                    );
                  },
                  child: statusView(ctx, p.photo, p.name, cs.latestMessage, cs.latestMessageTime)
                );
              }
            }
          );
        }
      ),
    );
  }
}
