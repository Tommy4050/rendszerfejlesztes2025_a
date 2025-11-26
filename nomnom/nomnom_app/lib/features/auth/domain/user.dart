class AppUser {
  final String id;
  final String username;
  final String email;
  final String? profilePictureRef;
  final String? bio;

  AppUser({
    required this.id,
    required this.username,
    required this.email,
    this.profilePictureRef,
    this.bio,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['_id'] ?? json['id'],
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      profilePictureRef: json['profilePictureRef'],
      bio: json['bio'],
    );
  }
}
