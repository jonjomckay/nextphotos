import 'dart:developer';

import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:input_country/input_country.dart';
import 'package:intl/intl.dart';
import 'package:nextphotos/dart/extensions.dart';
import 'package:nextphotos/database/entities.dart';
import 'package:nextphotos/home/home_model.dart';
import 'package:nextphotos/nextcloud/image.dart';
import 'package:nextphotos/search/person_page.dart';
import 'package:nextphotos/search/place_page.dart';
import 'package:provider/provider.dart';

class PeopleScreen extends StatefulWidget {
  @override
  _PeopleScreenState createState() => _PeopleScreenState();
}

class _PeopleScreenState extends State<PeopleScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    return Consumer<HomeModel>(builder: (context, model, child) {
      return Container(
        child: Column(
          children: [
            Expanded(child: FutureBuilder<List<Person>>(
              future: model.listPeople(),
              builder: (context, snapshot) {
                var error = snapshot.error;
                if (error != null) {
                  log('Unable to list people', error: error, stackTrace: snapshot.stackTrace);
                }

                var people = snapshot.data;
                if (people == null) {
                  return Center(child: CircularProgressIndicator());
                }

                return GridView.builder(
                    shrinkWrap: true,
                    controller: _scrollController,
                    gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 120, crossAxisSpacing: 10, mainAxisSpacing: 10),
                    itemCount: people.length,
                    itemBuilder: (BuildContext context, int index) {
                      var item = people[index];

                      return GestureDetector(
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => PersonPage(id: item.id))),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(100),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              ExtendedImage.network(
                                '${item.thumbUrl}',
                                cache: true,
                                clearMemoryCacheIfFailed: true,
                                headers: {
                                  'Authorization': model.authorization,
                                  'OCS-APIRequest': 'true'
                                },
                                height: 200,
                                width: 200,
                                fit: BoxFit.cover,
                                filterQuality: FilterQuality.high,
                                enableLoadState: true,
                                loadStateChanged: (state) {
                                  switch (state.extendedImageLoadState) {
                                    case LoadState.loading:
                                      return Container(color: Colors.white10);
                                    case LoadState.failed:
                                      return state.completedWidget;
                                    default:
                                      return state.completedWidget;
                                  }
                                },
                              ),
                              Container(color: Colors.black45),
                              Container(
                                margin: EdgeInsets.all(8),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(item.name, textAlign: TextAlign.center, maxLines: 5, style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      shadows: [
                                        Shadow(
                                          blurRadius: 20.0,
                                          color: Colors.black,
                                          offset: Offset(5, 0),
                                        ),
                                      ],
                                    )),
                                  ],
                                ),
                              )
                            ],
                          ),
                        ),
                      );
                    });
              },
            ))
          ],
        ),
      );
    });
  }
}
