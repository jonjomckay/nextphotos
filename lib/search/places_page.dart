import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:input_country/input_country.dart';
import 'package:intl/intl.dart';
import 'package:nextphotos/dart/extensions.dart';
import 'package:nextphotos/database/entities.dart';
import 'package:nextphotos/home/home_model.dart';
import 'package:nextphotos/nextcloud/image.dart';
import 'package:nextphotos/search/place_page.dart';
import 'package:provider/provider.dart';

class PlacesScreen extends StatefulWidget {
  @override
  _PlacesScreenState createState() => _PlacesScreenState();
}

class _PlacesScreenState extends State<PlacesScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    return Consumer<HomeModel>(builder: (context, model, child) {
      return Container(
        child: Column(
          children: [
            // Column(
            //   children: [
            //     InputChip(label: Text('Country'), onSelected: (value) => null,),
            //     ChoiceChip(label: Text('Country'), onSelected: (value) => null, selected: true,),
            //     FilterChip(label: Text('Country'), onSelected: (value) => null, selected: true,),
            //     ActionChip(label: Text('Country'), avatar: Icon(Icons.location_pin, size: 16), onPressed: () => null,),
            //   ],
            // ),
            Expanded(child: FutureBuilder<List<Location>>(
              future: model.listLocations(),
              builder: (context, snapshot) {
                var error = snapshot.error;
                if (error != null) {
                  log('Unable to list the locations', error: error, stackTrace: snapshot.stackTrace);
                }

                var items = snapshot.data;
                if (items == null) {
                  return Center(child: CircularProgressIndicator());
                }

                var groups = items.groupBy((e) => e.state);
                var countries = groups.keys.map((e) => Country.findByCode2(e)).toList(growable: false);

                countries.sort((a, b) => a!.name.compareTo(b!.name));

                return ListView.builder(
                  itemCount: countries.length,
                  itemBuilder: (context, index) {
                    var country = countries[index]!;
                    var places = groups[country.alpha2]!;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          margin: EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                          child: Text(country.name, style: TextStyle(
                              fontWeight: FontWeight.bold
                          )),
                        ),
                        GridView.builder(
                          shrinkWrap: true,
                            controller: _scrollController,
                            gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                                maxCrossAxisExtent: 200, crossAxisSpacing: 4, mainAxisSpacing: 4),
                            itemCount: places.length,
                            itemBuilder: (BuildContext context, int index) {
                              var item = places[index];
                              var plural = Intl.plural(item.numberOfPhotos, one: 'photo', other: 'photos');

                              return GestureDetector(
                                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => PlacePage(id: item.id))),
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Thumbnail(id: item.coverPhoto, model: model, fit: BoxFit.cover, width: 200, height: 200,),
                                    Container(color: Colors.black54),
                                    Container(
                                      margin: EdgeInsets.all(8),
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(item.name, textAlign: TextAlign.center, maxLines: 5, style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w500,
                                            shadows: [
                                              Shadow(
                                                blurRadius: 20.0,
                                                color: Colors.black,
                                                offset: Offset(5, 0),
                                              ),
                                            ],
                                          )),
                                          SizedBox(height: 4),
                                          Text('${item.numberOfPhotos} $plural', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(
                                            fontSize: 12,
                                            shadows: [
                                              Shadow(
                                                blurRadius: 20.0,
                                                color: Colors.black,
                                                offset: Offset(5, 0),
                                              ),
                                            ],
                                          ))
                                        ],
                                      ),
                                    )
                                  ],
                                ),
                              );
                            })
                      ],
                    );
                  },
                );
              },
            ))
          ],
        ),
      );
    });
  }
}
