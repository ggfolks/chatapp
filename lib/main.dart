import "package:firebase_core/firebase_core.dart";
import "package:flutter/cupertino.dart";
import "package:flutter/material.dart";
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:mobx/mobx.dart';

import "stores.dart";
import "chat_tab.dart";
import "news_tab.dart";
import "games_tab.dart";
import "people_tab.dart";
import "debug_tab.dart";

Future<void> main () async {
  WidgetsFlutterBinding.ensureInitialized();
  final app = await AppStore.create(FirebaseOptions(
    projectID: "tfwchat",
    googleAppID: "1:733313051370:ios:a49e7f8aa716dfa6",
    // TODO: I think we have separate API keys for iOS & Android, so maybe we need to use the one
    // for the right platform... or the web API key?
    apiKey: "AIzaSyCCh5TKk32ZG-fyUBG_aDLUvFCjTfEvBrc",
    // gcmSenderID: "",
  ));
  runApp(ChatApp(app));
}

class Tab {
  final String title;
  final IconData icon;
  final Widget Function(AppStore app) maker;
  const Tab (this.title, this.icon, this.maker);

  BottomNavigationBarItem navItem () => BottomNavigationBarItem(
    icon: Icon(icon), title: Text(title), backgroundColor: Colors.deepOrange);
  Widget tabView (AppStore app) => maker(app);
  // Widget iosTabView (AppStore app) =>
  //   CupertinoTabView(builder: (ctx) => maker(app), defaultTitle: title);
}

final tabs = [
  // Tab("Chat", CupertinoIcons.conversation_bubble, (app) => ChatTab(app)),
  // Tab("News", CupertinoIcons.news, (app) => NewsTab(app)),
  // Tab("Games", CupertinoIcons.game_controller, (app) => GamesTab(app)),
  // Tab("People", CupertinoIcons.profile_circled, (app) => PeopleTab(app)),
  // Tab("Debug", CupertinoIcons.info, (app) => DebugTab(app)),
  Tab("Chat", Icons.chat_bubble, (app) => ChatTab(app)),
  Tab("News", Icons.info, (app) => NewsTab(app)),
  Tab("Games", Icons.videogame_asset, (app) => GamesTab(app)),
  Tab("People", Icons.person, (app) => PeopleTab(app)),
  Tab("Debug", Icons.info, (app) => DebugTab(app)),
];

class ChatApp extends StatefulWidget {
  final AppStore app;
  ChatApp (this.app);
  _ChatAppState createState () => _ChatAppState(app);
}

class _ChatAppState extends State<ChatApp> with WidgetsBindingObserver {
  _ChatAppState (this.app) {
    // TEMP: hack, resolve all people when we switch to the people tab
    autorun((_) {
      if (app.selTabIdx == 3) app.profiles.resolveAllPeople();
      else if (app.selTabIdx == 4) app.profiles.resolveAllChannels();
    });
    // if a channel notification is set, switch to the chats tab;
    // the chats tab UI will then navigate itself to the right place to display the message
    autorun((_) {
      if (app.notifChannel != null) app.selTabIdx = 0;
    });
  }

  final AppStore app;
  // final tabController = new CupertinoTabController();
  final tabViews = new Map<int, Widget>();
  // TODO: set default tab index to 1, or 2 if we're not logged in

  _tabView (int index) => tabViews.putIfAbsent(index, () => tabs[index].tabView(app));

  @override void initState () {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override void dispose () {
    super.dispose();
    // tabController.dispose();
  }

  @override void didChangeAppLifecycleState (AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) app.sendAnalyticsEvent(
      "app_resumed", {"user": "${app.user.id}"});
  }

  // TODO: create app store here
  // display some sort of UI prior to async resolve of AppStore
  // also handle failure of AppStore init

  @override Widget build (BuildContext ctx) {
    return MaterialApp(
      title: "tfw chat",
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      // TEMP: use a scaffold so we can show snackbars
      // home: Scaffold(body: CupertinoTabScaffold(
      //   controller: tabController,
      //   tabBar: CupertinoTabBar(items: tabs.map((tab) => tab.navItem()).toList()),
      //   tabBuilder: (ctx, int index) => tabs[index].tabView(app),
      // )),
      home: Observer(name: "Scaffold", builder: (ctx) => Scaffold(
        body: _tabView(app.selTabIdx),
        bottomNavigationBar: BottomNavigationBar(
          items: tabs.map((tab) => tab.navItem()).toList(),
          currentIndex: app.selTabIdx,
          onTap: (int index) {
            app.selTabIdx = index;
          }
        )
      ))
    );
  }
}
