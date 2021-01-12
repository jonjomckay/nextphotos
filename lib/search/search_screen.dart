import 'dart:collection';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:nextphotos/home/home_model.dart';
import 'package:nextphotos/search/search_location.dart';
import 'package:provider/provider.dart';

class SearchScreen extends StatelessWidget {
  Widget _buildCarouselItem(BuildContext context, SearchLocation location) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Container(
        width: 180,
        child: Column(
          children: [
            CachedNetworkImage(
                imageUrl:
                'https://api.mapbox.com/styles/v1/mapbox/outdoors-v11/static/${location.lng},${location.lat},10,0/300x300?access_token=pk.eyJ1Ijoiam9uam9tY2theSIsImEiOiJja2p1NHU5ZTcwYm9wMnFvNWJwbnhieWc4In0.lUbmCfnLIOsijQsKpe2u0Q'),
            ListTile(
              title: Text(location.name),
              subtitle: Text(
                '${location.count} ${Intl.plural(location.count, one: 'photo', other: 'photos')}',
                style: Theme.of(context).textTheme.caption,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(child: Consumer<HomeModel>(
      builder: (context, model, child) {
        var places = FutureBuilder<List<SearchLocation>>(
          future: model.listLocations(),
          builder: (context, snapshot) {
            switch (snapshot.connectionState) {
              default:
                if (snapshot.hasError) {
                  return Text('Oops: ${snapshot.error}');
                }

                if (!snapshot.hasData) {
                  return Container();
                }

                var locations = UnmodifiableListView(snapshot.data);

                return Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                          child: Text('Places', style: Theme.of(context).textTheme.headline6),
                        ),
                        SizedBox(
                          // TODO: you may want to use an aspect ratio here for tablet support
                          height: 260.0,
                          child: ListView.separated(
                            physics: PageScrollPhysics(),
                            separatorBuilder: (context, index) => Divider(),
                            scrollDirection: Axis.horizontal,
                            clipBehavior: Clip.none,
                            itemCount: locations.length,
                            itemBuilder: (BuildContext context, int itemIndex) {
                              return _buildCarouselItem(context, locations[itemIndex]);
                            },
                          ),
                        )
                      ],
                    ));
            }
          },
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            places,
            places,
            // places
          ],
        );
      },
    ));
  }
}
