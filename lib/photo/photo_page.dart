import 'dart:developer';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:intl/intl.dart';
import 'package:nextphotos/database/photo.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';

class PhotoPage extends StatefulWidget {
  PhotoPage({Key key, this.hostname, this.username, this.authorization, this.photos, this.index})
      : pageController = PageController(initialPage: index);

  final String hostname;
  final String username;
  final String authorization;
  final List<Photo> photos;
  final int index;
  final PageController pageController;

  @override
  State<StatefulWidget> createState() => _PhotoPageState();
}

class _PhotoPageState extends State<PhotoPage> {
  Photo photo;

  @override
  void initState() {
    super.initState();
    photo = widget.photos[widget.index];
  }

  void onPageChanged(int index) {
    setState(() {
      photo = widget.photos[index];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Column(
        children: [
          Row(
            mainAxisSize: MainAxisSize.max,
            children: [
              Padding(
                  padding: EdgeInsets.all(2),
                  child: Center(
                      child: Text(
                    new DateFormat.yMMMMd().format(photo.modifiedAt),
                    textScaleFactor: 0.95,
                  )))
            ],
          ),
          Row(
            mainAxisSize: MainAxisSize.max,
            children: [
              Padding(
                  padding: EdgeInsets.all(2),
                  child: Center(
                      child: Text(
                    new DateFormat.Hm().format(photo.modifiedAt),
                    textScaleFactor: 0.7,
                  )))
            ],
          )
        ],
      )),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        type: BottomNavigationBarType.fixed,
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.share), label: 'Share'),
          BottomNavigationBarItem(icon: Icon(Icons.favorite), label: 'Favourite'),
          BottomNavigationBarItem(icon: Icon(Icons.delete), label: 'Delete')
        ],
      ),
      body: Center(
          child: PhotoViewGallery.builder(
        scrollPhysics: const BouncingScrollPhysics(),
        loadingBuilder: (context, event) {
          return SpinKitPulse(
            color: Theme.of(context).primaryColorLight,
            size: 50.0,
          );
          // return Loading(indicator: BallSpinFadeLoaderIndicator(), size: 48.0, color: Theme.of(context).primaryColorLight);
        },
        backgroundDecoration: BoxDecoration(
          color: Colors.black,
        ),
        pageController: widget.pageController,
        onPageChanged: onPageChanged,
        scrollDirection: Axis.horizontal,
        builder: (context, index) {
          var photo = widget.photos[index];
          var image = CachedNetworkImageProvider('https://${widget.hostname}/remote.php/dav${photo.path}',
              headers: {'Authorization': widget.authorization, 'OCS-APIRequest': 'true'});

          return PhotoViewGalleryPageOptions.customChild(child: CachedNetworkImage(
              imageUrl: 'https://${widget.hostname}/remote.php/dav${photo.path}',
              httpHeaders: {'Authorization': widget.authorization, 'OCS-APIRequest': 'true'},
            progressIndicatorBuilder: (context, url, progress) {
                return Stack(
                  children: [
                    SpinKitPulse(
                      color: Theme.of(context).primaryColorLight,
                      size: 50.0,
                    ),
                    LinearProgressIndicator(
                      value: progress.progress,
                    )
                  ],
                );
            },
          ));

          return PhotoViewGalleryPageOptions(
            imageProvider: image,
            minScale: PhotoViewComputedScale.contained,
          );
        },
        itemCount: widget.photos.length,
      )),
    );
  }
}
