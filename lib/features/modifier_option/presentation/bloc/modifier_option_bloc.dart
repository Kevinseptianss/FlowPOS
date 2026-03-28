import 'package:equatable/equatable.dart';
import 'package:flow_pos/core/usecase/use_case.dart';
import 'package:flow_pos/features/modifier_option/domain/entities/create_modifier_option_input.dart';
import 'package:flow_pos/features/modifier_option/domain/entities/modifier_option.dart';
import 'package:flow_pos/features/modifier_option/domain/usecases/create_modifier_group_with_options.dart';
import 'package:flow_pos/features/modifier_option/domain/usecases/get_all_modifier_group_options.dart';
import 'package:flow_pos/features/modifier_option/domain/usecases/get_all_modifier_options.dart';
import 'package:flow_pos/features/modifier_option/domain/usecases/get_selected_modifier_group_ids.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'modifier_option_event.dart';
part 'modifier_option_state.dart';

class ModifierOptionBloc
    extends Bloc<ModifierOptionEvent, ModifierOptionState> {
  final GetAllModifierOptions _getAllModifierOptions;
  final CreateModifierGroupWithOptions _createModifierGroupWithOptions;
  final GetAllModifierGroupOptions _getAllModifierGroupOptions;
  final GetSelectedModifierGroupIds _getSelectedModifierGroupIds;

  ModifierOptionBloc({
    required GetAllModifierOptions getAllModifierOptions,
    required CreateModifierGroupWithOptions createModifierGroupWithOptions,
    required GetAllModifierGroupOptions getAllModifierGroupOptions,
    required GetSelectedModifierGroupIds getSelectedModifierGroupIds,
  }) : _getAllModifierOptions = getAllModifierOptions,
       _createModifierGroupWithOptions = createModifierGroupWithOptions,
       _getAllModifierGroupOptions = getAllModifierGroupOptions,
       _getSelectedModifierGroupIds = getSelectedModifierGroupIds,
       super(ModifierOptionInitial()) {
    on<GetAllModifierOptionsEvent>(_onGetAllModifierOptions);
    on<CreateModifierGroupEvent>(_onCreateModifierGroup);
    on<GetModifierGroupSelectionEvent>(_onGetModifierGroupSelection);
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

  void _onGetModifierGroupSelection(
    GetModifierGroupSelectionEvent event,
    Emitter<ModifierOptionState> emit,
  ) async {
    emit(ModifierOptionLoading());

    final allOptionsResult = await _getAllModifierGroupOptions(NoParams());
    final selectedGroupIdsResult = await _getSelectedModifierGroupIds(
      GetSelectedModifierGroupIdsParams(menuId: event.menuId),
    );

    allOptionsResult.fold(
      (failure) => emit(ModifierOptionFailure(failure.message)),
      (allOptions) {
        selectedGroupIdsResult.fold(
          (failure) => emit(ModifierOptionFailure(failure.message)),
          (selectedGroupIds) => emit(
            ModifierGroupSelectionLoaded(
              menuId: event.menuId,
              modifierOptions: allOptions,
              selectedModifierGroupIds: selectedGroupIds,
            ),
          ),
        );
      },
    );
  }

  void _onCreateModifierGroup(
    CreateModifierGroupEvent event,
    Emitter<ModifierOptionState> emit,
  ) async {
    emit(ModifierOptionLoading());

    final result = await _createModifierGroupWithOptions(
      CreateModifierGroupWithOptionsParams(
        groupName: event.groupName,
        options: event.options,
      ),
    );

    result.fold(
      (failure) => emit(ModifierOptionFailure(failure.message)),
      (_) => emit(ModifierGroupCreatedSuccess()),
    );
  }
}
