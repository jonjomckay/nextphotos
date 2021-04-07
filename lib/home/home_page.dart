import 'dart:developer';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:nextphotos/home/home_model.dart';
import 'package:nextphotos/library/favourites_screen.dart';
import 'package:nextphotos/library/library_screen.dart';
import 'package:nextphotos/settings/settings_page.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomePage extends StatefulWidget {
  static String route = '/';

  HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final PageController _pageController = PageController();
  Future<SharedPreferences> _preferences = SharedPreferences.getInstance();

  int _currentPage = 0;

  @override
  void initState() {
    super.initState();

    _preferences.then((prefs) {
      var model = context.read<HomeModel>();

      model.setSettings(
          prefs.getString('nextcloud.hostname')!,
          prefs.getString('nextcloud.username')!,
          prefs.getString('nextcloud.appPassword')!,
          prefs.getString('nextcloud.authorizationHeader')!
      );

      model.refreshPhotos(_onRefresh);
    });
  }

  void _onRefresh(String message) {
    log(message);

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Settings',
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => SettingsPage()));
            },
          )
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentPage,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          _pageController.animateToPage(index, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
        },
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.photo_library),
            label: 'Library'
          ),
          BottomNavigationBarItem(
              icon: Icon(Icons.favorite),
              label: 'Favourites'
          )
        ],
      ),
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) => setState(() {
          this._currentPage = index;
        }),
        children: [
          LibraryScreen(onRefresh: _onRefresh),
          FavouritesScreen(onRefresh: _onRefresh)
        ],
      ),
    );
  }

}
