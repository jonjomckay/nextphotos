import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:nextphotos/login/login_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  void onTapLogout() {
    SharedPreferences.getInstance().then((prefs) {
      prefs.remove('nextcloud.hostname');
      prefs.remove('nextcloud.username');
      prefs.remove('nextcloud.appPassword');
      prefs.remove('nextcloud.authorizationHeader');

      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => LoginPage()), (r) => false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'),
      ),
      body: ListView(
        children: [
          ListTile(
            title: Text('Logout'),
            subtitle: Text('Log out of your Nextcloud server'),
            leading: const Icon(Icons.logout, color: Colors.red),
            onTap: onTapLogout,
          )
        ],
      ),
    );
  }
}
