import 'dart:typed_data';

import 'package:async_builder/async_builder.dart';
import 'package:flutter/material.dart';
import 'package:nextphotos/home/home_model.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:provider/provider.dart';

class GalleryAlbumPage extends StatefulWidget {
  final AssetPathEntity album;

  const GalleryAlbumPage({Key? key, required this.album}) : super(key: key);

  @override
  _GalleryAlbumPageState createState() => _GalleryAlbumPageState();
}

class _GalleryAlbumPageState extends State<GalleryAlbumPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.album.name),
      ),
      body: Consumer<HomeModel>(
        builder: (context, model, child) => AsyncBuilder<List<AssetEntity>>(
          // TODO: Use pagination here instead
          future: widget.album.assetList,
          waiting: (context) => Center(child: CircularProgressIndicator()),
          builder: (context, value) {
            if (value == null) {
              // TODO
              return Container();
            }

            value.sort((a, b) => b.modifiedDateTime.compareTo(a.modifiedDateTime));

            return GridView.builder(
              gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: 160),
              itemCount: value.length,
              itemBuilder: (context, index) {
                var item = value[index];

                return InkWell(
                  onTap: () async {
                    await model.uploadPhoto(item);
                  },
                  child: AsyncBuilder<Uint8List?>(
                    future: item.thumbDataWithSize(200, 200),
                    waiting: (context) => Center(child: CircularProgressIndicator()),
                    builder: (context, value) {
                      if (value == null) {
                        // TODO
                        return Container();
                      }

                      return Image.memory(value, fit: BoxFit.cover);
                    },
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
