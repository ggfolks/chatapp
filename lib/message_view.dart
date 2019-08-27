import 'package:intl/intl.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

import 'data.dart';
import 'stores.dart';

final timeFormat = new DateFormat.jm();

class MessageView extends StatelessWidget {
  const MessageView ([this.profiles, this.message]);

  final ProfilesStore profiles;
  final Message message;

  @override
  Widget build (BuildContext ctx) {
    final sender = profiles.profiles[message.authorId] ?? unknownPerson;

    return Container(
      padding: const EdgeInsets.all(8),
      child: Observer(
        builder: (ctx) => Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(CupertinoIcons.conversation_bubble), // TODO: proper photo
            Flexible(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.only(right: 8),
                      child: Text(sender.name, style: Theme.of(ctx).textTheme.body2)
                    ),
                    Text(timeFormat.format(message.sentTime),
                         style: Theme.of(ctx).textTheme.body1),
                  ]
                ),
                Text(message.text, style: Theme.of(ctx).textTheme.subhead)
              ]
            ))
          ],
        )
      )
    );
  }
}
