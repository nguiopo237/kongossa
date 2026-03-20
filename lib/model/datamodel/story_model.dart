import 'package:cloud_firestore/cloud_firestore.dart';

class SocialStatus {
  final String id;
  final String userId;
  final String content;
  final List<String> mediaUrls;
  final StatusType type;
  final PrivacyLevel privacyLevel;
  final Timestamp createdAt;
  final DateTime updatedAt;
  final Timestamp? expiresAt;
  late final int likesCount;
  final int commentsCount;
  final int sharesCount;
  final List<String> likedBy;
  final List<Comment> comments;
  final Location? location;
  final List<String> mentions;
  final List<String> hashtags;
  final StatusMetadata metadata;

  SocialStatus({
    required this.id,
    required this.userId,
    required this.content,
    this.mediaUrls = const [],
    this.type = StatusType.text,
    this.privacyLevel = PrivacyLevel.public,
    required this.createdAt,
    required this.updatedAt,
    this.expiresAt,
    this.likesCount = 0,
    this.commentsCount = 0,
    this.sharesCount = 0,
    this.likedBy = const [],
    this.comments = const [],
    this.location,
    this.mentions = const [],
    this.hashtags = const [],
    this.metadata = const StatusMetadata(),
  });

  // Méthodes utilitaires
  // bool get isExpired => expiresAt != null && expiresAt!.isBefore(DateTime.now());

  bool get hasMedia => mediaUrls.isNotEmpty;

  bool get hasLocation => location != null;

  void addLike(String userId) {
    if (!likedBy.contains(userId)) {
      likedBy.add(userId);
      likesCount++;
    }
  }

  void removeLike(String userId) {
    if (likedBy.contains(userId)) {
      likedBy.remove(userId);
      likesCount--;
    }
  }

  bool isLikedBy(String userId) => likedBy.contains(userId);

  // Factory constructor pour créer depuis JSON
  factory SocialStatus.fromJson(Map<String, dynamic> json) {
    return SocialStatus(
      id: json['id'],
      userId: json['userId'],
      content: json['content'],
      mediaUrls: List<String>.from(json['mediaUrls'] ?? []),
      type: StatusType.values.firstWhere(
            (e) => e.toString() == 'StatusType.${json['type']}',
        orElse: () => StatusType.text,
      ),
      privacyLevel: PrivacyLevel.values.firstWhere(
            (e) => e.toString() == 'PrivacyLevel.${json['privacyLevel']}',
        orElse: () => PrivacyLevel.public,
      ),
      createdAt: json['createdAt'],
      updatedAt: DateTime.parse(json['updatedAt']),
      expiresAt: json['expiresAt'] != null
          ? json['expiresAt']
          : null,
      likesCount: json['likesCount'] ?? 0,
      commentsCount: json['commentsCount'] ?? 0,
      sharesCount: json['sharesCount'] ?? 0,
      likedBy: List<String>.from(json['likedBy'] ?? []),
      comments: (json['comments'] as List?)
          ?.map((c) => Comment.fromJson(c))
          .toList() ?? [],
      location: json['location'] != null
          ? Location.fromJson(json['location'])
          : null,
      mentions: List<String>.from(json['mentions'] ?? []),
      hashtags: List<String>.from(json['hashtags'] ?? []),
      metadata: StatusMetadata.fromJson(json['metadata'] ?? {}),
    );
  }

  // Convertir en JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'content': content,
      'mediaUrls': mediaUrls,
      'type': type.toString().split('.').last,
      'privacyLevel': privacyLevel.toString().split('.').last,
      'createdAt': createdAt,
      'updatedAt': updatedAt.toIso8601String(),
      'expiresAt': expiresAt,
      'likesCount': likesCount,
      'commentsCount': commentsCount,
      'sharesCount': sharesCount,
      'likedBy': likedBy,
      'comments': comments.map((c) => c.toJson()).toList(),
      'location': location?.toJson(),
      'mentions': mentions,
      'hashtags': hashtags,
      'metadata': metadata.toJson(),
    };
  }
}

// Énumérations
enum StatusType {
  text,
  image,
  video,
  link,
  poll,
  story,
}

enum PrivacyLevel {
  public,
  friends,
  onlyMe,
  custom,
}

// Modèle pour les commentaires
class Comment {
  final String id;
  final String userId;
  final String content;
  final DateTime createdAt;
  final List<String> likedBy;

  Comment({
    required this.id,
    required this.userId,
    required this.content,
    required this.createdAt,
    this.likedBy = const [],
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['id'],
      userId: json['userId'],
      content: json['content'],
      createdAt: DateTime.parse(json['createdAt']),
      likedBy: List<String>.from(json['likedBy'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
      'likedBy': likedBy,
    };
  }
}

// Modèle pour la localisation
class Location {
  final double latitude;
  final double longitude;
  final String? placeName;
  final String? address;

  Location({
    required this.latitude,
    required this.longitude,
    this.placeName,
    this.address,
  });

  factory Location.fromJson(Map<String, dynamic> json) {
    return Location(
      latitude: json['latitude'],
      longitude: json['longitude'],
      placeName: json['placeName'],
      address: json['address'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'placeName': placeName,
      'address': address,
    };
  }
}

// Métadonnées supplémentaires
class StatusMetadata {
  final bool isEdited;
  final String? source;
  final String? language;
  final Map<String, dynamic> customData;

  const StatusMetadata({
    this.isEdited = false,
    this.source,
    this.language,
    this.customData = const {},
  });

  factory StatusMetadata.fromJson(Map<String, dynamic> json) {
    return StatusMetadata(
      isEdited: json['isEdited'] ?? false,
      source: json['source'],
      language: json['language'],
      customData: json['customData'] ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isEdited': isEdited,
      'source': source,
      'language': language,
      'customData': customData,
    };
  }
}