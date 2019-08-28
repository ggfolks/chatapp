import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
// import 'package:flutter_mobx/flutter_mobx.dart';

import 'fake.dart';
import 'chat_tab.dart';
import 'feed_tab.dart';
import 'games_tab.dart';

var app = fakeAppStore();

void main () => runApp(ChatApp());

class ChatApp extends StatelessWidget {

  @override
  Widget build(BuildContext ctx) {
    return MaterialApp(
      title: 'tfw chat',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      // TEMP: use a scaffold so we can show snackbars
      home: Scaffold(
        body: const ChatShell()
      ),
    );
  }
}

class ChatShell extends StatelessWidget {
  const ChatShell();

  @override
  Widget build(BuildContext ctx) {
    return CupertinoTabScaffold(
      tabBar: CupertinoTabBar(
        items: [
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.conversation_bubble),
            title: Text('Chat'),
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.home),
            title: Text('Feed'),
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.profile_circled),
            title: Text('Games'),
          ),
        ],
      ),
      tabBuilder: (ctx, int index) {
        assert(index >= 0 && index <= 2);
        switch (index) {
          case 0:
            return CupertinoTabView(
              builder: (ctx) => ChatTab(app),
              defaultTitle: 'Chat',
            );
            break;
          case 1:
            return CupertinoTabView(
              builder: (ctx) => FeedTab(app),
              defaultTitle: 'Feed',
            );
            break;
          case 2:
            return CupertinoTabView(
              builder: (ctx) => GamesTab(app),
              defaultTitle: 'Games',
            );
            break;
        }
        return null;
      },
    );
  }
}
