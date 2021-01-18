import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:nextcloud/nextcloud.dart';
import 'package:nextphotos/home/home_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:webview_flutter/webview_flutter.dart';

class LoginPage extends StatefulWidget {
  static String route = '/login';

  @override
  State<StatefulWidget> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  NextCloudClient _client;
  LoginFlowInit _init;
  String _hostname;
  Timer _timer;

  @override
  void initState() {
    super.initState();

    if (Platform.isAndroid) {
      WebView.platform = SurfaceAndroidWebView();
    }

    SharedPreferences.getInstance().then((prefs) {
      _timer = Timer.periodic(Duration(seconds: 2), (timer) {
        if (_client == null) {
          return;
        }

        _client.login.pollLogin(_init).then((result) {

            var server = Uri.parse(result.server);
            var username = result.loginName;
            var password = result.appPassword;

            prefs.setString('nextcloud.hostname', server.host);
            prefs.setString('nextcloud.username', username);
            prefs.setString('nextcloud.appPassword', password);

            // Pre-generate the authorization header as it's static, and used a lot
            var authorizationHeader = 'Basic ${base64.encode(utf8.encode('$username:$password')).trim()}';

            prefs.setString('nextcloud.authorizationHeader', authorizationHeader);

            Navigator.pushReplacement(context, MaterialPageRoute(builder: (BuildContext ctx) => HomePage()));
        }).catchError((e) {
          // TODO
        });
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
      child = Center(
        child: Column(
          children: [
            TextField(
              keyboardType: TextInputType.url,
              decoration: InputDecoration(
                  hintText: 'example.com',
                  labelText: 'Hostname',
                  prefixText: 'https://',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.dns)),
              onChanged: (value) => setState(() {
                _hostname = value;
              }),
            ),
            RaisedButton(
              child: Text('Login'),
              onPressed: () async {
                var client = NextCloudClient.withoutLogin(_hostname);

                client.login.initLoginFlow().then((init) {
                  setState(() {
                    _client = client;
                    _init = init;
                  });
                }).catchError((e) {
                  // TODO
                });
              },
            )
          ],
        ),
      );
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
