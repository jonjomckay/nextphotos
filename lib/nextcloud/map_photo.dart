class NextcloudMapPhoto {
  final int id;
  final String path;
  final double lat;
  final double lng;

  NextcloudMapPhoto(this.id, this.path, this.lat, this.lng);

  factory NextcloudMapPhoto.fromJson(dynamic json) {
    return NextcloudMapPhoto(
      json['fileid'] as int,
      json['path'] as String,
      json['lat'] as double,
      json['lng'] as double,
    );
  }
}