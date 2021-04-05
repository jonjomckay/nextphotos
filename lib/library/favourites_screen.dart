import 'package:flutter/material.dart';
import 'package:nextphotos/database/entities.dart';
import 'package:nextphotos/home/home_model.dart';
import 'package:nextphotos/photo/photo_list.dart';
import 'package:provider/provider.dart';

class FavouritesScreen extends StatefulWidget {

  @override
  _FavouritesScreenState createState() => _FavouritesScreenState();
}

class _FavouritesScreenState extends State<FavouritesScreen> {
  List<PhotoListItem> _ids = [];

  @override
  void initState() {
    super.initState();

    _onRefresh();
  }

  Future _onRefresh() async {
    var model = context.read<HomeModel>();
    var ids = await model.listFavouritePhotoIds();

    setState(() {
      _ids = ids;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(child: PhotoList(items: _ids, onRefresh: _onRefresh));
  }
}
