import '../../domain/entities/category.dart';

class CategoryModel extends Category {
  const CategoryModel({
    required super.id,
    required super.name,
    super.icon = 'restaurant',
    super.colorValue = 0xFF1E5FDE,
  });

  factory CategoryModel.fromEntity(Category category) {
    return CategoryModel(
      id: category.id,
      name: category.name,
      icon: category.icon,
      colorValue: category.colorValue,
    );
  }

  factory CategoryModel.fromMap(Map<String, dynamic> map) {
    return CategoryModel(
      id: map['id'] as String,
      name: map['name'] as String,
      icon: (map['icon'] as String?) ?? 'restaurant',
      colorValue: (map['color_value'] as int?) ?? 0xFF1E5FDE,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'icon': icon,
      'color_value': colorValue,
    };
  }
}
