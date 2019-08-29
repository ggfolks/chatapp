// import 'dart:developer' as dev;
import 'package:flutter/scheduler.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

import 'data.dart';
import 'stores.dart';
import 'dates.dart';
import 'message_view.dart';

bool shouldAggregate (Message earlier, Message later) {
  return (earlier.authorId == later.authorId &&
          later.sentTime.difference(earlier.sentTime).inMinutes < 5);
}

class ChannelPage extends StatefulWidget {
  ChannelPage ([this.app, this.channel]);
  final AppStore app;
  final ChannelStore channel;

  @override
  _ChannelPageState createState () => _ChannelPageState(app, channel);
}

class _ChannelPageState extends State<ChannelPage> {
  _ChannelPageState ([this.app, this.channel]) {
    scrollController.addListener(() {
      scrolledBack = (scrollController.offset < scrollController.position.maxScrollExtent);
    });
  }

  final AppStore app;
  final ChannelStore channel;
  final scrollController = new ScrollController();
  final textController = TextEditingController();
  bool scrolledBack = false;

  void scrollToBottom () {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      scrollController.animateTo(
        scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
      scrolledBack = false;
    });
  }

  void snapToBottom () {
    SchedulerBinding.instance.addPostFrameCallback(
      (_) => scrollController.jumpTo(scrollController.position.maxScrollExtent));
  }

  @override
  void dispose () {
    scrollController.dispose();
    textController.dispose();
    super.dispose();
  }

  // TODO: keep track of whether we're "scrolled back" or "at the bottom"; if we're at the bottom
  // then we want to auto scroll new messages into view when they arrive

  @override
  Widget build (BuildContext ctx) {
    // TODO: fetch messages on demand, infini-scroll through them...
    final List<Message> messages = List.from(channel.messages.values)
                                       ..sort((a, b) => a.sentTime.compareTo(b.sentTime));
    final rows = List();

    // intersperse date headers, aggregate messages from same author
    List<Message> row = null;
    if (messages.length > 0) {
      DateTime headerTime = null;
      for (final msg in messages) {
        if (headerTime == null || !sameDate(headerTime, msg.sentTime)) {
          headerTime = msg.sentTime;
          rows.add(headerTime);
          row = null;
        }
        if (row == null || !shouldAggregate(row.last, msg)) {
          row = List();
          rows.add(row);
        }
        row.add(msg);
      }
    }

    final formatter = new RelativeDateFormatter();

    if (!scrolledBack) snapToBottom();

    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(),
      child: Observer(
        builder: (ctx) => Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            // Flutter tries to do magic to the ListView by putting enough padding to keep it from
            // scrolling under the bototm tab bar by default, but we have another widget below the
            // scrollview so we have to manually do that padding magic ourselves *and* remove the
            // padding magic from listview otherwise it will have a bunch of unwanted padding
            Expanded(child: MediaQuery.removePadding(
              removeBottom: true, context: ctx, child: ListView.builder(
                controller: scrollController,
                itemCount: rows.length,
                itemBuilder: (ctx, index) {
                  final row = rows[index];
                  return (row is DateTime) ? Container(
                    padding: const EdgeInsets.only(top: 8, left: 8, right: 8),
                    child: Text(formatter.formatHeader(row), style: Theme.of(ctx).textTheme.title)
                  ) : MessageView(app.profiles, row);
                }
              ))),
            Container(
              padding: const EdgeInsets.only(left: 8, right: 8),
              decoration: BoxDecoration(border: Border(
                top: BorderSide(width: 1.0, color: Theme.of(ctx).dividerColor),
              )),
              child: TextField(
                controller: textController,
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Message ${channel.profile.name}...'
                ),
                textInputAction: TextInputAction.send,
                maxLines: null, // causes it to auto-expand with long text
                onSubmitted: (text) {
                  channel.sendMessage(app.self, text);
                  textController.text = "";
                  scrollToBottom();
                }
              ),
            ),
            SizedBox(height: MediaQuery.of(ctx).padding.bottom)
          ]
        )
      )
    );
  }
}
