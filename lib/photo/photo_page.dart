import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:intl/intl.dart';
import 'package:nextphotos/database/entities.dart';
import 'package:nextphotos/home/home_model.dart';
import 'package:nextphotos/nextcloud/image.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:provider/provider.dart';

class PhotoPage extends StatefulWidget {
  PhotoPage({Key? key, required this.photos, required this.photo, required this.index})
      : pageController = PageController(initialPage: index);

  final List<PhotoListItem> photos;
  final Photo photo;
  final int index;
  final PageController pageController;

  @override
  State<StatefulWidget> createState() => _PhotoPageState();
}

class _PhotoPageState extends State<PhotoPage> {
  late Photo photo;

  @override
  void initState() {
    super.initState();
    photo = widget.photo;
  }

  void onPageChanged(int index) {
    context.read<HomeModel>().getPhoto(widget.photos[index].id).then((value) => setState(() {
          photo = value;
        }));
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
      bottomNavigationBar: BottomAppBar(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(icon: Icon(Icons.share), onPressed: () => {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('Not supported yet!'),
              ))
            }),
            IconButton(icon: Icon(Icons.favorite), color: photo.favourite ? Colors.red : null, onPressed: () async {
              await context.read<HomeModel>().setPhotoFavourite(photo.id, photo.path, !photo.favourite);
              onPageChanged(widget.index);
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
              loadingBuilder: (context, event) {
                return SpinKitPulse(
                  color: Theme.of(context).primaryColorLight,
                  size: 50.0,
                );
              },
              backgroundDecoration: BoxDecoration(
                color: Colors.black,
              ),
              pageController: widget.pageController,
              onPageChanged: onPageChanged,
              scrollDirection: Axis.horizontal,
              itemCount: widget.photos.length,
              builder: (context, index) {
                return PhotoViewGalleryPageOptions.customChild(
                  child: FutureBuilder<Photo>(
                    future: model.getPhoto(widget.photos[index].id),
                    builder: (context, snapshot) {
                      var photo = snapshot.data;
                      if (photo == null) {
                        return Container();
                      }

                      return CachedNetworkImage(
                        imageUrl: 'https://${model.hostname}/remote.php/dav${photo.path}',
                        httpHeaders: {
                          'Authorization': model.authorization,
                          'OCS-APIRequest': 'true'
                        },
                        placeholderFadeInDuration: Duration(milliseconds: 200),
                        fadeInDuration: Duration.zero,
                        fadeOutDuration: Duration(milliseconds: 1000),
                        progressIndicatorBuilder: (context, url, progress) {
                          return Stack(
                              children: [
                                Center(child: Thumbnail(id: photo.id, model: model, width: double.infinity, fit: BoxFit.contain)),
                                LinearProgressIndicator(
                                  value: progress.progress,
                                ),
                              ]
                          );
                        },
                      );
                    },
                  ));
              },
            );
          },
        )),
    );
  }
}
