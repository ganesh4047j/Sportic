class UserModel {
  final String uid;
  final String name;
  final String? phoneNumber;
  final String? location;
  final String? photoUrl;
  final bool isFriend;
  final int gamesPlayed;
  final int gamesWon;
  final List<String> achievements;
  final String? bio; // ✅ Added this line

  UserModel({
    required this.uid,
    required this.name,
    this.phoneNumber,
    this.location,
    this.photoUrl,
    required this.isFriend,
    required this.gamesPlayed,
    required this.gamesWon,
    required this.achievements,
    this.bio, // ✅ Added this line
  });

  factory UserModel.fromMap(Map<String, dynamic> data, String uid) {
    return UserModel(
      uid: uid,
      name: data['name'] ?? '',
      phoneNumber: data['phone_number'],
      location: data['location'],
      photoUrl: data['photoUrl'],
      isFriend: data['isFriend'] ?? false,
      gamesPlayed: data['gamesPlayed'] ?? 0,
      gamesWon: data['gamesWon'] ?? 0,
      achievements: List<String>.from(data['achievements'] ?? []),
      bio: data['bio'], // ✅ Added this line
    );
  }
}
