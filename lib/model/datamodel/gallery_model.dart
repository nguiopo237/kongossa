// models/image_item.dart
class ImageItem {
  final String id;
  final String url;
  final String? localPath;
  final DateTime createdAt;
  bool isSelected;

  ImageItem({
    required this.id,
    required this.url,
    this.localPath,
    required this.createdAt,
    this.isSelected = false,
  });

  factory ImageItem.fromNetwork(String url) {
    return ImageItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      url: url,
      createdAt: DateTime.now(),
    );
  }

  factory ImageItem.fromLocal(String path) {
    return ImageItem(
      id: path.hashCode.toString(),
      url: path,
      localPath: path,
      createdAt: DateTime.now(),
    );
  }
}