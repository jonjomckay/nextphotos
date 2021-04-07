import 'package:flutter/material.dart';
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

  final Future<List<PhotoListItem>> itemsFuture;
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
      return FutureBuilder<List<PhotoListItem>>(
        future: this.itemsFuture,
        builder: (context, snapshot) {
          var items = snapshot.data;
          if (items == null) {
            return Center(child: CircularProgressIndicator());
          }

          return DraggableScrollbar.arrows(
              controller: _scrollController,
              backgroundColor: Colors.white,
              labelConstraints: BoxConstraints.tightFor(width: 120, height: 40),
              labelTextBuilder: (double offset) {
                final int currentItem = _scrollController.hasClients
                    ? (_scrollController.offset / (_scrollController.position.maxScrollExtent + 1) * items.length).floor()
                    : 0;

                var item = items[currentItem];

                return Text(dateFormat.format(item.modifiedAt), style: TextStyle(
                    color: Colors.black87
                ));
              },
              child: SmartRefresher(
                controller: _refreshController,
                enablePullUp: false,
                enablePullDown: true,
                onRefresh: () => _onRefresh(context),
                child: GridView.builder(
                    controller: _scrollController,
                    gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 128, crossAxisSpacing: 3, mainAxisSpacing: 3),
                    itemCount: items.length,
                    itemBuilder: (BuildContext context, int index) {
                      var item = items[index];

                      return FutureBuilder<Photo>(
                        future: model.getPhoto(item.id),
                        builder: (context, snapshot) {
                          switch (snapshot.connectionState) {
                            default:
                              var data = snapshot.data;
                              if (data == null) {
                                return Container(color: Colors.white10);
                              }

                              return Pic(items, data, index);
                          }
                        },
                      );
                    }),
              )
          );
        },
      );
    });
  }
}
