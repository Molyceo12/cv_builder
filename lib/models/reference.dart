class Reference {
  final int? id;
  final int personalDetailsId;
  final String name;
  final String role;
  final String company;
  final String phone;
  final String email;

  Reference({
    this.id,
    required this.personalDetailsId,
    required this.name,
    required this.role,
    required this.company,
    required this.phone,
    required this.email,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'personalDetailsId': personalDetailsId,
      'name': name,
      'role': role,
      'company': company,
      'phone': phone,
      'email': email,
    };
  }

  factory Reference.fromMap(Map<String, dynamic> map) {
    return Reference(
      id: map['id'] as int?,
      personalDetailsId: map['personalDetailsId'] as int? ?? 0,
      name: map['name'] as String? ?? '',
      role: map['role'] as String? ?? '',
      company: map['company'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      email: map['email'] as String? ?? '',
    );
  }

  Reference copyWith({
    int? id,
    int? personalDetailsId,
    String? name,
    String? role,
    String? company,
    String? phone,
    String? email,
  }) {
    return Reference(
      id: id ?? this.id,
      personalDetailsId: personalDetailsId ?? this.personalDetailsId,
      name: name ?? this.name,
      role: role ?? this.role,
      company: company ?? this.company,
      phone: phone ?? this.phone,
      email: email ?? this.email,
    );
  }
}
