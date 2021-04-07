import 'package:flutter/material.dart';
import 'package:nextphotos/home/home_model.dart';
import 'package:nextphotos/photo/photo_list.dart';
import 'package:provider/provider.dart';

class FavouritesScreen extends StatefulWidget {
  final Function(String) onRefresh;

  const FavouritesScreen({Key? key, required this.onRefresh}) : super(key: key);

  @override
  _FavouritesScreenState createState() => _FavouritesScreenState();
}

class _FavouritesScreenState extends State<FavouritesScreen> {

  @override
  Widget build(BuildContext context) {
    return Consumer<HomeModel>(builder: (context, model, child) {
      return Container(child: PhotoList(
        itemsFuture: model.listFavouritePhotoIds(),
        onRefresh: widget.onRefresh,
      ));
    });
  }
}
