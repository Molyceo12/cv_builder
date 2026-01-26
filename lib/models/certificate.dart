class Certificate {
  final int? id;
  final int personalDetailsId;
  final String title;
  final String date;
  final String description;

  Certificate({
    this.id,
    required this.personalDetailsId,
    required this.title,
    required this.date,
    required this.description,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'personalDetailsId': personalDetailsId,
      'title': title,
      'date': date,
      'description': description,
    };
  }

  factory Certificate.fromMap(Map<String, dynamic> map) {
    return Certificate(
      id: map['id'],
      personalDetailsId: map['personalDetailsId'],
      title: map['title'],
      date: map['date'] ?? '',
      description: map['description'] ?? '',
    );
  }

  Certificate copyWith({
    int? id,
    int? personalDetailsId,
    String? title,
    String? date,
    String? description,
  }) {
    return Certificate(
      id: id ?? this.id,
      personalDetailsId: personalDetailsId ?? this.personalDetailsId,
      title: title ?? this.title,
      date: date ?? this.date,
      description: description ?? this.description,
    );
  }
}
