class UserProfile {
  final String uid;
  final String name;
  final String chronotype; // 아침형 / 저녁형
  final double cafSens;
  final double lightSens;

  UserProfile({
    required this.uid,
    required this.name,
    required this.chronotype,
    required this.cafSens,
    required this.lightSens,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'chronotype': chronotype,
      'cafSens': cafSens,
      'lightSens': lightSens,
    };
  }

  factory UserProfile.fromMap(String uid, Map<String, dynamic> map) {
    return UserProfile(
      uid: uid,
      name: map['name'] ?? '',
      chronotype: map['chronotype'] ?? 'neutral',
      cafSens: (map['cafSens'] ?? 0.5).toDouble(),
      lightSens: (map['lightSens'] ?? 0.5).toDouble(),
    );
  }
}
