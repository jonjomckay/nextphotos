import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
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
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: ExtendedImage.network(
        'https://${widget.model.hostname}/remote.php/dav${widget.photo.path}',
        headers: {
          'Authorization': widget.model.authorization,
          'OCS-APIRequest': 'true'
        },
        cache: true,
        cacheKey: widget.photo.id,
        mode: ExtendedImageMode.gesture,
        enableLoadState: true,
        loadStateChanged: (state) {
          switch (state.extendedImageLoadState) {
            case LoadState.loading:
              return Stack(
                  children: [
                    Center(child: AnimatedSwitcher(
                      reverseDuration: const Duration(milliseconds: 1500),
                      duration: Duration.zero,
                      child: Thumbnail(id: widget.photo.id, model: widget.model, width: double.infinity, fit: BoxFit.contain),
                    )),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 100),
                          child: LinearProgressIndicator(),
                        )
                      ],
                    ),
                  ]
              );
            case LoadState.completed:
            case LoadState.failed:
              // TODO: Failed
              return state.completedWidget;
          }
        },
      ),
    );
  }
}
