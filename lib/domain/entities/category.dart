class Category {
  final String id;
  final String name;
  final String icon;
  final int colorValue;

  const Category({
    required this.id,
    required this.name,
    this.icon = 'restaurant',
    this.colorValue = 0xFF1E5FDE,
  });

  Category copyWith({
    String? id,
    String? name,
    String? icon,
    int? colorValue,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      colorValue: colorValue ?? this.colorValue,
    );
  }
}
