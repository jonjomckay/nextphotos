import 'package:draggable_scrollbar/draggable_scrollbar.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:nextphotos/database/entities.dart';
import 'package:nextphotos/home/home_model.dart';
import 'package:nextphotos/nextcloud/image.dart';
import 'package:provider/provider.dart';

class PhotoList extends StatelessWidget {
  ScrollController _scrollController = ScrollController();

  final List<PhotoListItem> items;

  PhotoList({Key key, this.items}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var dateFormat = DateFormat.yMMMd();

    return Consumer<HomeModel>(
      builder: (context, model, child) {
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
            child: GridView.builder(
                controller: _scrollController,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3, crossAxisSpacing: 3, mainAxisSpacing: 3),
                itemCount: items.length,
                itemBuilder: (BuildContext context, int index) {
                  var item = items[index];

                  return FutureBuilder<Photo>(
                    future: model.getPhoto(item.id),
                    builder: (context, snapshot) {
                      switch (snapshot.connectionState) {
                        default:
                          if (!snapshot.hasData) {
                            return Container(color: Colors.white10);
                          }

                          return Pic(items, snapshot.data, index);
                      }
                    },
                  );
                }));
      },
    );
  }
}
