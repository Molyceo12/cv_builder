class Language {
  final int? id;
  final int personalDetailsId;
  final String language;
  final String level;

  Language({
    this.id,
    required this.personalDetailsId,
    required this.language,
    required this.level,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'personalDetailsId': personalDetailsId,
      'language': language,
      'level': level,
    };
  }

  factory Language.fromMap(Map<String, dynamic> map) {
    return Language(
      id: map['id'],
      personalDetailsId: map['personalDetailsId'],
      language: map['language'],
      level: map['level'],
    );
  }

  Language copyWith({
    int? id,
    int? personalDetailsId,
    String? language,
    String? level,
  }) {
    return Language(
      id: id ?? this.id,
      personalDetailsId: personalDetailsId ?? this.personalDetailsId,
      language: language ?? this.language,
      level: level ?? this.level,
    );
  }
}
