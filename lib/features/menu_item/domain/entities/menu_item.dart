import 'package:equatable/equatable.dart';

class MenuItem extends Equatable {
  final String id;
  final String name;
  final int price;
  final String categoryId;
  final bool enabled;

  const MenuItem({
    required this.id,
    required this.name,
    required this.price,
    required this.categoryId,
    required this.enabled,
  });

  @override
  List<Object?> get props => [id, name, price, categoryId, enabled];
}
