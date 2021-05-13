class Photo {
  final String id;
  final bool favourite;
  final String name;
  final String path;
  final String? downloadPath;
  final DateTime modifiedAt;
  final DateTime scannedAt;

  Photo({required this.id, required this.favourite, required this.name, required this.path, this.downloadPath, required this.modifiedAt, required this.scannedAt});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'favourite': favourite ? 1 : 0,
      'name': name,
      'path': path,
      'download_path': downloadPath,
      'modified_at': modifiedAt.millisecondsSinceEpoch,
      'scanned_at': scannedAt.millisecondsSinceEpoch
    };
  }
}

class Location {
  final int id;
  final String name;
  final String? state;
  final double lat;
  final double lng;
  final String coverPhoto;
  final int numberOfPhotos;

  Location({required this.id, required this.name, required this.state, required this.lat, required this.lng, required this.coverPhoto, required this.numberOfPhotos});
}

class LocationGet {
  final int id;
  final String name;
  final List<Photo> photos;

  LocationGet({required this.id, required this.name, required this.photos});
}

class Person {
  final int id;
  final String name;
  final String thumbUrl;

  Person({required this.id, required this.name, required this.thumbUrl});
}

class PersonGet {
  final int id;
  final String name;
  final List<Photo> photos;

  PersonGet({required this.id, required this.name, required this.photos});
}