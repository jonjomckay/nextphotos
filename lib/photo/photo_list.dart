import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:intl/intl.dart';
import 'package:nextphotos/database/entities.dart';
import 'package:nextphotos/home/home_model.dart';
import 'package:nextphotos/nextcloud/image.dart';
import 'package:nextphotos/ui/draggable_scrollbar.dart';
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

          List<PhotoOrDate> photos = [];

          for (int i = 0; i < items.length; i++) {
            var prevPhoto = i == 0 ? null : items[i - 1];
            var thisPhoto = items[i];

            // If this is the first photo, add the date separator first
            if (i == 0) {
              photos.add(PhotoOrDate(null, thisPhoto.modifiedAt));
            }

            // If this and the previous photo are from different days, add the date separator
            if (prevPhoto != null && prevPhoto.modifiedAt.day != thisPhoto.modifiedAt.day) {
              photos.add(PhotoOrDate(null, thisPhoto.modifiedAt));
            }

            photos.add(PhotoOrDate(thisPhoto, null));
          }

          return DraggableScrollbar.semicircle(
            controller: _scrollController,
            child: StaggeredGridView.countBuilder(
              addAutomaticKeepAlives: false,
              crossAxisCount: 4,
              crossAxisSpacing: 4,
              mainAxisSpacing: 4,
              controller: _scrollController,
              itemCount: photos.length,
              itemBuilder: (context, index) {
                var photoOrDate = photos[index];
                if (photoOrDate.photo != null) {
                  return Pic(items, photoOrDate.photo!, index);
                }

                return Container(
                  alignment: Alignment.centerLeft,
                  child: Text(dateFormat.format(photoOrDate.date!), style: TextStyle(
                      fontWeight: FontWeight.bold
                  )),
                );
              },
              staggeredTileBuilder: (index) {
                var photoOrDate = photos[index];
                if (photoOrDate.photo != null) {
                  return StaggeredTile.extent(1, 128);
                }

                return StaggeredTile.extent(4, 48);
              },
            ),
          );

        },
      );
    });
  }
}

class PhotoOrDate {
  final Photo? photo;
  final DateTime? date;

  PhotoOrDate(this.photo, this.date);
}