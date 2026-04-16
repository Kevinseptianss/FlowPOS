import 'package:flutter/foundation.dart';
import 'package:equatable/equatable.dart';
import 'package:flow_pos/features/staff/domain/entities/staff_profile.dart';
import 'package:flow_pos/features/staff/domain/repositories/staff_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rxdart/rxdart.dart';

part 'staff_event.dart';
part 'staff_state.dart';

class StaffBloc extends Bloc<StaffEvent, StaffState> {
  final StaffRepository staffRepository;

  StaffBloc(this.staffRepository) : super(StaffInitial()) {
    on<GetStaffEvent>(_onGetStaff);
    on<UpdateStaffRoleEvent>(_onUpdateStaffRole);
    on<CreateStaffEvent>(_onCreateStaff);
    on<DeleteStaffEvent>(_onDeleteStaff);
    on<CheckUsernameEvent>(
      _onCheckUsername,
      transformer: (events, mapper) => events
          .debounceTime(const Duration(milliseconds: 500))
          .flatMap(mapper),
    );
    on<UpdateStaffSalaryEvent>(_onUpdateStaffSalary);
  }

  Future<void> _onGetStaff(
    GetStaffEvent event,
    Emitter<StaffState> emit,
  ) async {
    emit(StaffLoading());
    final res = await staffRepository.getStaff();
    res.fold((failure) {
      debugPrint('StaffBloc._onGetStaff failure: ${failure.message}');
      emit(StaffFailure(failure.message));
    }, (staff) => emit(StaffLoaded(staff)));
  }

  Future<void> _onUpdateStaffRole(
    UpdateStaffRoleEvent event,
    Emitter<StaffState> emit,
  ) async {
    final res = await staffRepository.updateStaffRole(
      event.staffId,
      event.role,
    );
    res.fold(
      (failure) {
        debugPrint('StaffBloc._onUpdateStaffRole failure: ${failure.message}');
        emit(StaffFailure(failure.message));
      },
      (staff) {
        emit(StaffRoleUpdated(staff));
        add(GetStaffEvent()); // Refresh list
      },
    );
  }

  Future<void> _onCreateStaff(
    CreateStaffEvent event,
    Emitter<StaffState> emit,
  ) async {
    emit(StaffLoading());
    final res = await staffRepository.createStaff(
      event.name,
      event.username,
      event.password,
    );
    res.fold(
      (failure) {
        debugPrint('StaffBloc._onCreateStaff failure: ${failure.message}');
        emit(StaffFailure(failure.message));
      },
      (staff) {
        emit(StaffCreated(staff));
        add(GetStaffEvent()); // Refresh list
      },
    );
  }

  Future<void> _onDeleteStaff(
    DeleteStaffEvent event,
    Emitter<StaffState> emit,
  ) async {
    emit(StaffLoading());
    final res = await staffRepository.deleteStaff(event.staffId);
    res.fold(
      (failure) {
        debugPrint('StaffBloc._onDeleteStaff failure: ${failure.message}');
        emit(StaffFailure(failure.message));
      },
      (_) {
        emit(StaffDeleted());
        add(GetStaffEvent()); // Refresh list
      },
    );
  }

  Future<void> _onCheckUsername(
    CheckUsernameEvent event,
    Emitter<StaffState> emit,
  ) async {
    if (event.username.isEmpty) {
      emit(StaffInitial());
      return;
    }
    final res = await staffRepository.checkUsername(event.username);
    res.fold((failure) {
      debugPrint('StaffBloc._onCheckUsername failure: ${failure.message}');
      emit(StaffFailure(failure.message));
    }, (exists) => emit(UsernameChecked(exists)));
  }

  Future<void> _onUpdateStaffSalary(
    UpdateStaffSalaryEvent event,
    Emitter<StaffState> emit,
  ) async {
    final res = await staffRepository.updateStaffSalary(
      staffId: event.staffId,
      salary: event.salary,
      salaryType: event.salaryType,
      hourlyRate: event.hourlyRate,
      minuteRate: event.minuteRate,
    );
    res.fold(
      (failure) {
        debugPrint('StaffBloc._onUpdateStaffSalary failure: ${failure.message}');
        emit(StaffFailure(failure.message));
      },
      (staff) {
        emit(StaffSalaryUpdated(staff));
        add(GetStaffEvent()); // Refresh list
      },
    );
  }
}
