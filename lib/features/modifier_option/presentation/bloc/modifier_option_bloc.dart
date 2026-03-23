import 'package:equatable/equatable.dart';
import 'package:flow_pos/features/modifier_option/domain/entities/modifier_option.dart';
import 'package:flow_pos/features/modifier_option/domain/usecases/get_all_modifier_options.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'modifier_option_event.dart';
part 'modifier_option_state.dart';

class ModifierOptionBloc
    extends Bloc<ModifierOptionEvent, ModifierOptionState> {
  final GetAllModifierOptions _getAllModifierOptions;

  ModifierOptionBloc({required GetAllModifierOptions getAllModifierOptions})
    : _getAllModifierOptions = getAllModifierOptions,
      super(ModifierOptionInitial()) {
    on<GetAllModifierOptionsEvent>(_onGetAllModifierOptions);
  }

  void _onGetAllModifierOptions(
    GetAllModifierOptionsEvent event,
    Emitter<ModifierOptionState> emit,
  ) async {
    emit(ModifierOptionLoading());

    final result = await _getAllModifierOptions(
      GetAllModifierOptionsParams(menuId: event.menuId),
    );

    result.fold(
      (l) => emit(ModifierOptionFailure(l.message)),
      (r) => emit(ModifierOptionLoaded(r)),
    );
  }
}
