class CvSummary {
  final String id;
  final String name;
  final String createdAt;

  CvSummary({
    required this.id,
    required this.name,
    required this.createdAt,
  });

  factory CvSummary.fromJson(Map<String, dynamic> json) {
    return CvSummary(
      id: json['id'] as String,
      name: json['name'] as String,
      createdAt: json['created_at'] as String,
    );
  }
}
