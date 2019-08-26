# tfw.chatapp

The communication hub of the tfw social gaming experience. A messaging app where you can chat and
coordinate with your gaming friends, keep up with what's going on in the games you play by being
connected to in-game chat and via a feed of messages and reports from the games.

## Building

The tfw app is built using [Flutter], to build it you'll need to follow the
[Flutter getting started] instructions.

Once you have your development environment set up, you must first run:

```
flutter packages get
```

to install the project dependencies. This must be run again if the dependencies ever change.

Then run:

```
flutter packages pub run build_runner build
```

to generate generated code.

Now you can run the app locally by first starting an Android emulator or iOS simulator and then
invoking:

```
flutter run
```

See the Flutter dev docs for more info on building, hot reloading, etc.

The app also uses [MobX] for Dart/Flutter. It is useful to read the [MobX getting started]
instructions to familiarize yourself with its moving parts.

If one updates the annotated MobX store classes, it is necessary to update the generated code by
running:

```
flutter packages pub run build_runner build
```

One can replace `build` with `watch` to have the codegen process run automatically on file change.

## License

The tfw app code is licensed under the MIT License. See the [LICENSE](LICENSE.md) file for details.

[Flutter]: https://flutter.dev/
[Flutter getting started]: https://flutter.dev/docs/get-started/install
[MobX]: https://mobx.pub/
[MobX getting started]: https://mobx.pub/getting-started
