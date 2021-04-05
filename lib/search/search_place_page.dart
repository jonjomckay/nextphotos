import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:nextphotos/database/entities.dart';
import 'package:nextphotos/home/home_model.dart';
import 'package:nextphotos/photo/photo_list.dart';
import 'package:nextphotos/search/search_location.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SearchPlacePage extends StatefulWidget {
  final SearchLocation searchLocation;

  const SearchPlacePage({Key key, this.searchLocation}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _SearchPlacePageState();
}

class _SearchPlacePageState extends State<SearchPlacePage> {
  List<PhotoListItem> _ids = [];

  String _hostname;
  String _username;
  String _password;
  String _authorization;

  @override
  void initState() {
    super.initState();

    SharedPreferences.getInstance().then((prefs) {
      setState(() {
        _hostname = prefs.getString('nextcloud.hostname');
        _username = prefs.getString('nextcloud.username');
        _password = prefs.getString('nextcloud.appPassword');
        _authorization = prefs.getString('nextcloud.authorizationHeader');
      });

      context.read<HomeModel>().listLocationPhotoIds(widget.searchLocation.id).then((ids) => setState(() {
        _ids = ids;
      }));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.searchLocation.name),
      ),
      body: PhotoList(items: _ids),
    );
  }
}