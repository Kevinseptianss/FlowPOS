import 'package:equatable/equatable.dart';
import 'package:flow_pos/core/usecase/use_case.dart';
import 'package:flow_pos/features/store_settings/domain/entities/store_settings.dart';
import 'package:flow_pos/features/store_settings/domain/usecases/get_store_settings.dart';
import 'package:flow_pos/features/store_settings/domain/usecases/update_store_settings.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'store_settings_event.dart';
part 'store_settings_state.dart';

class StoreSettingsBloc extends Bloc<StoreSettingsEvent, StoreSettingsState> {
  final GetStoreSettings _getStoreSettings;
  final UpdateStoreSettings _updateStoreSettings;

  StoreSettingsBloc({
    required GetStoreSettings getStoreSettings,
    required UpdateStoreSettings updateStoreSettings,
  }) : _getStoreSettings = getStoreSettings,
       _updateStoreSettings = updateStoreSettings,
       super(StoreSettingsInitial()) {
    on<GetStoreSettingsEvent>(_onGetStoreSettings);
    on<UpdateStoreSettingsEvent>(_onUpdateStoreSettings);
  }

  void _onGetStoreSettings(
    GetStoreSettingsEvent event,
    Emitter<StoreSettingsState> emit,
  ) async {
    emit(StoreSettingsLoading());

    final result = await _getStoreSettings(NoParams());

    result.fold(
      (failure) => emit(StoreSettingsFailure(failure.message)),
      (storeSettings) => emit(StoreSettingsLoaded(storeSettings)),
    );
  }

  void _onUpdateStoreSettings(
    UpdateStoreSettingsEvent event,
    Emitter<StoreSettingsState> emit,
  ) async {
    emit(StoreSettingsUpdating());

    final result = await _updateStoreSettings(
      UpdateStoreSettingsParams(
        id: event.id,
        taxPercentage: event.taxPercentage,
        serviceChargePercentage: event.serviceChargePercentage,
        storeName: event.storeName,
        storeAddress: event.storeAddress,
      ),
    );

    result.fold(
      (failure) => emit(StoreSettingsFailure(failure.message)),
      (storeSettings) => emit(StoreSettingsUpdated(storeSettings)),
    );
  }
}
