class User {
  final int id;
  final String email;
  final String username;
  final String firstName;
  final String lastName;
  final String? avatar;
  final int apiCallsCount;
  final DateTime createdAt;

  User({
    required this.id,
    required this.email,
    required this.username,
    this.firstName = '',
    this.lastName = '',
    this.avatar,
    this.apiCallsCount = 0,
    required this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      email: json['email'],
      username: json['username'],
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      avatar: json['avatar'],
      apiCallsCount: json['api_calls_count'] ?? 0,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'username': username,
      'first_name': firstName,
      'last_name': lastName,
      'avatar': avatar,
      'api_calls_count': apiCallsCount,
      'created_at': createdAt.toIso8601String(),
    };
  }

  String get fullName => '$firstName $lastName'.trim();
}
