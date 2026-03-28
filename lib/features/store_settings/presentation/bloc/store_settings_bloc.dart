import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flow_pos/features/store_settings/domain/entities/store_settings.dart';
import 'package:flow_pos/features/store_settings/domain/usecases/listen_store_settings.dart';
import 'package:flow_pos/features/store_settings/domain/usecases/update_store_settings.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'store_settings_event.dart';
part 'store_settings_state.dart';

class StoreSettingsBloc extends Bloc<StoreSettingsEvent, StoreSettingsState> {
  final ListenStoreSettings _listenStoreSettings;
  final UpdateStoreSettings _updateStoreSettings;

  StreamSubscription? _storeSettingsSubscription;

  StoreSettingsBloc({
    required ListenStoreSettings listenStoreSettings,
    required UpdateStoreSettings updateStoreSettings,
  }) : _listenStoreSettings = listenStoreSettings,
       _updateStoreSettings = updateStoreSettings,
       super(StoreSettingsInitial()) {
    on<StartStoreSettingsRealtimeEvent>(_onStartStoreSettingsRealtime);
    on<StopStoreSettingsRealtimeEvent>(_onStopStoreSettingsRealtime);
    on<UpdateStoreSettingsEvent>(_onUpdateStoreSettings);
    on<StoreSettingsRealtimeUpdatedEvent>(_onStoreSettingsRealtimeUpdated);
    on<StoreSettingsRealtimeFailureEvent>(_onStoreSettingsRealtimeFailure);
  }

  void _onStartStoreSettingsRealtime(
    StartStoreSettingsRealtimeEvent event,
    Emitter<StoreSettingsState> emit,
  ) async {
    await _storeSettingsSubscription?.cancel();
    emit(StoreSettingsLoading());

    _storeSettingsSubscription = _listenStoreSettings().listen((result) {
      result.fold(
        (failure) => add(StoreSettingsRealtimeFailureEvent(failure.message)),
        (storeSettings) =>
            add(StoreSettingsRealtimeUpdatedEvent(storeSettings)),
      );
    });
  }

  void _onStopStoreSettingsRealtime(
    StopStoreSettingsRealtimeEvent event,
    Emitter<StoreSettingsState> emit,
  ) async {
    await _storeSettingsSubscription?.cancel();
    _storeSettingsSubscription = null;
  }

  void _onStoreSettingsRealtimeUpdated(
    StoreSettingsRealtimeUpdatedEvent event,
    Emitter<StoreSettingsState> emit,
  ) {
    emit(StoreSettingsLoaded(event.storeSettings));
  }

  void _onStoreSettingsRealtimeFailure(
    StoreSettingsRealtimeFailureEvent event,
    Emitter<StoreSettingsState> emit,
  ) {
    emit(StoreSettingsFailure(event.message));
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
      ),
    );

    result.fold(
      (failure) => emit(StoreSettingsFailure(failure.message)),
      (storeSettings) => emit(StoreSettingsUpdated(storeSettings)),
    );
  }

  @override
  Future<void> close() async {
    await _storeSettingsSubscription?.cancel();
    return super.close();
  }
}
