import 'package:equatable/equatable.dart';

class SelectedModifier extends Equatable {
  final String id;
  final String name;
  final String optionName;

  const SelectedModifier({
    required this.id, 
    required this.name,
    this.optionName = '',
  });

  @override
  List<Object?> get props => [id, name, optionName];
}
