
import 'package:flutter/material.dart';
import 'package:nextphotos/database/entities.dart';
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
  List<PhotoListItem> _ids = [];
  HomeModel? _model;

  @override
  void initState() {
    super.initState();

    var model = context.read<HomeModel>();

    model.listPhotoIds().then((ids) => setState(() {
      _ids = ids;
      _model = model;
    }));
  }

  @override
  Widget build(BuildContext context) {
    var model = _model;
    if (model == null) {
      return Container();
    }

    return Container(child: PhotoList(model: model, items: _ids));
  }
}
