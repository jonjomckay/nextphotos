import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
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
    var cacheManager = DefaultCacheManager();

    var cachePhoto = (String key, PhotoListItem photo) async {
      var uri = generateCacheUri(model.hostname, model.username, photo.id, 256);

      var stream = cacheManager.getImageFile(uri, key: key, headers: {
        'Authorization': model.authorization,
        'OCS-APIRequest': 'true'
      });

      await for (var result in stream) {
        if (result is DownloadProgress) {
          continue;
        }

        if (result is FileInfo) {
          print('Cached ${photo.id}');
        }
      }
    };

    List<Future<Null>> futures = [];

    // For each photo, if we don't have it cached, add a future that primes the cached for that given photo ID
    for (var photo in (await model.listPhotoIds())) {
      var key = generateCacheKey(photo.id, 256);

      var existingFile = await cacheManager.getFileFromCache(key);
      if (existingFile == null) {
        futures.add(cachePhoto(key, photo));
      }
    }

    if (futures.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('There are no missing thumbnails to precache'),
      ));
    } else {
      var start = DateTime.now().millisecondsSinceEpoch;

      await Future.wait(futures);

      var total = DateTime.now().millisecondsSinceEpoch - start;

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Precached ${futures.length} missing thumbnails in ${total}ms'),
      ));
    }
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
          )
        ],
      ),
    );
  }
}
