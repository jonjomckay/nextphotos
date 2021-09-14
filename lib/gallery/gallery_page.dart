import 'package:async_builder/async_builder.dart';
import 'package:flutter/material.dart';
import 'package:nextphotos/gallery/gallery_album_page.dart';
import 'package:photo_manager/photo_manager.dart';

class GalleryPage extends StatefulWidget {
  const GalleryPage({Key? key}) : super(key: key);

  @override
  _GalleryPageState createState() => _GalleryPageState();
}

class _GalleryPageState extends State<GalleryPage> {
  @override
  void initState() {
    super.initState();

    PhotoManager.requestPermissionExtend().then((result) {
      if (!result.isAuth) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          // TODO
          content: Text('You need to grant Nextphotos permission to view your photos!'),
        ));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Container(
        child: AsyncBuilder<List<AssetPathEntity>>(
          future: PhotoManager.getAssetPathList(onlyAll: true, filterOption: FilterOptionGroup(orders: [
            OrderOption(type: OrderOptionType.updateDate, asc: true)
          ])),
          waiting: (context) => Center(child: CircularProgressIndicator()),
          builder: (context, value) {
            if (value == null) {
              // TODO
              return Container();
            }

            return ListView.builder(
              itemCount: value.length,
              itemBuilder: (context, index) {
                var item = value[index];

                return InkWell(
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => GalleryAlbumPage(album: item)));
                  },
                  child: Container(
                    color: Colors.orange,
                    height: 48,
                    child: Text(item.name),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
