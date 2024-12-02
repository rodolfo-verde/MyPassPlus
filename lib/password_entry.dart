class PasswordEntry {
  final String key;
  String user;
  String password;
  bool isStarred;

  PasswordEntry({
    required this.key,
    required this.user,
    required this.password,
    this.isStarred = false,
  });

  // Convert PasswordEntry to JSON
  Map<String, dynamic> toJson() => {
        'key': key,
        'user': user,
        'password': password,
        'isStarred': isStarred,
      };

  // Create PasswordEntry from JSON
  factory PasswordEntry.fromJson(Map<String, dynamic> json) {
    return PasswordEntry(
      key: json['key'],
      user: json['user'],
      password: json['password'],
      isStarred: json['isStarred'] ?? false,
    );
  }
}
