import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'table_event.dart';
part 'table_state.dart';

class TableBloc extends Bloc<TableEvent, TableState> {
  TableBloc() : super(const TableState(selectedTableNumber: 1)) {
    on<SelectTableEvent>(_onSelectTable);
  }

  void _onSelectTable(SelectTableEvent event, Emitter<TableState> emit) {
    emit(TableState(selectedTableNumber: event.tableNumber));
  }
}
