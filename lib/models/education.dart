class Education {
  final int? id;
  final int? personalDetailsId;
  final String school;
  final String degree;
  final String startDate;
  final String? endDate;
  final bool isCurrent;
  final String cityState;
  final String? description;

  Education({
    this.id,
    this.personalDetailsId,
    required this.school,
    required this.degree,
    required this.startDate,
    this.endDate,
    this.isCurrent = false,
    required this.cityState,
    this.description,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'personalDetailsId': personalDetailsId,
      'school': school,
      'degree': degree,
      'startDate': startDate,
      'endDate': endDate,
      'isCurrent': isCurrent ? 1 : 0,
      'cityState': cityState,
      'description': description,
    };
  }

  factory Education.fromMap(Map<String, dynamic> map) {
    return Education(
      id: map['id'] as int?,
      personalDetailsId: map['personalDetailsId'] as int?,
      school: map['school'] as String? ?? '',
      degree: map['degree'] as String? ?? '',
      startDate: map['startDate'] as String? ?? '',
      endDate: map['endDate'] as String?,
      isCurrent: (map['isCurrent'] as int? ?? 0) == 1,
      cityState: map['cityState'] as String? ?? '',
      description: map['description'] as String?,
    );
  }

  Education copyWith({
    int? id,
    int? personalDetailsId,
    String? school,
    String? degree,
    String? startDate,
    String? endDate,
    bool? isCurrent,
    String? cityState,
    String? description,
  }) {
    return Education(
      id: id ?? this.id,
      personalDetailsId: personalDetailsId ?? this.personalDetailsId,
      school: school ?? this.school,
      degree: degree ?? this.degree,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isCurrent: isCurrent ?? this.isCurrent,
      cityState: cityState ?? this.cityState,
      description: description ?? this.description,
    );
  }
}
