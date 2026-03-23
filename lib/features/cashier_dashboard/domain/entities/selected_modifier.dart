import 'package:equatable/equatable.dart';

class SelectedModifier extends Equatable {
  final String id;
  final String name;

  const SelectedModifier({required this.id, required this.name});

  @override
  List<Object?> get props => [id, name];
}
