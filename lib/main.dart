import 'package:flutter/material.dart';
import 'package:nextphotos/database/database.dart';
import 'package:nextphotos/home/home_model.dart';
import 'package:nextphotos/login/login_page.dart';
import 'package:provider/provider.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'home/home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  Connection connection = Connection();
  connection.migrate();

  HomeModel homeModel = HomeModel();

  Widget child;

  var prefs = await SharedPreferences.getInstance();
  if (prefs.containsKey('nextcloud.appPassword')) {
    child = HomePage();

    homeModel.setSettings(
        prefs.getString('nextcloud.hostname')!,
        prefs.getString('nextcloud.username')!,
        prefs.getString('nextcloud.appPassword')!,
        prefs.getString('nextcloud.authorizationHeader')!
    );
  } else {
    child = LoginPage();
  }

  runApp(ChangeNotifierProvider(
    create: (context) => homeModel,
    child: RefreshConfiguration(
      enableScrollWhenRefreshCompleted: true,
      child: MyApp(child),
    ),
  ));
}

class MyApp extends StatelessWidget {
  final Widget child;

  MyApp(this.child);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nextphotos',
      theme: ThemeData(
        brightness: Brightness.light,
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.blue,

        // TODO: These are only required due to https://github.com/flutter/flutter/issues/19089
        accentColor: Colors.blue[500],
        toggleableActiveColor: Colors.blue[500],
        textSelectionColor: Colors.blue[200],
      ),
      // themeMode: ThemeMode.system,
      themeMode: ThemeMode.system,
      home: child,
    );
  }
}
