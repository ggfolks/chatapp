import 'package:flutter/material.dart';

import 'stores.dart';

class GamesTab extends StatelessWidget {
  const GamesTab([this.app]);
  final AppStore app;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text('TODO: Games'),
        ],
      ),
    );
  }
}
