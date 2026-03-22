class UserModel {
  final String uid;
  final String email;
  final String name;
  final String role; // 'member', 'trainer', 'admin'
  final String? profileImageUrl;
  final String? phone;
  final String? specialization; // for trainers
  final String? experience; // for trainers
  final String? bio; // for trainers

  UserModel({
    required this.uid,
    required this.email,
    required this.name,
    required this.role,
    this.profileImageUrl,
    this.phone,
    this.specialization,
    this.experience,
    this.bio,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      uid: json['uid'] ?? '',
      email: json['email'] ?? '',
      name: json['name'] ?? '',
      role: json['role'] ?? 'member',
      profileImageUrl: json['profileImageUrl'],
      phone: json['phone'],
      specialization: json['specialization'],
      experience: json['experience'],
      bio: json['bio'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
      'role': role,
      'profileImageUrl': profileImageUrl,
      'phone': phone,
      'specialization': specialization,
      'experience': experience,
      'bio': bio,
    };
  }
}
