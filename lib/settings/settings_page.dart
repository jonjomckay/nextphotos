import 'dart:async';

import 'package:extended_image/extended_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:nextphotos/database/entities.dart';
import 'package:nextphotos/home/home_model.dart';
import 'package:nextphotos/login/login_page.dart';
import 'package:nextphotos/nextcloud/image.dart';
import 'package:provider/provider.dart';
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

  Future onTapPrecacheThumbnails() async {
    var model = context.read<HomeModel>();

    var headers = {
      'Authorization': model.authorization,
      'OCS-APIRequest': 'true'
    };

    var cached = 0;

    var cachePhoto = (Photo photo) async {
      var uri = generateCacheUri(model.hostname, model.username, photo.id, 256);
      var key = generateCacheKey(photo.id, 256);

      var existingFile = await cachedImageExists(uri, cacheKey: key);
      if (existingFile == false) {
        await ExtendedNetworkImageProvider(uri, cache: true, cacheKey: key, headers: headers)
            .getNetworkImageData();

        cached++;

        print('Cached $key');
      }
    };

    List<Future<Null>> futures = [];

    // For each photo, if we don't have it cached, add a future that primes the cached for that given photo ID
    for (var photo in (await model.listPhotoIds())) {
        futures.add(cachePhoto(photo));
    }

    var start = DateTime.now().millisecondsSinceEpoch;

    await Future.wait(futures);

    var total = DateTime.now().millisecondsSinceEpoch - start;

    if (cached == 0) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('There were no missing thumbnails to precache'),
      ));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Precached $cached missing thumbnails in ${total}ms'),
      ));
    }
  }

  Future onTapMapStuff() async {
    var model = context.read<HomeModel>();

    await model.doMapStuff();
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
          ),
          ListTile(
            title: Text('Precache thumbnails'),
            subtitle: Text('Download thumbnails for your entire library'),
            leading: const Icon(Icons.cloud_download),
            onTap: onTapPrecacheThumbnails,
          ),
          ListTile(
            title: Text('Map stuff'),
            subtitle: Text('Do map stuff'),
            leading: const Icon(Icons.map),
            onTap: onTapMapStuff,
          )
        ],
      ),
    );
  }
}
