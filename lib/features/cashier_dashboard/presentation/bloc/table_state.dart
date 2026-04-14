part of 'table_bloc.dart';

final class TableState extends Equatable {
  final int selectedTableNumber;
  final Set<int> occupiedTableNumbers;
  final Map<int, String> occupiedTableNames;

  const TableState({
    required this.selectedTableNumber,
    this.occupiedTableNumbers = const {},
    this.occupiedTableNames = const {},
  });

  TableState copyWith({
    int? selectedTableNumber,
    Set<int>? occupiedTableNumbers,
    Map<int, String>? occupiedTableNames,
  }) {
    return TableState(
      selectedTableNumber: selectedTableNumber ?? this.selectedTableNumber,
      occupiedTableNumbers: occupiedTableNumbers ?? this.occupiedTableNumbers,
      occupiedTableNames: occupiedTableNames ?? this.occupiedTableNames,
    );
  }

  @override
  List<Object> get props => [selectedTableNumber, occupiedTableNumbers, occupiedTableNames];
}
