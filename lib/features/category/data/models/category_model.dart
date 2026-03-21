import 'package:flow_pos/features/category/domain/entities/category.dart';

class CategoryModel extends Category {
  const CategoryModel({required super.id, required super.name});

  factory CategoryModel.fromJson(Map<String, dynamic> map) {
    return CategoryModel(id: map['id'] ?? '', name: map['name'] ?? '');
  }
}
