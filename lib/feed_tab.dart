import 'package:flutter/material.dart';

import 'stores.dart';

class FeedTab extends StatelessWidget {
  const FeedTab([this.app]);
  final AppStore app;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('TODO: Feed'),
        ],
      ),
    );
  }
}
