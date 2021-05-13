class NextCloudFacePerson {
  final String name;
  final String thumbUrl;
  final int count;

  NextCloudFacePerson(this.name, this.thumbUrl, this.count);

  factory NextCloudFacePerson.fromJson(dynamic json) {
    return NextCloudFacePerson(
        json['name'],
        json['thumbUrl'],
        json['count']
    );
  }
}

class NextCloudFacePersonPhoto {
  final String thumbUrl;
  final String fileUrl;

  NextCloudFacePersonPhoto(this.thumbUrl, this.fileUrl);

  factory NextCloudFacePersonPhoto.fromJson(dynamic json) {
    return NextCloudFacePersonPhoto(
      json['thumbUrl'],
      json['fileUrl']
    );
  }
}

class NextCloudMapPhoto {
  final int id;
  final String path;
  final double lat;
  final double lng;

  NextCloudMapPhoto(this.id, this.path, this.lat, this.lng);

  factory NextCloudMapPhoto.fromJson(dynamic json) {
    return NextCloudMapPhoto(
      json['fileid'] as int,
      json['path'] as String,
      json['lat'] as double,
      json['lng'] as double,
    );
  }
}
