import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'table_event.dart';
part 'table_state.dart';

class TableBloc extends Bloc<TableEvent, TableState> {
  TableBloc() : super(const TableState(selectedTableNumber: 0)) {
    on<SelectTableEvent>(_onSelectTable);
    on<UpdateOccupiedTablesEvent>(_onUpdateOccupiedTables);
  }

  void _onSelectTable(SelectTableEvent event, Emitter<TableState> emit) {
    emit(state.copyWith(selectedTableNumber: event.tableNumber));
  }

  void _onUpdateOccupiedTables(UpdateOccupiedTablesEvent event, Emitter<TableState> emit) {
    emit(state.copyWith(
      occupiedTableNumbers: event.occupiedTableNumbers,
      occupiedTableNames: event.occupiedTableNames,
    ));
  }
}
