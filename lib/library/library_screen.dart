
import 'package:flutter/material.dart';
import 'package:nextphotos/home/home_model.dart';
import 'package:nextphotos/photo/photo_list.dart';
import 'package:provider/provider.dart';

/// This screen simply loads all the photos from the library, and displays them in a scrollable grid. Each photo can be
/// tapped, which opens it up, full-size, in a new route.
class LibraryScreen extends StatefulWidget {
  final Function(String) onRefresh;

  const LibraryScreen({Key? key, required this.onRefresh}) : super(key: key);

  @override
  _LibraryScreenState createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {

  @override
  Widget build(BuildContext context) {
    return Consumer<HomeModel>(builder: (context, model, child) {
      return Container(child: PhotoList(
        itemsFuture: model.listPhotoIds(),
        onRefresh: widget.onRefresh,
      ));
    });
  }
}
