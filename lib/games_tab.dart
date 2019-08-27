import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

// import 'data.dart';
import 'stores.dart';

import 'counter.dart';

final counter = Counter();

class GamesTab extends StatelessWidget {
  const GamesTab([this.profiles, this.channels]);

  final ProfilesStore profiles;
  final ChannelsStore channels;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              'You have frobbed the games knob this many times:',
            ),
            Observer(
              builder: (_) => Text(
                '${counter.value}',
                style: Theme.of(context).textTheme.display1,
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: counter.increment,
        tooltip: 'Increment',
        child: Icon(Icons.add),
      ),
    );
  }
}
