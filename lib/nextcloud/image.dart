import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:nextphotos/database/entities.dart';
import 'package:nextphotos/home/home_model.dart';
import 'package:nextphotos/photo/photo_page.dart';
import 'package:provider/provider.dart';

String generateCacheKey(String id, int size) {
  return '$id-$size';
}

String generateCacheUri(String hostname, String username, String id, int size) {
  return 'https://$hostname/index.php/core/preview?fileId=$id&x=$size&y=$size&a=1&mode=cover&forceIcon=0';
}

class Thumbnail extends StatelessWidget {
  final String id;
  final HomeModel model;
  final double? width;
  final double? height;
  final BoxFit? fit;

  const Thumbnail({Key? key, required this.id, required this.model, this.width, this.height, this.fit = BoxFit.cover}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ExtendedImage.network(
      generateCacheUri(model.hostname, model.username, id, 256),
      cache: true,
      cacheKey: generateCacheKey(id, 256),
      clearMemoryCacheIfFailed: true,
      headers: {
        'Authorization': model.authorization,
        'OCS-APIRequest': 'true'
      },
      height: height,
      width: width,
      fit: fit,
      filterQuality: FilterQuality.high,
      enableLoadState: true,
      loadStateChanged: (state) {
        switch (state.extendedImageLoadState) {
          case LoadState.loading:
            return Container(color: Colors.white10);
          case LoadState.failed:
            return state.completedWidget;
          default:
            return state.completedWidget;
        }
      },
    );
  }
}

class Pic extends StatelessWidget {
  Pic(this.photos, this.photo, this.index);

  final List<Photo> photos;
  final Photo photo;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Consumer<HomeModel>(
      builder: (context, model, child) {
        return GestureDetector(
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) {
                return PhotoPage(
                    photos: photos,
                    photo: photo,
                    index: index
                );
              }));
            },
            child: Stack(
              alignment: Alignment.bottomRight,
              children: [
                Thumbnail(id: photo.id, model: model, width: 256, height: 256),
                if (photo.favourite)
                  Container(
                    margin: EdgeInsets.all(8),
                    child: Icon(Icons.favorite, size: 18, color: Colors.white),
                    decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black45,
                            blurRadius: 8.0,
                          ),
                        ]
                    ),
                  ),
              ],
            )
        );
      },
    );
  }
}