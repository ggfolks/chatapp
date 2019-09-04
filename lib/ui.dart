import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

import 'uuid.dart';
import 'data.dart';
import 'stores.dart';

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

abstract class AppTab extends StatelessWidget {
  AppTab ([this.app]);
  final AppStore app;
}

abstract class AuthedTab extends AppTab {
  AuthedTab (AppStore app) : super(app);

  @override Widget build (BuildContext ctx) {
    return Observer(builder: (ctx) {
      if (app.user.id == Uuid.zero) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text('Login to chat'),
              RaisedButton(
                child: const Text('SIGN IN'),
                onPressed: () => app.signIn(),
              ),
            ],
          ),
        );
      } else {
        return buildAuthed(ctx);
      }
    });
  }

  String unauthedMessage ();

  Widget buildAuthed (BuildContext ctx);
}

class UI {

  static SliverPersistentHeader makeHeader (BuildContext ctx, String headerText) {
    final theme = Theme.of(ctx);
    return SliverPersistentHeader(
      // pinned: true,
      delegate: _HeaderDelegate(Container(
        padding: const EdgeInsets.only(top: 10, left: 8, right: 8),
        decoration: BoxDecoration(border: Border(
          bottom: BorderSide(width: 1.0, color: theme.dividerColor),
        )),
        child: Text(headerText, textAlign: TextAlign.left, style: theme.textTheme.headline)
      )),
    );
  }
}
