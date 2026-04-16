// lib/models/story_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class StoryModel {
  final String id;
  final String userName;
  final String userAvatar;
  final List<StoryItem> stories;
  final bool isViewed;
  final DateTime timestamp;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime expiresAt;

  StoryModel({
    required this.id,
    required this.userName,
    required this.userAvatar,
    required this.stories,
    DateTime? timestamp,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? expiresAt,
    this.isViewed = false,
  }): timestamp = timestamp ?? DateTime.now(),createdAt = createdAt ?? DateTime.now(),updatedAt = updatedAt ?? DateTime.now(),expiresAt = expiresAt ?? DateTime.now().add(Duration(hours: 24));

  // Factory constructor pour créer un StoryModel depuis une Map
  factory StoryModel.fromMap(Map<String, dynamic> map) {

    return StoryModel(
      id: map['id'] as String,
      userName: map['userName'] as String,
      userAvatar: map['userAvatar'] as String,
      stories: _parseStories(map['stories']),
      isViewed: map['isViewed'] as bool? ?? false,
      expiresAt: (map['expiresAt'] as Timestamp).toDate().add(Duration(days: 24)),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }

  // Méthode pour convertir StoryModel en Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userName': userName,
      'userAvatar': userAvatar,
      'stories': stories.map((story) => story.toMap()).toList(),
      'isViewed': isViewed,
      'expiresAt': expiresAt,
      'updatedAt': updatedAt,
      'createdAt': createdAt,
    };
  }

  // Méthode utilitaire privée pour parser la liste des stories
  static List<StoryItem> _parseStories(dynamic storiesData) {
    if (storiesData == null) return [];

    if (storiesData is List) {
      return storiesData
          .map((story) => StoryItem.fromMap(story as Map<String, dynamic>))
          .toList();
    }

    return [];
  }

  // Méthode copyWith pour créer une copie modifiée
  StoryModel copyWith({
    String? id,
    String? userName,
    String? userAvatar,
    List<StoryItem>? stories,
    bool? isViewed,
  }) {
    return StoryModel(
      id: id ?? this.id,
      userName: userName ?? this.userName,
      userAvatar: userAvatar ?? this.userAvatar,
      stories: stories ?? this.stories,
      isViewed: isViewed ?? this.isViewed,
    );
  }
}

class StoryItem {
  final String id;
  final String mediaUrl;
  final StoryMediaType mediaType;
  final Duration duration;
  final String? caption;

  bool isViewed;

  StoryItem({
    required this.id,
    required this.mediaUrl,
    required this.mediaType,
    this.duration = const Duration(seconds: 5),
    this.caption,

    this.isViewed = false,
  }) ;
  // Factory constructor pour créer un StoryItem depuis une Map
  factory StoryItem.fromMap(Map<String, dynamic> map) {
    return StoryItem(
      id: map['id'] as String,
      mediaUrl: map['mediaUrl'] as String,
      mediaType: _parseMediaType(map['mediaType']),
      duration: Duration(seconds: map['duration'] as int? ?? 5),
      caption: map['caption'] as String?,
     // timestamp: DateTime.parse((map['timestamp'] as Timestamp).toDate().toString()),
     //  createdAt: map['createdAt'] != null
     //      ? DateTime.parse(map['createdAt'] as String)
     //      : null,
     //  updatedAt: map['updatedAt'] != null
     //      ? DateTime.parse(map['updatedAt'] as String)
     //      : null,

      isViewed: map['isViewed'] as bool? ?? false,
    );
  }

  // Méthode pour convertir StoryItem en Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'mediaUrl': mediaUrl,
      'mediaType': mediaType.toString().split('.').last,
      'duration': duration.inSeconds,
      'caption': caption,
      // 'timestamp': timestamp.toIso8601String(),
      'isViewed': isViewed,
      // 'createdAt': createdAt,
      // 'updatedAt': updatedAt,
      // 'expiresAt': expiresAt,
    };
  }

  // Méthode utilitaire privée pour parser le type de média
  static StoryMediaType _parseMediaType(String? mediaType) {
    switch (mediaType) {
      case 'video':
        return StoryMediaType.video;
      case 'image':
      default:
        return StoryMediaType.image;
    }
  }

  // Méthode copyWith pour créer une copie modifiée
  StoryItem copyWith({
    String? id,
    String? mediaUrl,
    StoryMediaType? mediaType,
    Duration? duration,
    String? caption,
    DateTime? timestamp,
    bool? isViewed,
  }) {
    return StoryItem(
      id: id ?? this.id,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      mediaType: mediaType ?? this.mediaType,
      duration: duration ?? this.duration,
      caption: caption ?? this.caption,
      // timestamp: timestamp ?? this.timestamp,
      isViewed: isViewed ?? this.isViewed,
    );
  }
}

enum StoryMediaType {
  image,
  video;

  // Méthode utilitaire pour convertir en string
  String toJson() => toString().split('.').last;

  // Méthode utilitaire pour créer depuis une string
  static StoryMediaType fromJson(String json) {
    return StoryMediaType.values.firstWhere(
          (e) => e.toJson() == json,
      orElse: () => StoryMediaType.image,
    );
  }
}

