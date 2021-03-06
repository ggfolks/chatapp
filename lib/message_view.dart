import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:url_launcher/url_launcher.dart';

import 'data.dart';
import 'stores.dart';
import 'ui.dart';

final timeFormat = new DateFormat.jm();

void openUrl (String url) async {
  if (await canLaunch(url)) {
    await launch(url, forceSafariVC: false);
  } else {
    // TODO: feedback in app
    print("Could not open $url");
  }
}

Widget makeClickable (String linkUrl, Widget widget) {
  if (linkUrl == null) return widget;
  return GestureDetector(onTap: () => openUrl(linkUrl), child: widget);
}

class MessageView extends StatelessWidget {
  const MessageView ([this.app, this.messages]);

  final AppStore app;
  final List<Message> messages;

  @override
  Widget build (BuildContext ctx) {
    final first = messages.first;
    List<Widget> contents = [];
    for (final msg in messages) {
      if (msg.imageUrl != null) contents.add(Container(
        padding: const EdgeInsets.only(top: 5),
        child: makeClickable(msg.linkUrl, Image.network(msg.imageUrl))
      ));
      var style = Theme.of(ctx).textTheme.subtitle1;
      if (msg.linkUrl != null) style = style.copyWith(decoration: TextDecoration.underline);
      contents.add(Container(
        padding: const EdgeInsets.only(top: 5),
        child: makeClickable(msg.linkUrl, Text(msg.text, style: style))
      ));
    }

    return Observer(name: "messageView", builder: (ctx) {
      // print("Message ${first.uuid} from ${first.authorId}");
      final sender = app.profiles.getProfile(first.authorId);
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
                      child: Text(sender.name, style: Theme.of(ctx).textTheme.bodyText1)
                    ),
                    Text(timeFormat.format(first.sentTime),
                         style: Theme.of(ctx).textTheme.bodyText2),
                  ]
                ),
                ...contents
              ]
            ))
          ],
        )
      );
    });
  }
}
