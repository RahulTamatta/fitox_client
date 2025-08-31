class UserInfo {
  final String id;
  final String name;
  final String email;
  final String? profileImage;
  final String? role;
  final bool isOnline;

  UserInfo({
    required this.id,
    required this.name,
    required this.email,
    this.profileImage,
    this.role,
    this.isOnline = false,
  });

  factory UserInfo.fromJson(Map<String, dynamic> json) {
    return UserInfo(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      profileImage: json['profileImage'],
      role: json['role'],
      isOnline: json['isOnline'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'profileImage': profileImage,
      'role': role,
      'isOnline': isOnline,
    };
  }
}
