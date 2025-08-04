// chat_utils.dart - Replace your generateChatId function with this:

String generateChatId(dynamic uid1, dynamic uid2) {
  // Convert to strings safely
  final safeUid1 = uid1?.toString().trim() ?? '';
  final safeUid2 = uid2?.toString().trim() ?? '';

  print(
    '🔥 generateChatId input: uid1=$uid1 (${uid1.runtimeType}), uid2=$uid2 (${uid2.runtimeType})',
  );
  print('🔥 generateChatId safe: uid1=$safeUid1, uid2=$safeUid2');

  if (safeUid1.isEmpty || safeUid2.isEmpty) {
    throw Exception(
      'Invalid UIDs for chat generation: uid1="$safeUid1", uid2="$safeUid2"',
    );
  }

  if (safeUid1 == safeUid2) {
    throw Exception('Cannot create chat with same user: $safeUid1');
  }

  // Sort UIDs to ensure consistent chat ID regardless of order
  final sortedUids = [safeUid1, safeUid2]..sort();
  final chatId = '${sortedUids[0]}_${sortedUids[1]}';

  print('🔥 Generated chatId: $chatId');
  return chatId;
}

// Additional helper function for safe user data extraction
Map<String, String> extractSafeUserData(Map<String, dynamic> userData) {
  return {
    'uid': (userData['uid'] ?? userData['id'] ?? '').toString(),
    'name':
        (userData['name'] ?? userData['displayName'] ?? 'Unknown').toString(),
    'email': (userData['email'] ?? '').toString(),
    'photoUrl':
        (userData['photoUrl'] ?? userData['profilePicture'] ?? '').toString(),
    'location': (userData['location'] ?? '').toString(),
  };
}
