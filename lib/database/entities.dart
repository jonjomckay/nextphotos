class Photo {
  final String id;
  final String name;
  final String path;
  final DateTime modifiedAt;
  final DateTime scannedAt;

  Photo({this.id, this.name, this.path, this.modifiedAt, this.scannedAt});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'path': path,
      'modified_at': modifiedAt.millisecondsSinceEpoch,
      'scanned_at': scannedAt.millisecondsSinceEpoch
    };
  }
}

class PhotoListItem {
  final String id;
  final DateTime modifiedAt;

  PhotoListItem({ this.id, this.modifiedAt });
}