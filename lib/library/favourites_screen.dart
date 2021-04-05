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
  HomeModel? _model;

  @override
  void initState() {
    super.initState();

    var model = context.read<HomeModel>();

    model.listFavouritePhotoIds().then((ids) => setState(() {
      _ids = ids;
      _model = model;
    }));
  }

  @override
  Widget build(BuildContext context) {
    var model = _model;
    if (model == null) {
      return Container();
    }

    return Container(child: PhotoList(model: model, items: _ids));
  }
}
