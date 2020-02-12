import "package:flutter/cupertino.dart";
import "package:flutter/material.dart";
import "package:flutter_mobx/flutter_mobx.dart";
import "package:flutter_auth_buttons/flutter_auth_buttons.dart";

import "auth.dart";
import "channel_page.dart";
import "data.dart";
import "stores.dart";
import "uuid.dart";

class _HeaderDelegate extends SliverPersistentHeaderDelegate {
  _HeaderDelegate([this.child]);
  final Widget child;
  @override double get minExtent => 40;
  @override double get maxExtent => 40;
  @override
  Widget build (BuildContext context, double shrinkOffset, bool overlapsContent) => child;
  @override
  bool shouldRebuild (_HeaderDelegate oldDelegate) => (child != oldDelegate.child);
}

class ProfileImage extends StatelessWidget {
  const ProfileImage ([this.profile]);
  final Profile profile;

  @override Widget build (BuildContext ctx) {
    return Image.network(profile.photo, width: 40);
  }
}

class ProfileRow extends StatelessWidget {
  ProfileRow ([this.profile]);

  final Profile profile;
  final icons = List<IconData>();
  final actions = List<Function>();

  void addIcon (IconData icon, Function action) {
    icons.add(icon);
    actions.add(action);
  }

  @override Widget build (BuildContext ctx) {
    final children = [
      ProfileImage(profile),
      Expanded(child: Container(
        margin: EdgeInsets.only(left: 10, right: 10),
        child: Text(profile.name)
      )),
    ];
    for (var ii = 0; ii < icons.length; ii += 1) {
      children.add(IconButton(icon: Icon(icons[ii]), onPressed: actions[ii]));
    }
    return Row(children: children);
  }
}

PageRoute<T> pageRoute<T> ({String title, WidgetBuilder builder}) {
  // return CupertinoPageRoute(title: title, builder: builder);
  return MaterialPageRoute(builder: builder);
}

abstract class AppTab extends StatelessWidget {
  AppTab ([this.app]);
  final AppStore app;
}

abstract class AuthedTab extends AppTab {
  AuthedTab (AppStore app) : super(app);

  @override Widget build (BuildContext ctx) {
    final theme = Theme.of(ctx);
    return Observer(builder: (ctx) {
      if (app.user.id == Uuid.zero) {
        return SafeArea(
          minimum: EdgeInsets.all(15),
          child: Flex(
            direction: Axis.vertical,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Spacer(),
              Text(unauthedMessage, textAlign: TextAlign.center, style: theme.textTheme.headline4),
              Spacer(),
              UI.header(theme, "Sign in:"),
              Container(
                margin: EdgeInsets.only(top: 15),
                child: Column(
                  children: [
                    GoogleSignInButton(onPressed: () => app.signInWithGoogle()),
                  ]
                )
              ),
              Spacer(),
              UI.header(theme, "Sign in with email"),
              Container(
                margin: EdgeInsets.only(left: 15, right: 15),
                child: EmailPasswordForm(app)
              ),
              Spacer(),
            ],
          )
        );
      } else {
        return buildAuthed(ctx);
      }
    });
  }

  String get unauthedMessage;

  Widget buildAuthed (BuildContext ctx);
}

class UI {

  static Widget header (ThemeData theme, String text) => Container(
    padding: const EdgeInsets.only(top: 10, left: 8, right: 8),
    decoration: BoxDecoration(border: Border(
      bottom: BorderSide(width: 1.0, color: theme.dividerColor),
    )),
    child: Text(text, textAlign: TextAlign.left, style: theme.textTheme.headline5)
  );

  static SliverPersistentHeader makeHeader (BuildContext ctx, String headerText) =>
    SliverPersistentHeader(
      // pinned: true,
      delegate: _HeaderDelegate(header(Theme.of(ctx), headerText)),
    );


  static navigateToFriend (BuildContext ctx, AppStore app, Profile friend) =>
    Navigator.of(ctx).push(pageRoute<void>(
      title: friend.name,
      builder: (ctx) => ChannelPage(app, app.user.privateChannel(friend.uuid))
    ));
}
