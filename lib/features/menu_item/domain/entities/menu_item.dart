import 'package:equatable/equatable.dart';
import 'package:flow_pos/features/category/domain/entities/category.dart';

class MenuItem extends Equatable {
  final String id;
  final String name;
  final int price;
  final Category category;
  final bool enabled;

  const MenuItem({
    required this.id,
    required this.name,
    required this.price,
    required this.category,
    required this.enabled,
  });

  @override
  List<Object?> get props => [id, name, price, category, enabled];
}
