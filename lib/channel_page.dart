import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
// import 'package:flutter_mobx/flutter_mobx.dart';

// import 'data.dart';
import 'stores.dart';

class ChannelPage extends StatelessWidget {
  const ChannelPage ([this.channel]);

  final ChannelStore channel;

  @override
  Widget build (BuildContext ctx) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(),
      child: SafeArea(
        top: false,
        bottom: false,
        child: Text("TODO!")
      )
    );
  }
}
