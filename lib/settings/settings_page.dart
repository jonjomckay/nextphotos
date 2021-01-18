import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:nextphotos/login/login_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Form(
            key: _formKey,
            child: Column(children: <Widget>[
              ElevatedButton(
                onPressed: () {
                  SharedPreferences.getInstance().then((prefs) {
                    prefs.remove('nextcloud.hostname');
                    prefs.remove('nextcloud.username');
                    prefs.remove('nextcloud.appPassword');
                    prefs.remove('nextcloud.authorizationHeader');

                    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => LoginPage()));
                  });
                },
                child: Text('Submit'),
              )
            ])),
      ),
    );
  }
}
