class User {
  final String id;
  final String? username;
  final String? name;
  final String? surname;
  final String? token;
  final String? expiresAt;

  User({
    required this.id,
    this.username,
    this.name,
    this.surname,
    this.token,
    this.expiresAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      surname: json['surname'] as String? ?? '',
      username: json['username'] as String? ?? '',
      token: json['token'] as String? ?? '',
      expiresAt: json['expiresAt'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'surname': surname,
      'username': username,
      'token': token,
      'expiresAt': expiresAt,
    };
  }
}
