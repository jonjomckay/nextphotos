
import 'package:flutter/material.dart';
import 'package:nextphotos/home/home_model.dart';
import 'package:nextphotos/photo/photo_list.dart';
import 'package:provider/provider.dart';

/// This screen simply loads all the photos from the library, and displays them in a scrollable grid. Each photo can be
/// tapped, which opens it up, full-size, in a new route.
class LibraryScreen extends StatefulWidget {

  @override
  _LibraryScreenState createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  List<String> _ids = [];

  @override
  void initState() {
    super.initState();

    var model = context.read<HomeModel>();

    model.listPhotoIds().then((ids) => setState(() => _ids = ids));
    model.refreshPhotos();
  }

  @override
  Widget build(BuildContext context) {
    return Container(child: PhotoList(ids: _ids));
  }
}