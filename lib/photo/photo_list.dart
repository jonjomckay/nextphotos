import 'package:draggable_scrollbar/draggable_scrollbar.dart';
import 'package:flutter/cupertino.dart';
import 'package:nextphotos/database/photo.dart';
import 'package:nextphotos/home/home_model.dart';
import 'package:nextphotos/nextcloud/image.dart';
import 'package:provider/provider.dart';

class PhotoList extends StatelessWidget {
  ScrollController _scrollController = ScrollController();

  final List<String> ids;

  PhotoList({Key key, this.ids}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<HomeModel>(
      builder: (context, model, child) {
        return DraggableScrollbar.rrect(
            controller: _scrollController,
            child: GridView.builder(
                controller: _scrollController,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3, crossAxisSpacing: 3, mainAxisSpacing: 3),
                itemCount: ids.length,
                itemBuilder: (BuildContext context, int index) {
                  var id = ids[index];

                  return FutureBuilder<Photo>(
                    future: model.getPhoto(id),
                    builder: (context, snapshot) {
                      switch (snapshot.connectionState) {
                        default:
                          if (!snapshot.hasData) {
                            return Image(image: AssetImage('assets/images/placeholder.png'));
                          }

                          return Pic(ids, snapshot.data, index);
                      }
                    },
                  );
                }));
      },
    );
  }
}
