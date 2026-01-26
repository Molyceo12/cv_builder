class Project {
  final int? id;
  final int personalDetailsId;
  final String title;
  final String description;
  final String githubLink;
  final String liveLink;
  final String playStoreLink;
  final String appStoreLink;
  final String technologies;

  Project({
    this.id,
    required this.personalDetailsId,
    required this.title,
    required this.description,
    this.githubLink = '',
    this.liveLink = '',
    this.playStoreLink = '',
    this.appStoreLink = '',
    this.technologies = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'personalDetailsId': personalDetailsId,
      'title': title,
      'description': description,
      'githubLink': githubLink,
      'liveLink': liveLink,
      'playStoreLink': playStoreLink,
      'appStoreLink': appStoreLink,
      'technologies': technologies,
    };
  }

  factory Project.fromMap(Map<String, dynamic> map) {
    return Project(
      id: map['id'],
      personalDetailsId: map['personalDetailsId'],
      title: map['title'],
      description: map['description'],
      githubLink: map['githubLink'] ?? '',
      liveLink: map['liveLink'] ?? '',
      playStoreLink: map['playStoreLink'] ?? '',
      appStoreLink: map['appStoreLink'] ?? '',
      technologies: map['technologies'] ?? '',
    );
  }

  Project copyWith({
    int? id,
    int? personalDetailsId,
    String? title,
    String? description,
    String? githubLink,
    String? liveLink,
    String? playStoreLink,
    String? appStoreLink,
    String? technologies,
  }) {
    return Project(
      id: id ?? this.id,
      personalDetailsId: personalDetailsId ?? this.personalDetailsId,
      title: title ?? this.title,
      description: description ?? this.description,
      githubLink: githubLink ?? this.githubLink,
      liveLink: liveLink ?? this.liveLink,
      playStoreLink: playStoreLink ?? this.playStoreLink,
      appStoreLink: appStoreLink ?? this.appStoreLink,
      technologies: technologies ?? this.technologies,
    );
  }
}
