import 'package:cached_network_image/cached_network_image.dart';
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

class Pic extends StatelessWidget {
  Pic(this.photos, this.photo, this.index);

  final List<PhotoListItem> photos;
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
                CachedNetworkImage(
                  cacheKey: generateCacheKey(photo.id, 256),
                  imageUrl: generateCacheUri(model.hostname, model.username, photo.id, 256),
                  httpHeaders: {
                    'Authorization': model.authorization,
                    'OCS-APIRequest': 'true'
                  },
                  height: 256,
                  width: 256,
                  fit: BoxFit.cover,
                  filterQuality: FilterQuality.high,
                  placeholder: (context, url) => Container(color: Colors.white10),
                ),
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