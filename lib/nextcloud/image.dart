import 'dart:async';
import 'dart:developer';
import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:nextcloud/nextcloud.dart';
import 'package:nextphotos/database/photo.dart';
import 'package:nextphotos/home/home_model.dart';
import 'package:nextphotos/photo/photo_page.dart';
import 'package:progressive_image/progressive_image.dart';
import 'package:provider/provider.dart';

class Pic extends StatelessWidget {
  Pic(this.photos, this.photo, this.index);

  final List<String> photos;
  final Photo photo;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Consumer<HomeModel>(
      builder: (context, model, child) {
        var actualPath = Uri.decodeFull(photo.path.replaceFirst('/files/${model.username}', ''));

        var image = CachedNetworkImageProvider('https://${model.hostname}/index.php/apps/files/api/v1/thumbnail/256/256$actualPath',
            headers: {'Authorization': model.authorization, 'OCS-APIRequest': 'true'},
            imageRenderMethodForWeb: ImageRenderMethodForWeb.HttpGet);

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
            child: ProgressiveImage(
              placeholder: AssetImage('assets/images/placeholder.png'),
              thumbnail: image,
              image: image,
              height: 256,
              width: 256,
              fit: BoxFit.cover,
            ));
      },
    );
  }
}

/// TODO: Cache these images: https://pub.dev/packages/cached_network_image
class NextCloudImageProvider extends ImageProvider<NextCloudImageProvider> {
  const NextCloudImageProvider(this.client, this.uri, this.width, this.height, {this.scale = 1.0})
      : assert(uri != null),
        assert(scale != null);

  final NextCloudClient client;
  final String uri;
  final int width;
  final int height;
  final double scale;

  @override
  ImageStreamCompleter load(NextCloudImageProvider key, DecoderCallback decode) {
    // Ownership of this controller is handed off to [_loadAsync]; it is that
    // method's responsibility to close the controller's stream when the image
    // has been loaded or an error is thrown.
    final StreamController<ImageChunkEvent> chunkEvents = StreamController<ImageChunkEvent>();

    return MultiFrameImageStreamCompleter(
      codec: _loadAsync(decode),
      chunkEvents: chunkEvents.stream,
      scale: key.scale,
      debugLabel: key.uri,
    );
  }

  @override
  Future<NextCloudImageProvider> obtainKey(ImageConfiguration configuration) {
    return SynchronousFuture<NextCloudImageProvider>(this);
  }

  Future<Codec> _loadAsync(DecoderCallback decode) async {
    try {
      return decode(await client.preview.getThumbnail(uri, width, height));
    } on RequestException {
      log('Unable to load $uri');
    }
  }
}
