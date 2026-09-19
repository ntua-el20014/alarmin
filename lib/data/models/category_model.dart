class CategoryModel {
  const CategoryModel({
    required this.id,
    required this.name,
    required this.emoji,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final String emoji;
  final DateTime createdAt;
  final DateTime updatedAt;
}
