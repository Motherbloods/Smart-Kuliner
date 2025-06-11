class EducationContent {
  final String id;
  final String title;
  final String description;
  final String imageUrl;
  final String category;
  final String type;
  final int readTime;
  final DateTime createdAt;
  final String status;
  final int views;
  final int likes;

  EducationContent({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.category,
    required this.type,
    required this.readTime,
    required this.createdAt,
    required this.status,
    required this.views,
    required this.likes,
  });
}
