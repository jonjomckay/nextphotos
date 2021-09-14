import 'dart:developer';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:nextphotos/library/favourites_screen.dart';
import 'package:nextphotos/library/library_screen.dart';
import 'package:nextphotos/search/people_page.dart';
import 'package:nextphotos/search/places_page.dart';
import 'package:nextphotos/settings/settings_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomePage extends StatefulWidget {
  static String route = '/';

  HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final PageController _pageController = PageController();

  int _currentPage = 0;

  @override
  void initState() {
    super.initState();

    SharedPreferences.getInstance().then((prefs) {
      context.read<HomeModel>().refreshPhotos(_onRefresh);
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
          ),
          BottomNavigationBarItem(
              icon: Icon(Icons.place),
              label: 'Places'
          ),
          BottomNavigationBarItem(
              icon: Icon(Icons.people),
              label: 'People'
          ),
        ],
      ),
      body: Container(
        margin: EdgeInsets.symmetric(horizontal: 8),
        child: PageView(
          controller: _pageController,
          onPageChanged: (index) => setState(() {
            this._currentPage = index;
          }),
          children: [
            LibraryScreen(onRefresh: _onRefresh),
            FavouritesScreen(onRefresh: _onRefresh),
            PlacesScreen(),
            PeopleScreen(),
          ],
        ),
      ),
    );
  }

}
