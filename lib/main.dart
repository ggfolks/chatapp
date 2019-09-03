import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'stores.dart';
import 'chat_tab.dart';
import 'feed_tab.dart';
import 'games_tab.dart';

Future<void> main () async {
  final app = await AppStore.create(FirebaseOptions(
    projectID: 'tfwchat',
    googleAppID: '1:733313051370:ios:a49e7f8aa716dfa6',
    // TODO: I think we have separate API keys for iOS & Android, so maybe we need to use the one
    // for the right platform... or the web API key?
    apiKey: 'AIzaSyCCh5TKk32ZG-fyUBG_aDLUvFCjTfEvBrc',
    // gcmSenderID: '',
  ));
  runApp(ChatApp(app));
}

class ChatApp extends StatefulWidget {
  final AppStore app;
  ChatApp(this.app);
  _ChatAppState createState () => _ChatAppState(app);
}

class _ChatAppState extends State<ChatApp> with WidgetsBindingObserver {
  final AppStore app;
  _ChatAppState (this.app);

  @override void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  void didChangeAppLifecycleState (AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) app.sendAnalyticsEvent(
      "app_resumed", {"user": app.self.uuid});
  }

  // TODO: create app store here
  // display some sort of UI prior to async resolve of AppStore
  // also handle failure of AppStore init

  @override Widget build(BuildContext ctx) {
    return MaterialApp(
      title: 'tfw chat',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      // TEMP: use a scaffold so we can show snackbars
      home: Scaffold(body: ChatShell(app)),
    );
  }
}

class ChatShell extends StatelessWidget {
  final AppStore app;
  ChatShell (this.app);

  @override Widget build(BuildContext ctx) {
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
