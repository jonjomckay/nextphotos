class Photo {
  final String id;
  final bool favourite;
  final String name;
  final String path;
  final DateTime modifiedAt;
  final DateTime scannedAt;

  Photo({required this.id, required this.favourite, required this.name, required this.path, required this.modifiedAt, required this.scannedAt});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'favourite': favourite ? 1 : 0,
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

  PhotoListItem({ required this.id, required this.modifiedAt });
}