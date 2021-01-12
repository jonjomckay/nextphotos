import 'dart:async';
import 'dart:developer';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:nextcloud/nextcloud.dart';

/// TODO: Cache these images: https://pub.dev/packages/cached_network_image
class NextCloudImage extends ImageProvider<NextCloudImage> {
  const NextCloudImage(this.client, this.uri, this.width, this.height,
      {this.scale = 1.0})
      : assert(uri != null),
        assert(scale != null);

  final NextCloudClient client;
  final String uri;
  final int width;
  final int height;
  final double scale;

  @override
  ImageStreamCompleter load(NextCloudImage key, DecoderCallback decode) {
    // Ownership of this controller is handed off to [_loadAsync]; it is that
    // method's responsibility to close the controller's stream when the image
    // has been loaded or an error is thrown.
    final StreamController<ImageChunkEvent> chunkEvents =
    StreamController<ImageChunkEvent>();

    return MultiFrameImageStreamCompleter(
      codec: _loadAsync(decode),
      chunkEvents: chunkEvents.stream,
      scale: key.scale,
      debugLabel: key.uri,
    );
  }

  @override
  Future<NextCloudImage> obtainKey(ImageConfiguration configuration) {
    return SynchronousFuture<NextCloudImage>(this);
  }

  Future<Codec> _loadAsync(DecoderCallback decode) async {
    try {
      return decode(await client.preview.getThumbnail(uri, width, height));
    } on RequestException {
      log('Unable to load $uri');
    }
  }
}