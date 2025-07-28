import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'current_user_id_provider.dart';

final connectionsProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  final firestore = FirebaseFirestore.instance;
  final userId = await ref.watch(currentUserIdProvider.future);

  // Fetch friend UIDs from connections
  final friendRefs =
      await firestore
          .collection('connections')
          .doc(userId)
          .collection('friends')
          .get();

  final friendUids = friendRefs.docs.map((doc) => doc.id).toList();
  if (friendUids.isEmpty) {
    print('[connectionsProvider] No friend UIDs found for user $userId.');
    return [];
  }

  print('[connectionsProvider] Total friend UIDs: ${friendUids.length}');
  final List<Map<String, dynamic>> allFriends = [];

  for (var i = 0; i < friendUids.length; i += 10) {
    final batch = friendUids.sublist(
      i,
      (i + 10 > friendUids.length) ? friendUids.length : i + 10,
    );
    print('[connectionsProvider] Looking up batch: $batch');

    final emailSnapshot =
        await firestore
            .collection('user_details_email')
            .where(FieldPath.documentId, whereIn: batch)
            .get();

    final phoneSnapshot =
        await firestore
            .collection('user_details_phone')
            .where(FieldPath.documentId, whereIn: batch)
            .get();

    final combinedDocs = [...emailSnapshot.docs, ...phoneSnapshot.docs];

    for (final doc in combinedDocs) {
      final data = doc.data();
      print('[connectionsProvider] Friend found: ${doc.id}');

      allFriends.add({
        'uid': doc.id,
        'name': data['name'] ?? '',
        'email': data['email'] ?? '',
        'location': data['location'] ?? '',
        'photoUrl': data['photoUrl'] ?? '',
        'phone': data['phone_number'] ?? '',
      });
    }
  }

  allFriends.sort(
    (a, b) => a['name'].toString().compareTo(b['name'].toString()),
  );

  print('[connectionsProvider] Total friends fetched: ${allFriends.length}');
  return allFriends;
});
