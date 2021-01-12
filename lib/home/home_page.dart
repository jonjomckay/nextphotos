import 'dart:collection';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:draggable_scrollbar/draggable_scrollbar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:nextcloud/nextcloud.dart';
import 'package:nextphotos/database/photo.dart';
import 'package:nextphotos/home/home_model.dart';
import 'package:nextphotos/login/login_page.dart';
import 'package:nextphotos/nextcloud/image.dart';
import 'package:nextphotos/photo/photo_list.dart';
import 'package:nextphotos/search/search_location.dart';
import 'package:nextphotos/search/search_screen.dart';
import 'package:nextphotos/settings/settings_page.dart';
import 'package:provider/provider.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomePage extends StatefulWidget {
  static String route = '/';

  HomePage({Key key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Future<SharedPreferences> _preferences = SharedPreferences.getInstance();

  String _hostname;
  String _username;
  String _password;
  String _authorization;
  int _currentPage;
  List<String> _ids = [];

  RefreshController _refreshController = RefreshController(initialRefresh: true);

  // void _onRefresh() async {
  //   await fetchPhotos();
  // }

  @override
  void initState() {
    super.initState();

    _currentPage = 0;

    _preferences.then((prefs) {
      setState(() {
        _hostname = prefs.getString('nextcloud.hostname');
        _username = prefs.getString('nextcloud.username');
        _password = prefs.getString('nextcloud.appPassword');
        _authorization = prefs.getString('nextcloud.authorizationHeader');
      });

      context.read<HomeModel>().listPhotoIds().then((ids) => setState(() {
            _ids = ids;
          }));
      context.read<HomeModel>().refreshPhotos(_hostname, _username, _password);
    });
  }

  @override
  Widget build(BuildContext context) {
    // var child = SmartRefresher(
    //     enablePullDown: true,
    //     enablePullUp: true,
    //     header: ClassicHeader(),
    //     footer: ClassicFooter(
    //       idleText: 'Pull up to load more',
    //       loadingText: 'Loading...',
    //       failedText: 'Loading failed. Pull up to try again',
    //       canLoadingText: '',
    //       noDataText: 'No data',
    //     ),
    //     controller: _refreshController,
    //     onRefresh: _onRefresh,
    //     onLoading: _onRefresh,
    // );

    var libraryPage = Center(
      child: PhotoList(ids: _ids, hostname: _hostname, username: _username, authorization: _authorization)
    );

    var searchPage = SearchScreen();

    Widget child;
    if (_password == null) {
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
                  Navigator.push(
                      context, MaterialPageRoute(builder: (context) => LoginPage(client: client, init: init)));
                }).catchError((e) {
                  // TODO
                });
              },
            )
          ],
        ),
      );
    } else {
      if (_currentPage == 0) {
        child = libraryPage;
      } else {
        child = searchPage;
      }
    }

    return Scaffold(
        appBar: AppBar(
          title: Text('Nextphotos'),
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
          onTap: (value) {
            setState(() {
              _currentPage = value;
            });
          },
          items: [
            BottomNavigationBarItem(icon: Icon(Icons.photo_library), label: 'Library'),
            BottomNavigationBarItem(icon: Icon(Icons.mood), label: 'For You'),
            BottomNavigationBarItem(icon: Icon(Icons.photo_album), label: 'Albums'),
            BottomNavigationBarItem(
              icon: Icon(Icons.search),
              label: 'Search',
            )
          ],
        ),
        body: child);
  }


}
