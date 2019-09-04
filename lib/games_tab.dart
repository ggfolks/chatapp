import 'package:flutter/material.dart';

import 'ui.dart';
import 'stores.dart';

class GamesTab extends AppTab {
  GamesTab (AppStore app) : super(app);

  @override Widget build (BuildContext context) {
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
