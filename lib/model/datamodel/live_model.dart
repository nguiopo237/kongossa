import 'package:cloud_firestore/cloud_firestore.dart';

enum LiveStatus { live, ended, scheduled }

class LiveModel {
  final String id;
  final String hostId;
  final String hostName;
  final String hostAvatar;
  final String title;
  final String description;
  final LiveStatus status;
  final String? streamUrl;
  final String? thumbnailUrl;
  final int viewers;
  final int likes;
  final List<String> viewerIds;
  final DateTime startedAt;
  final DateTime? endedAt;
  final DateTime? scheduledAt;

  LiveModel({
    required this.id,
    required this.hostId,
    required this.hostName,
    required this.hostAvatar,
    required this.title,
    this.description = '',
    this.status = LiveStatus.live,
    this.streamUrl,
    this.thumbnailUrl,
    this.viewers = 0,
    this.likes = 0,
    this.viewerIds = const [],
    required this.startedAt,
    this.endedAt,
    this.scheduledAt,
  });

  bool get isLive => status == LiveStatus.live;
  bool get isEnded => status == LiveStatus.ended;
  String get duration {
    final diff = DateTime.now().difference(startedAt);
    if (diff.inHours > 0) return '${diff.inHours}h ${diff.inMinutes.remainder(60)}m';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m';
    return '${diff.inSeconds}s';
  }

  factory LiveModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final statusStr = data['status'] as String? ?? 'live';
    return LiveModel(
      id: doc.id,
      hostId: data['hostId'] ?? '',
      hostName: data['hostName'] ?? '',
      hostAvatar: data['hostAvatar'] ?? '',
      title: data['title'] ?? 'Live',
      description: data['description'] ?? '',
      status: LiveStatus.values.firstWhere(
        (e) => e.name == statusStr,
        orElse: () => LiveStatus.live,
      ),
      streamUrl: data['streamUrl'],
      thumbnailUrl: data['thumbnailUrl'],
      viewers: data['viewers'] ?? 0,
      likes: data['likes'] ?? 0,
      viewerIds: List<String>.from(data['viewerIds'] ?? []),
      startedAt: (data['startedAt'] as Timestamp).toDate(),
      endedAt: (data['endedAt'] as Timestamp?)?.toDate(),
      scheduledAt: (data['scheduledAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'hostId': hostId,
      'hostName': hostName,
      'hostAvatar': hostAvatar,
      'title': title,
      'description': description,
      'status': status.name,
      'streamUrl': streamUrl,
      'thumbnailUrl': thumbnailUrl,
      'viewers': viewers,
      'likes': likes,
      'viewerIds': viewerIds,
      'startedAt': Timestamp.fromDate(startedAt),
      'endedAt': endedAt != null ? Timestamp.fromDate(endedAt!) : null,
      'scheduledAt': scheduledAt != null ? Timestamp.fromDate(scheduledAt!) : null,
    };
  }
}
