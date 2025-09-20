import 'package:cloud_firestore/cloud_firestore.dart';

import '../Services/live_stream_models.dart';

class LiveStreamProvider {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 🔹 Fetch all live events
  Stream<List<LiveEvent>> getLiveEvents() {
    return _firestore
        .collection("live_events")
        .withConverter<LiveEvent>(
          fromFirestore: LiveEvent.fromFirestore,
          toFirestore: (event, _) => event.toFirestore(),
        )
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  /// 🔹 Fetch single live event
  Future<LiveEvent?> getLiveEventById(String id) async {
    final doc =
        await _firestore
            .collection("live_events")
            .doc(id)
            .withConverter<LiveEvent>(
              fromFirestore: LiveEvent.fromFirestore,
              toFirestore: (event, _) => event.toFirestore(),
            )
            .get();
    return doc.data();
  }

  /// 🔹 Update viewer count
  Future<void> updateViewerCount(String eventId, int count) async {
    await _firestore.collection("live_events").doc(eventId).update({
      "currentViewers": count,
    });
  }
}
