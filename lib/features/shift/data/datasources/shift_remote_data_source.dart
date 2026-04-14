import 'package:flow_pos/core/error/server_exception.dart';
import 'package:flow_pos/features/shift/data/models/shift_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract interface class ShiftRemoteDataSource {
  Future<List<ShiftModel>> getShiftHistory();
  Future<ShiftModel> openShift({
    required String cashierId,
    required double openingBalance,
  });
  Future<ShiftModel> closeShift({
    required String shiftId,
    required double closingBalance,
  });
  Future<ShiftModel?> getActiveShift(String cashierId);
}

class ShiftRemoteDataSourceImpl implements ShiftRemoteDataSource {
  final SupabaseClient supabaseClient;
  ShiftRemoteDataSourceImpl(this.supabaseClient);

  @override
  Future<ShiftModel?> getActiveShift(String cashierId) async {
    try {
      final response = await supabaseClient
          .from('shifts')
          .select('*, profiles(name)')
          .eq('cashier_id', cashierId)
          .filter('closed_at', 'is', null)
          .maybeSingle();

      if (response == null) return null;
      return ShiftModel.fromJson(response);
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<List<ShiftModel>> getShiftHistory() async {
    try {
      final response = await supabaseClient
          .from('shifts')
          .select('*, profiles(name)')
          .order('opened_at', ascending: false);
      
      return (response as List)
          .map((data) => ShiftModel.fromJson(data))
          .toList();
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<ShiftModel> openShift({
    required String cashierId,
    required double openingBalance,
  }) async {
    try {
      final response = await supabaseClient
          .from('shifts')
          .insert({
            'cashier_id': cashierId,
            'opening_balance': openingBalance.toInt(),
          })
          .select('*, profiles(name)')
          .single();
      
      return ShiftModel.fromJson(response);
    } on PostgrestException catch (e) {
      if (e.message.contains('unique_open_shift_per_cashier')) {
        throw const ServerException('Anda masih memiliki shift yang belum ditutup. Tutup shift tersebut terlebih dahulu sebelum membuka shift baru.');
      }
      throw ServerException(e.message);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<ShiftModel> closeShift({
    required String shiftId,
    required double closingBalance,
  }) async {
    try {
      final response = await supabaseClient
          .from('shifts')
        .update({
          'closed_at': DateTime.now().toUtc().toIso8601String(),
          'closing_balance': closingBalance.toInt(),
        })
          .eq('id', shiftId)
          .select('*, profiles(name)')
          .single();
      
      return ShiftModel.fromJson(response);
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
}
