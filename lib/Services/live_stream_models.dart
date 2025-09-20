import 'package:cloud_firestore/cloud_firestore.dart';

class StreamMetadata {
  final String turfId;
  final String turfName;
  final String thumbnailUrl;

  StreamMetadata({
    required this.turfId,
    required this.turfName,
    required this.thumbnailUrl,
  });

  factory StreamMetadata.fromJson(Map<String, dynamic> json) {
    return StreamMetadata(
      turfId: json['turfId'] ?? '',
      turfName: json['turfName'] ?? '',
      thumbnailUrl: json['thumbnailUrl'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'turfId': turfId,
      'turfName': turfName,
      'thumbnailUrl': thumbnailUrl,
    };
  }
}

class LiveEvent {
  final String id;
  final String roomId;
  final StreamMetadata metadata;
  final String rtmpUrl;
  final String streamKey;
  final String status;
  final DateTime createdAt;
  final DateTime startTime;
  final DateTime? liveStartedAt;
  final int currentViewers;

  LiveEvent({
    required this.id,
    required this.roomId,
    required this.metadata,
    required this.rtmpUrl,
    required this.streamKey,
    required this.status,
    required this.createdAt,
    required this.startTime,
    this.liveStartedAt,
    this.currentViewers = 0,
  });

  /// ✅ UI compatibility
  String get thumbnail => metadata.thumbnailUrl;
  String get title => metadata.turfName;

  /// ✅ Firestore converter
  factory LiveEvent.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
    SnapshotOptions? options,
  ) {
    final data = doc.data()!;
    return LiveEvent(
      id: doc.id,
      roomId: data['roomId'] ?? '',
      metadata: StreamMetadata.fromJson(data['metadata'] ?? {}),
      rtmpUrl: data['rtmpUrl'] ?? '',
      streamKey: data['streamKey'] ?? '',
      status: data['status'] ?? 'scheduled',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      startTime: DateTime.parse(data['startTime']),
      liveStartedAt:
          data['liveStartedAt'] != null
              ? DateTime.parse(data['liveStartedAt'])
              : null,
      currentViewers: data['currentViewers'] ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() => {
    'roomId': roomId,
    'metadata': metadata.toJson(),
    'rtmpUrl': rtmpUrl,
    'streamKey': streamKey,
    'status': status,
    'createdAt': createdAt,
    'startTime': startTime.toIso8601String(),
    'liveStartedAt': liveStartedAt?.toIso8601String(),
    'currentViewers': currentViewers,
  };
}
