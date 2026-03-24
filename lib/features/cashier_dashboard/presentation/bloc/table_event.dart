part of 'table_bloc.dart';

sealed class TableEvent extends Equatable {
  const TableEvent();

  @override
  List<Object> get props => [];
}

final class SelectTableEvent extends TableEvent {
  final int tableNumber;

  const SelectTableEvent(this.tableNumber);

  @override
  List<Object> get props => [tableNumber];
}
