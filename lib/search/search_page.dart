import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:nextphotos/database/entities.dart';
import 'package:nextphotos/home/home_model.dart';
import 'package:nextphotos/nextcloud/image.dart';
import 'package:nextphotos/search/location_page.dart';
import 'package:provider/provider.dart';

class SearchScreen extends StatefulWidget {
  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    return Consumer<HomeModel>(builder: (context, model, child) {
      return Container(child: FutureBuilder<List<Location>>(
        future: model.listLocations(),
        builder: (context, snapshot) {
          var error = snapshot.error;
          if (error != null) {
            log('Unable to list the locations', error: error);
          }

          var items = snapshot.data;
          if (items == null) {
            return Center(child: CircularProgressIndicator());
          }

          return GridView.builder(
              controller: _scrollController,
              gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 128, crossAxisSpacing: 3, mainAxisSpacing: 3),
              itemCount: items.length,
              itemBuilder: (BuildContext context, int index) {
                var item = items[index];

                return GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => LocationPage(id: item.id))),
                  child: Column(
                    children: [
                      Expanded(child: Thumbnail(id: item.coverPhoto, model: model, fit: BoxFit.cover, width: 128, height: 128,),),
                      Text(item.name, maxLines: 1, overflow: TextOverflow.ellipsis)
                    ],
                  ),
                );
              });
        },
      ));
    });
  }
}
