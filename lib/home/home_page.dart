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
import 'package:nextphotos/photo/photo_page.dart';
import 'package:nextphotos/search/search_location.dart';
import 'package:nextphotos/settings/settings_page.dart';
import 'package:progressive_image/progressive_image.dart';
import 'package:provider/provider.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Pic extends StatelessWidget {
  Pic(this.hostname, this.username, this.authorization, this.photos, this.photo, this.index);

  final String hostname;
  final String username;
  final String authorization;
  final List<String> photos;
  final Photo photo;
  final int index;

  @override
  Widget build(BuildContext context) {
    var actualPath = Uri.decodeFull(photo.path.replaceFirst('/files/$username', ''));

    var image = CachedNetworkImageProvider('https://$hostname/index.php/apps/files/api/v1/thumbnail/256/256$actualPath',
        headers: {'Authorization': authorization, 'OCS-APIRequest': 'true'},
        imageRenderMethodForWeb: ImageRenderMethodForWeb.HttpGet);

    return GestureDetector(
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) {
            return PhotoPage(
                photos: photos,
                photo: photo,
                index: index,
                hostname: hostname,
                username: username,
                authorization: authorization);
          }));
        },
        child: ProgressiveImage(
          placeholder: AssetImage('assets/images/placeholder.png'),
          thumbnail: image,
          image: image,
          height: 256,
          width: 256,
          fit: BoxFit.cover,
        ));
  }
}

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

  ScrollController _scrollController = ScrollController();
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

    var libraryPage = Center(child: Consumer<HomeModel>(
      builder: (context, model, child) {
        return DraggableScrollbar.rrect(
            controller: _scrollController,
            child: GridView.builder(
                controller: _scrollController,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3, crossAxisSpacing: 3, mainAxisSpacing: 3),
                itemCount: _ids.length,
                itemBuilder: (BuildContext context, int index) {
                  var id = _ids[index];

                  return FutureBuilder<Photo>(
                    future: model.getPhoto(id),
                    builder: (context, snapshot) {
                      switch (snapshot.connectionState) {
                        default:
                          if (!snapshot.hasData) {
                            return Image(image: AssetImage('assets/images/placeholder.png'));
                          }

                          return Pic(_hostname, _username, _authorization, _ids, snapshot.data, index);
                      }
                    },
                  );
                }));
      },
    ));

    var searchPage = Container(child: Consumer<HomeModel>(
      builder: (context, model, child) {
        var places = FutureBuilder<List<SearchLocation>>(
          future: model.listLocations(),
          builder: (context, snapshot) {
            switch (snapshot.connectionState) {
              default:
                if (snapshot.hasError) {
                  return Text('Oops: ${snapshot.error}');
                }

                if (!snapshot.hasData) {
                  return Text('No data yet');
                }

                var locations = UnmodifiableListView(snapshot.data);

                return Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                          child: Text('Places', style: Theme.of(context).textTheme.headline6),
                        ),
                        SizedBox(
                          // TODO: you may want to use an aspect ratio here for tablet support
                          height: 260.0,
                          child: ListView.separated(
                            physics: PageScrollPhysics(),
                            separatorBuilder: (context, index) => Divider(),
                            scrollDirection: Axis.horizontal,
                            clipBehavior: Clip.none,
                            itemCount: locations.length,
                            itemBuilder: (BuildContext context, int itemIndex) {
                              return _buildCarouselItem(context, locations[itemIndex]);
                            },
                          ),
                        )
                      ],
                    ));
            }
          },
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            places,
            places,
            // places
          ],
        );
      },
    ));

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

  Widget _buildCarouselItem(BuildContext context, SearchLocation location) {
    // return Container(
    //   width: 260,
    //   child: Card(
    //       clipBehavior: Clip.antiAlias,
    //       child: Stack(
    //         children: [
    //           ColorFiltered(
    //             colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.7), BlendMode.dstATop),
    //             child: CachedNetworkImage(imageUrl: 'https://api.mapbox.com/styles/v1/mapbox/outdoors-v11/static/${location.lng},${location.lat},10,0/300x300?access_token=pk.eyJ1Ijoiam9uam9tY2theSIsImEiOiJja2p1NHU5ZTcwYm9wMnFvNWJwbnhieWc4In0.lUbmCfnLIOsijQsKpe2u0Q'),
    //           ),
    //           Container(
    //             child: Center(
    //               child: Text(location.name, textAlign: TextAlign.center),
    //             ),
    //             width: double.infinity,
    //           )
    //         ],
    //       )
    //   ),
    // );

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Container(
        width: 180,
        child: Column(
          children: [
            CachedNetworkImage(
                imageUrl:
                    'https://api.mapbox.com/styles/v1/mapbox/outdoors-v11/static/${location.lng},${location.lat},10,0/300x300?access_token=pk.eyJ1Ijoiam9uam9tY2theSIsImEiOiJja2p1NHU5ZTcwYm9wMnFvNWJwbnhieWc4In0.lUbmCfnLIOsijQsKpe2u0Q'),
            ListTile(
              title: Text(location.name),
              subtitle: Text(
                '${location.count} ${Intl.plural(location.count, one: 'photo', other: 'photos')}',
                style: Theme.of(context).textTheme.caption,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
