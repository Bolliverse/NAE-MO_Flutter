class Category {
  final String id;
  final String name;
  final int color; // ARGB int — UI 레이어에서 Color(category.color)로 변환
  final int sortOrder;

  const Category({
    required this.id,
    required this.name,
    required this.color,
    required this.sortOrder,
  });
}
