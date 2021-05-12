import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:nextphotos/database/entities.dart';
import 'package:nextphotos/home/home_model.dart';
import 'package:nextphotos/photo/photo_list.dart';
import 'package:provider/provider.dart';

class PlacePage extends StatefulWidget {
  final int id;

  const PlacePage({Key? key, required this.id}) : super(key: key);

  @override
  _PlacePageState createState() => _PlacePageState();
}

class _PlacePageState extends State<PlacePage> {
  @override
  Widget build(BuildContext context) {
    return Consumer<HomeModel>(
      builder: (context, model, child) {
        return FutureBuilder<LocationGet>(
          future: model.getLocation(widget.id),
          builder: (context, snapshot) {
            var error = snapshot.error;
            if (error != null) {
              log('Unable to load the location', error: error);
            }

            var location = snapshot.data;
            if (location == null) {
              return Center(child: CircularProgressIndicator());
            }

            return Scaffold(
              appBar: AppBar(),
              body: Container(child: PhotoList(
                itemsFuture: Future.value(location.photos),
                onRefresh: (something) {

                },
              )),
            );
          },
        );
      },
    );
  }
}
