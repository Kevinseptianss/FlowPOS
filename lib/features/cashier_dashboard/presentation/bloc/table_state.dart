part of 'table_bloc.dart';

final class TableState extends Equatable {
  final int selectedTableNumber;

  const TableState({required this.selectedTableNumber});

  @override
  List<Object> get props => [selectedTableNumber];
}
