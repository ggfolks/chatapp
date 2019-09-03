import 'package:intl/intl.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'data.dart';
import 'stores.dart';

final timeFormat = new DateFormat.jm();

class ProfileImage extends StatelessWidget {
  const ProfileImage ([this.profile]);
  final Profile profile;

  @override
  Widget build (BuildContext ctx) {
    return Image.network(profile.photo, width: 40);
  }
}

class MessageView extends StatelessWidget {
  const MessageView ([this.app, this.messages]);

  final AppStore app;
  final List<Message> messages;

  @override
  Widget build (BuildContext ctx) {
    final first = messages.first;
    final sender = app.profiles.profiles[first.authorId] ?? unknownPerson;
    final texts = messages.map((msg) => Container(
      padding: const EdgeInsets.only(top: 5),
      child: Text(msg.text, style: Theme.of(ctx).textTheme.subhead)
    ));

    return Container(
      padding: const EdgeInsets.all(8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.only(right: 5),
            child: ProfileImage(sender)
          ),
          Flexible(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.only(right: 8),
                    child: Text(sender.name, style: Theme.of(ctx).textTheme.body2)
                  ),
                  Text(timeFormat.format(first.sentTime), style: Theme.of(ctx).textTheme.body1),
                ]
              ),
              ...texts
            ]
          ))
        ],
      )
    );
  }
}
