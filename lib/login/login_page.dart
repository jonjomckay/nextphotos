import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:nextcloud/nextcloud.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:webview_flutter/webview_flutter.dart';

class LoginPage extends StatefulWidget {
  static String route = '/login';

  final NextCloudClient client;
  final LoginFlowInit init;

  const LoginPage({Key key, this.client, this.init}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _LoginPageState(client, init);
}

class _LoginPageState extends State<LoginPage> {
  NextCloudClient _client;
  LoginFlowInit _init;
  Timer _timer;

  _LoginPageState(this._client, this._init);

  @override
  void initState() {
    super.initState();

    if (Platform.isAndroid) {
      WebView.platform = SurfaceAndroidWebView();
    }

    _timer = Timer.periodic(Duration(seconds: 2), (timer) {
      _client.login.pollLogin(_init).then((result) {
        SharedPreferences.getInstance().then((prefs) {
          var server = Uri.parse(result.server);
          var username = result.loginName;
          var password = result.appPassword;

          prefs.setString('nextcloud.hostname', server.host);
          prefs.setString('nextcloud.username', username);
          prefs.setString('nextcloud.appPassword', password);

          // Pre-generate the authorization header as it's static, and used a lot
          var authorizationHeader = 'Basic ${base64.encode(utf8.encode('$username:$password')).trim()}';

          prefs.setString("nextcloud.authorizationHeader", authorizationHeader);

          Navigator.of(context).pushNamedAndRemoveUntil('/', (Route<dynamic> route) => false);
        });
      }).catchError((e) {
        // TODO
      });
    });
  }

  @override
  void dispose() {
    super.dispose();

    if (_timer != null) {
      _timer.cancel();
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget child;
    if (_init == null) {
      child = Container();
    } else {
      child = WebView(userAgent: 'Nextphotos', initialUrl: _init.login, javascriptMode: JavascriptMode.unrestricted);
    }

    return Scaffold(
        appBar: AppBar(
          title: Text('Log in'),
        ),
        body: child);
  }
}
