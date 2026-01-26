class PersonalDetails {
  final int? id;
  final String jobTarget;
  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final String address;
  final String cityState;
  final String country;
  final String postalCode;
  final String drivingLicense;
  final String linkedin;
  final String dateOfBirth;
  final String placeOfBirth;
  final String gender;
  final String nationality;
  final String github;
  final String summary;
  final String? photoPath;
  final String? remoteCvId;
  final DateTime createdAt;
  final DateTime updatedAt;

  PersonalDetails({
    this.id,
    required this.jobTarget,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.address,
    required this.cityState,
    required this.country,
    required this.postalCode,
    required this.drivingLicense,
    required this.linkedin,
    this.dateOfBirth = '',
    this.placeOfBirth = '',
    this.gender = '',
    this.nationality = '',
    this.github = '',
    this.summary = '',
    this.photoPath,
    this.remoteCvId,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  // Convert a PersonalDetails object into a Map object
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'jobTarget': jobTarget,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'phone': phone,
      'address': address,
      'cityState': cityState,
      'country': country,
      'postalCode': postalCode,
      'drivingLicense': drivingLicense,
      'linkedin': linkedin,
      'dateOfBirth': dateOfBirth,
      'placeOfBirth': placeOfBirth,
      'gender': gender,
      'nationality': nationality,
      'github': github,
      'summary': summary,
      'photoPath': photoPath,
      'remoteCvId': remoteCvId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // Extract a PersonalDetails object from a Map object
  factory PersonalDetails.fromMap(Map<String, dynamic> map) {
    return PersonalDetails(
      id: map['id'] as int?,
      jobTarget: map['jobTarget'] as String? ?? '',
      firstName: map['firstName'] as String? ?? '',
      lastName: map['lastName'] as String? ?? '',
      email: map['email'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      address: map['address'] as String? ?? '',
      cityState: map['cityState'] as String? ?? '',
      country: map['country'] as String? ?? '',
      postalCode: map['postalCode'] as String? ?? '',
      drivingLicense: map['drivingLicense'] as String? ?? '',
      linkedin: map['linkedin'] as String? ?? '',
      dateOfBirth: map['dateOfBirth'] as String? ?? '',
      placeOfBirth: map['placeOfBirth'] as String? ?? '',
      gender: map['gender'] as String? ?? '',
      nationality: map['nationality'] as String? ?? '',
      github: map['github'] as String? ?? '',
      summary: map['summary'] as String? ?? '',
      photoPath: map['photoPath'] as String?,
      remoteCvId: map['remoteCvId'] as String?,
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'] as String)
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'] as String)
          : DateTime.now(),
    );
  }

  // Create a copy with updated values
  PersonalDetails copyWith({
    int? id,
    String? jobTarget,
    String? firstName,
    String? lastName,
    String? email,
    String? phone,
    String? address,
    String? cityState,
    String? country,
    String? postalCode,
    String? drivingLicense,
    String? linkedin,
    String? dateOfBirth,
    String? placeOfBirth,
    String? gender,
    String? nationality,
    String? github,
    String? summary,
    String? photoPath,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PersonalDetails(
      id: id ?? this.id,
      jobTarget: jobTarget ?? this.jobTarget,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      cityState: cityState ?? this.cityState,
      country: country ?? this.country,
      postalCode: postalCode ?? this.postalCode,
      drivingLicense: drivingLicense ?? this.drivingLicense,
      linkedin: linkedin ?? this.linkedin,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      placeOfBirth: placeOfBirth ?? this.placeOfBirth,
      gender: gender ?? this.gender,
      nationality: nationality ?? this.nationality,
      github: github ?? this.github,
      summary: summary ?? this.summary,
      photoPath: photoPath ?? this.photoPath,
      remoteCvId: remoteCvId ?? this.remoteCvId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'PersonalDetails{id: $id, firstName: $firstName, lastName: $lastName, email: $email}';
  }
}
