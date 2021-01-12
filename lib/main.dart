import 'package:flutter/material.dart';
import 'package:nextphotos/database/database.dart';
import 'package:nextphotos/home/home_model.dart';
import 'package:provider/provider.dart';

import 'home/home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  Connection connection = Connection();
  connection.connect();

  runApp(ChangeNotifierProvider(
    create: (context) => HomeModel(),
    child: MyApp(),
  ));
}

class MyApp extends StatelessWidget {
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
      home: HomePage(),
    );
  }
}
