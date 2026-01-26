class Skill {
  final int? id;
  final int personalDetailsId;
  final String skillName;
  final String level;

  Skill({
    this.id,
    required this.personalDetailsId,
    required this.skillName,
    required this.level,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'personalDetailsId': personalDetailsId,
      'skillName': skillName,
      'level': level,
    };
  }

  factory Skill.fromMap(Map<String, dynamic> map) {
    return Skill(
      id: map['id'],
      personalDetailsId: map['personalDetailsId'],
      skillName: map['skillName'],
      level: map['level'],
    );
  }

  Skill copyWith({
    int? id,
    int? personalDetailsId,
    String? skillName,
    String? level,
  }) {
    return Skill(
      id: id ?? this.id,
      personalDetailsId: personalDetailsId ?? this.personalDetailsId,
      skillName: skillName ?? this.skillName,
      level: level ?? this.level,
    );
  }
}
