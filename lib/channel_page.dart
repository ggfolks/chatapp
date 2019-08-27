import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

import 'data.dart';
import 'stores.dart';
import 'message_view.dart';

class ChannelPage extends StatelessWidget {
  const ChannelPage ([this.profiles, this.channel]);

  final ProfilesStore profiles;
  final ChannelStore channel;

  @override
  Widget build (BuildContext ctx) {
    // TODO: fetch messages on demand, infini-scroll through them...
    final List<Message> messages = List.from(channel.messages.values)
                                       ..sort((a, b) => a.sentTime.compareTo(b.sentTime));
    // TODO: intersperse date headers (Today, Yesterday, then Month, Day, Year localized)
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(),
      child: Observer(
        builder: (ctx) => ListView.builder(
          itemCount: messages.length,
          itemBuilder: (ctx, index) => MessageView(profiles, messages[index])
        )
      )
    );
  }
}
