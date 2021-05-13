import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:nextphotos/database/entities.dart';
import 'package:nextphotos/home/home_model.dart';
import 'package:nextphotos/photo/photo_list.dart';
import 'package:provider/provider.dart';

class PersonPage extends StatefulWidget {
  final int id;

  const PersonPage({Key? key, required this.id}) : super(key: key);

  @override
  _PersonPageState createState() => _PersonPageState();
}

class _PersonPageState extends State<PersonPage> {
  @override
  Widget build(BuildContext context) {
    return Consumer<HomeModel>(
      builder: (context, model, child) {
        return FutureBuilder<PersonGet>(
          future: model.getPerson(widget.id),
          builder: (context, snapshot) {
            var error = snapshot.error;
            if (error != null) {
              log('Unable to load the person', error: error);
            }

            var person = snapshot.data;
            if (person == null) {
              return Center(child: CircularProgressIndicator());
            }

            return Scaffold(
              appBar: AppBar(),
              body: Container(child: PhotoList(
                itemsFuture: Future.value(person.photos),
                onRefresh: (something) {

                },
              )),
            );
          },
        );
      },
    );
  }
}
