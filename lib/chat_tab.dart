import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

import 'data.dart';
import 'stores.dart';
import 'fake.dart';
import 'message_view.dart';
import 'channel_page.dart';

Widget statusView (BuildContext ctx, Profile profile, String text, DateTime time) {
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
          // TODO: if channel data is not yet available, show a loading indicator?
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
                  padding: const EdgeInsets.only(top: 10, left: 8, right: 8),
                  decoration: const BoxDecoration(border: Border(
                    bottom: BorderSide(width: 1.0, color: Color(0xFFFF000000)),
                  )),
                  child: Text(index == 0 ? "Channels" : "People",
                              textAlign: TextAlign.left,
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
                        builder: (ctx) => ChannelPage(profiles, channelStore(p))
                      )
                    );
                  },
                  child: statusView(ctx, p, cs.latestMessage, cs.latestMessageTime)
                );
              }
            }
          );
        }
      ),
    );
  }
}
