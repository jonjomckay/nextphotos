import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:nextphotos/database/entities.dart';
import 'package:nextphotos/home/home_model.dart';
import 'package:nextphotos/photo/photo_page.dart';
import 'package:provider/provider.dart';

class Pic extends StatelessWidget {
  Pic(this.photos, this.photo, this.index);

  final List<PhotoListItem> photos;
  final Photo photo;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Consumer<HomeModel>(
      builder: (context, model, child) {
        var actualPath = Uri.decodeFull(photo.path.replaceFirst('/files/${model.username}', ''));

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
            child: CachedNetworkImage(
              cacheKey: photo.id,
              imageUrl: 'https://${model.hostname}/index.php/apps/files/api/v1/thumbnail/256/256$actualPath',
              httpHeaders: {
                'Authorization': model.authorization,
                'OCS-APIRequest': 'true'
              },
              height: 256,
              width: 256,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(color: Colors.white10),
            )
        );
      },
    );
  }
}