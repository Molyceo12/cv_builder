class WorkExperience {
  final int? id;
  final int personalDetailsId;
  final String jobTitle;
  final String employer;
  final String startDate;
  final String? endDate;
  final bool isCurrent;
  final String cityState;
  final String? description;

  WorkExperience({
    this.id,
    required this.personalDetailsId,
    required this.jobTitle,
    required this.employer,
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
      'jobTitle': jobTitle,
      'employer': employer,
      'startDate': startDate,
      'endDate': endDate,
      'isCurrent': isCurrent ? 1 : 0,
      'cityState': cityState,
      'description': description,
    };
  }

  factory WorkExperience.fromMap(Map<String, dynamic> map) {
    return WorkExperience(
      id: map['id'] as int?,
      personalDetailsId: map['personalDetailsId'] as int,
      jobTitle: map['jobTitle'] as String? ?? '',
      employer: map['employer'] as String? ?? '',
      startDate: map['startDate'] as String? ?? '',
      endDate: map['endDate'] as String?,
      isCurrent: (map['isCurrent'] as int? ?? 0) == 1,
      cityState: map['cityState'] as String? ?? '',
      description: map['description'] as String?,
    );
  }

  WorkExperience copyWith({
    int? id,
    int? personalDetailsId,
    String? jobTitle,
    String? employer,
    String? startDate,
    String? endDate,
    bool? isCurrent,
    String? cityState,
    String? description,
  }) {
    return WorkExperience(
      id: id ?? this.id,
      personalDetailsId: personalDetailsId ?? this.personalDetailsId,
      jobTitle: jobTitle ?? this.jobTitle,
      employer: employer ?? this.employer,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isCurrent: isCurrent ?? this.isCurrent,
      cityState: cityState ?? this.cityState,
      description: description ?? this.description,
    );
  }

  @override
  String toString() {
    return 'WorkExperience{id: $id, jobTitle: $jobTitle, employer: $employer, isCurrent: $isCurrent}';
  }
}
