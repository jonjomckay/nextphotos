import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:intl/intl.dart';
import 'package:nextphotos/dart/extensions.dart';
import 'package:nextphotos/database/entities.dart';
import 'package:nextphotos/home/home_model.dart';
import 'package:nextphotos/nextcloud/image.dart';
import 'package:provider/provider.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

class PhotoList extends StatelessWidget {
  final RefreshController _refreshController = RefreshController(initialRefresh: false);
  final ScrollController _scrollController = ScrollController();

  final Future<List<Photo>> itemsFuture;
  final Function(String) onRefresh;

  PhotoList({Key? key, required this.itemsFuture, required this.onRefresh}) : super(key: key);

  Future _onRefresh(BuildContext context) async {
    context.read<HomeModel>().refreshPhotos((message) {
      onRefresh(message);

    });

    _refreshController.refreshCompleted();
  }

  @override
  Widget build(BuildContext context) {
    var dateFormat = DateFormat.yMMMd();

    return Consumer<HomeModel>(builder: (context, model, child) {
      return FutureBuilder<List<Photo>>(
        future: this.itemsFuture,
        builder: (context, snapshot) {
          var items = snapshot.data;
          if (items == null) {
            return Center(child: CircularProgressIndicator());
          }

          var groups = items.groupBy((e) => dateFormat.format(e.modifiedAt));
          var titles = groups.keys.toList(growable: false);

          return ListView.builder(
            itemCount: groups.length,
            itemBuilder: (context, index) {
              var title = titles[index];
              var photos = groups[title]!;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                    child: Text(title, style: TextStyle(
                      fontWeight: FontWeight.bold
                    )),
                  ),
                  GridView.builder(
                      shrinkWrap: true,
                      controller: _scrollController,
                      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 128, crossAxisSpacing: 4, mainAxisSpacing: 4),
                      itemCount: photos.length,
                      itemBuilder: (BuildContext context, int index) {
                        var photo = photos[index];

                        return Pic(items, photo, items.indexOf(photo));
                      })
                ],
              );
            },
          );
        },
      );
    });
  }
}
