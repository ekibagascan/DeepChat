class UserModel {
  final String id;
  final String email;
  final String subscriptionStatus;

  UserModel({
    required this.id,
    required this.email,
    required this.subscriptionStatus,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      email: json['email'],
      subscriptionStatus: json['subscription_status'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'subscription_status': subscriptionStatus,
    };
  }
} 