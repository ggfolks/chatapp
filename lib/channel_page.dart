// import 'dart:developer' as dev;
import 'package:flutter/scheduler.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

import 'stores.dart';
import 'dates.dart';
import 'message_view.dart';

class ChannelPage extends StatefulWidget {
  ChannelPage ([this.app, this.channel]);
  final AppStore app;
  final ChannelStore channel;

  @override
  _ChannelPageState createState () => _ChannelPageState(app, channel);
}

Widget titleView (BuildContext ctx, String title) => Container(
  padding: const EdgeInsets.only(top: 8, left: 8, right: 8),
  child: Text(title, style: Theme.of(ctx).textTheme.headline6)
);

Widget messagesList (AppStore app, ChannelStore channel, ScrollController scrollController) {
  final formatter = new RelativeDateFormatter(), rows = channel.aggregateMessages;
  return ListView.builder(
    controller: scrollController,
    reverse: true,
    itemCount: rows.length,
    itemBuilder: (ctx, index) {
      final row = rows[rows.length-index-1];
      return (row is DateTime) ? titleView(ctx, formatter.formatHeader(row))
                               : MessageView(app, row);
    }
  );
}

class _ChannelPageState extends State<ChannelPage> {
  _ChannelPageState ([this.app, this.channel]) {
    scrollController.addListener(() {
      scrolledBack = (scrollController.offset > scrollController.position.minScrollExtent);
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
        scrollController.position.minScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
      scrolledBack = false;
    });
  }

  @override void dispose () {
    scrollController.dispose();
    textController.dispose();
    super.dispose();
  }

  @override Widget build (BuildContext ctx) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.deepOrange,
        title: Observer(name: "channelName", builder: (ctx) => Text(app.profiles.name(channel.id))),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Flutter is adding padding below and above our list which we need to remove for...
          // reasons (the text input field below, and the appBar above, I guess...).
          Expanded(child: MediaQuery.removePadding(
            removeTop: true,
            removeBottom: true,
            context: ctx, child: messagesList(app, channel, scrollController)
          )),
          Container(
            padding: const EdgeInsets.only(left: 8, right: 8),
            decoration: BoxDecoration(border: Border(
              top: BorderSide(width: 1.0, color: Theme.of(ctx).dividerColor),
            )),
            child: TextField(
              controller: textController,
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: 'Message ${app.profiles.name(channel.id)}...'
              ),
              textInputAction: TextInputAction.send,
              textCapitalization: TextCapitalization.sentences,
              maxLines: null, // causes it to auto-expand with long text
              onSubmitted: (text) {
                channel.sendMessage(app.profiles.self, text);
                textController.text = "";
                scrollToBottom();
              }
            ),
          ),
          SizedBox(height: MediaQuery.of(ctx).padding.bottom)
        ]
      )
    );
  }
}
