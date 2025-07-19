import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../Services/user_model.dart';

final userProfileProvider = FutureProvider.family<UserModel, String>((
  ref,
  uid,
) async {
  final phoneDoc =
      await FirebaseFirestore.instance
          .collection('user_details_phone')
          .doc(uid)
          .get();
  if (phoneDoc.exists) {
    return UserModel.fromMap(phoneDoc.data()!, uid);
  }

  final emailDoc =
      await FirebaseFirestore.instance
          .collection('user_details_email')
          .doc(uid)
          .get();
  if (emailDoc.exists) {
    return UserModel.fromMap(emailDoc.data()!, uid);
  }

  throw Exception("User not found");
});

final friendsCountProvider = FutureProvider.family<int, String>((
  ref,
  userId,
) async {
  final snapshot =
      await FirebaseFirestore.instance
          .collection(
            'connections',
          ) // or use 'user_details_xxx/userId/friends' if you’re using subcollection
          .doc(userId)
          .collection('friends')
          .get();

  return snapshot.docs.length;
});
