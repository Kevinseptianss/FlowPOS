import 'package:equatable/equatable.dart';
import 'package:flow_pos/core/services/cashier_shift_local_service.dart';
import 'package:flow_pos/features/shift/domain/entities/shift_entity.dart';
import 'package:flow_pos/features/shift/domain/repositories/shift_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'shift_event.dart';
part 'shift_state.dart';

class ShiftBloc extends Bloc<ShiftEvent, ShiftState> {
  final ShiftRepository shiftRepository;
  final CashierShiftLocalService shiftLocalService;

  ShiftBloc({
    required this.shiftRepository,
    required this.shiftLocalService,
  }) : super(ShiftInitial()) {
    on<GetShiftHistoryEvent>(_onGetShiftHistory);
    on<OpenShiftEvent>(_onOpenShift);
    on<SkipShiftEvent>(_onSkipShift);
    on<CloseShiftEvent>(_onCloseShift);
    on<GetActiveShiftEvent>(_onGetActiveShift);
  }

  Future<void> _onGetActiveShift(
    GetActiveShiftEvent event,
    Emitter<ShiftState> emit,
  ) async {
    emit(ShiftLoading());
    final res = await shiftRepository.getActiveShift(event.cashierId);
    res.fold(
      (failure) {
        debugPrint('--- [SHIFT ERROR] ---');
        debugPrint(failure.message);
        debugPrint('----------------------');
        emit(ShiftFailure(failure.message));
      },
      (shift) {
        if (shift != null) {
          // Sync with local Hive
          shiftLocalService.openShift(
            shiftId: shift.id,
            cashierId: event.cashierId,
            cashierName: shift.cashierName ?? 'Kasir',
            openingBalance: shift.openingBalance.toDouble(),
          );
          emit(ShiftOpened(shift));
        } else {
          emit(ShiftNone());
        }
      },
    );
  }

  Future<void> _onCloseShift(
    CloseShiftEvent event,
    Emitter<ShiftState> emit,
  ) async {
    final currentState = state;
    if (currentState is! ShiftOpened) {
      emit(const ShiftFailure('Tidak ada shift aktif yang ditemukan.'));
      return;
    }

    final activeShift = currentState.shift;
    emit(ShiftLoading());
    
    try {
      final res = await shiftRepository.closeShift(
        shiftId: activeShift.id,
        closingBalance: event.closingBalance,
      );

      res.fold(
        (failure) => emit(ShiftFailure(failure.message)),
        (shift) {
          // Clear local Hive
          shiftLocalService.clearActiveShift(event.cashierId);
          emit(ShiftClosed(shift));
        },
      );
    } catch (e) {
      emit(ShiftFailure(e.toString()));
    }
  }

  Future<void> _onGetShiftHistory(
    GetShiftHistoryEvent event,
    Emitter<ShiftState> emit,
  ) async {
    emit(ShiftLoading());
    final res = await shiftRepository.getShiftHistory();
    res.fold(
      (failure) {
        debugPrint('--- [SHIFT ERROR] ---');
        debugPrint(failure.message);
        debugPrint('----------------------');
        emit(ShiftFailure(failure.message));
      },
      (shifts) => emit(ShiftLoaded(shifts)),
    );
  }

  Future<void> _onOpenShift(
    OpenShiftEvent event,
    Emitter<ShiftState> emit,
  ) async {
    emit(ShiftLoading());
    try {
      final res = await shiftRepository.openShift(
        cashierId: event.cashierId,
        openingBalance: event.openingBalance,
      );

      res.fold(
        (failure) => emit(ShiftFailure(failure.message)),
        (shift) {
          // Sync with local Hive
          shiftLocalService.setShiftSkipped(event.cashierId, false);
          shiftLocalService.openShift(
            shiftId: shift.id,
            cashierId: event.cashierId,
            cashierName: shift.cashierName ?? 'Kasir',
            openingBalance: shift.openingBalance.toDouble(),
          );
          emit(ShiftOpened(shift));
        },
      );
    } catch (e) {
      emit(ShiftFailure(e.toString()));
    }
  }

  Future<void> _onSkipShift(
    SkipShiftEvent event,
    Emitter<ShiftState> emit,
  ) async {
    try {
      await shiftLocalService.setShiftSkipped(event.cashierId, true);
      emit(ShiftSkipped());
    } catch (e) {
      emit(ShiftFailure(e.toString()));
    }
  }
}
