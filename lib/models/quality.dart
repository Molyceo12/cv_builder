class Quality {
  final int? id;
  final int personalDetailsId;
  final String quality;

  Quality({
    this.id,
    required this.personalDetailsId,
    required this.quality,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'personalDetailsId': personalDetailsId,
      'quality': quality,
    };
  }

  factory Quality.fromMap(Map<String, dynamic> map) {
    return Quality(
      id: map['id'],
      personalDetailsId: map['personalDetailsId'],
      quality: map['quality'] ?? '',
    );
  }

  Quality copyWith({
    int? id,
    int? personalDetailsId,
    String? quality,
  }) {
    return Quality(
      id: id ?? this.id,
      personalDetailsId: personalDetailsId ?? this.personalDetailsId,
      quality: quality ?? this.quality,
    );
  }
}
