import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_downloader/image_downloader.dart';
import 'package:intl/intl.dart';
import 'package:nextphotos/database/entities.dart';
import 'package:nextphotos/home/home_model.dart';
import 'package:nextphotos/nextcloud/image.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:provider/provider.dart';

class PhotoPage extends StatefulWidget {
  PhotoPage({Key? key, required this.photos, required this.photo, required this.index})
      : pageController = PageController(initialPage: index);

  final List<Photo> photos;
  final Photo photo;
  final int index;
  final PageController pageController;

  @override
  State<StatefulWidget> createState() => _PhotoPageState();
}

class _PhotoPageState extends State<PhotoPage> {
  late int _index;
  late Photo _photo;

  @override
  void initState() {
    super.initState();
    _index = widget.index;
    _photo = widget.photo;
  }

  void onPageChanged(int index) {
    context.read<HomeModel>().getPhoto(widget.photos[index].id).then((photo) {
      setState(() {
        _index = index;
        _photo = photo;
      });
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
                    new DateFormat.yMMMMd().format(_photo.modifiedAt),
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
                    new DateFormat.Hm().format(_photo.modifiedAt),
                    textScaleFactor: 0.7,
                  )))
            ],
          )
        ],
      )),
      bottomNavigationBar: BottomAppBar(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(icon: Icon(Icons.share), onPressed: () => {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('Not supported yet!'),
              ))
            }),
            IconButton(icon: Icon(Icons.favorite), color: _photo.favourite ? Colors.red : null, onPressed: () async {
              await context.read<HomeModel>().setPhotoFavourite(_photo.id, _photo.path, !_photo.favourite);
              onPageChanged(_index);
            }),
            IconButton(icon: Icon(Icons.delete), onPressed: () => {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('Not supported yet!'),
              ))
            }),
          ],
        ),
      ),
      body: Center(
        child: Consumer<HomeModel>(
          builder: (context, model, child) {
            return PhotoViewGallery.builder(
              scrollPhysics: const BouncingScrollPhysics(),
              backgroundDecoration: BoxDecoration(
                color: Colors.transparent,
              ),
              pageController: widget.pageController,
              onPageChanged: onPageChanged,
              scrollDirection: Axis.horizontal,
              itemCount: widget.photos.length,
              builder: (context, index) {
                return PhotoViewGalleryPageOptions.customChild(
                    child: FutureBuilder<Photo>(
                      future: model.getPhoto(widget.photos[index].id),
                      initialData: widget.photos[index],
                      builder: (context, snapshot) {
                        var photo = snapshot.data;
                        if (photo == null) {
                          return Container();
                        }

                        return FullSizePhoto(
                          model: model,
                          photo: photo,
                        );
                      },
                    )
                );
              },
            );
          },
        )),
    );
  }
}

class FullSizePhoto extends StatefulWidget {
  final HomeModel model;
  final Photo photo;

  const FullSizePhoto({Key? key, required this.model, required this.photo}) : super(key: key);

  @override
  _FullSizePhotoState createState() => _FullSizePhotoState();
}

class _FullSizePhotoState extends State<FullSizePhoto> {
  String? _path;
  double _progress = 0;
  bool _hideProgress = false;

  @override
  void initState() {
    super.initState();

    _initialize();
  }

  Future _initialize() async {
    ImageDownloader.callback(onProgressUpdate: (imageId, progress) async {
      // Sometimes the download can stall and the user might close the widget, so cancel the download if so
      if (this.mounted == false) {
        await ImageDownloader.cancel();
      }

      setState(() {
        _progress = progress / 100;
      });

      // If the image has finished downloading, wait a bit and then tell the progress bar it can disappear
      if (progress == 100) {
        Future.delayed(Duration(milliseconds: 200), () {
          setState(() {
            _hideProgress = true;
          });
        });
      }
    });

    var downloadPath = widget.photo.downloadPath;
    if (downloadPath == null) {
      _downloadImage();
      return;
    }

    var downloadFile = File(downloadPath);
    if (downloadFile.existsSync() && downloadFile.lengthSync() > 0) {
      setState(() {
        _hideProgress = true;
        _path = downloadPath;
        _progress = 1;
      });
    } else {
      _downloadImage();
    }
  }

  Future _downloadImage() async {
    try {
      var destination = AndroidDestinationType.directoryPictures;
      destination.inExternalFilesDir();

      var id = await ImageDownloader.downloadImage(
          'https://${widget.model.hostname}/remote.php/dav${widget.photo.path}',
          headers: {
            'Authorization': widget.model.authorization,
            'OCS-APIRequest': 'true'
          },
          destination: destination
      );

      if (id != null) {
        var downloadPath = await ImageDownloader.findPath(id);

        await widget.model.setPhotoDownloadPath(widget.photo.id, downloadPath);

        setState(() {
          _path = downloadPath;
        });
      } else {
        // TODO
      }
    } catch (e, stackTrace) {
      log('Unable to download the full size image', error: e, stackTrace: stackTrace);

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Unable to download the full size image: $e'),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    var path = _path;

    Widget child;

    // If file doesn't exist, or is downloading, display the thumbnail
    if (_progress < 1.0 || path == null) {
      child = Container(
        alignment: Alignment.center,
        color: Colors.black,
        child: Thumbnail(id: widget.photo.id, model: widget.model, width: double.infinity, fit: BoxFit.contain)
      );
    } else {
      // Otherwise, display the gallery widget
      child = Image.file(File(path));
    }

    Widget progress = Container();
    if (_hideProgress == false) {
      progress = LinearProgressIndicator(value: _progress);
    }

    return Container(
      color: Colors.black,
      child: Stack(
          children: [
            Center(child: AnimatedSwitcher(
              reverseDuration: const Duration(milliseconds: 1500),
              duration: Duration.zero,
              child: child,
            )),
            Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 1000),
                  child: progress,
                )
              ],
            ),
          ]
      ),
    );
  }
}
