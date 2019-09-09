import "package:flutter/cupertino.dart";
import "package:flutter/material.dart";
import "package:flutter_mobx/flutter_mobx.dart";
import "package:mobx/mobx.dart";
import "package:flutter/services.dart";

import "stores.dart";

part "auth.g.dart";

class EmailPasswordStore = _EmailPasswordStore with _$EmailPasswordStore;
abstract class _EmailPasswordStore with Store {
  @observable String status = "";
}

class EmailPasswordForm extends StatefulWidget {
  final AppStore app;
  EmailPasswordForm (this.app);
  @override State<StatefulWidget> createState() => _EmailPasswordFormState(app);
}

class _EmailPasswordFormState extends State<EmailPasswordForm> {
  final AppStore app;
  final EmailPasswordStore _state = new EmailPasswordStore();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  _EmailPasswordFormState (this.app);

  @override Widget build (BuildContext ctx) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          TextFormField(
            controller: _emailController,
            decoration: InputDecoration(labelText: "Email"),
            validator: (String value) => value.isEmpty ? "Please enter your email" : null,
          ),
          TextFormField(
            controller: _passwordController,
            decoration: InputDecoration(labelText: "Password"),
            validator: (String value) => value.isEmpty ? "Please enter your password" : null,
            obscureText: true,
          ),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            alignment: Alignment.center,
            child: RaisedButton(
              onPressed: () async {
                if (_formKey.currentState.validate()) _signIn();
              },
              child: const Text("Sign in"),
            ),
          ),
          Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Observer(builder: (ctx) => Text(
              _state.status,
              style: TextStyle(color: Colors.red),
            )),
          )
        ],
      ),
    );
  }

  @override void dispose () {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _signIn () async {
    try {
      final result = await app.auth.signInWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      ), user = result.user;
      if (user != null) {
        final id = await app.user.userDidAuth(user.uid);
        final displayName = user.displayName ?? "Tester";
        final photoUrl = user.photoUrl ?? "https://api.adorable.io/avatars/128/${user.uid}.png";
        app.profiles.userDidAuth(id, displayName, photoUrl);
      }
    } on PlatformException catch (err) {
      _state.status = _decodeError(err.code);
    }
  }

  String _decodeError (String code) {
    switch (code) {
      case "ERROR_INVALID_EMAIL": return "That email address is invalid.";
      case "ERROR_WRONG_PASSWORD": return "That password is incorrect.";
      case "ERROR_USER_NOT_FOUND": return "No account was found for that email address.";
      case "ERROR_USER_DISABLED": return "That account is disabled.";
      case "ERROR_TOO_MANY_REQUESTS": return "Please wait before making another login attempt.";
      case "ERROR_OPERATION_NOT_ALLOWED": return "Oops, our server is misconfigured.";
      default: return "Unknown error: $code";
    }
  }
}
