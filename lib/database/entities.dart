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