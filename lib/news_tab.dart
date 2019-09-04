import "package:flutter/material.dart";

import "stores.dart";

class NewsTab extends StatelessWidget {
  const NewsTab([this.app]);
  final AppStore app;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text("TODO: All the news that's fit to print"),
        ],
      ),
    );
  }
}
