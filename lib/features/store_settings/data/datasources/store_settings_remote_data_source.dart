import 'package:flow_pos/features/store_settings/data/models/store_settings_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract interface class StoreSettingsRemoteDataSource {
  Stream<StoreSettingsModel> listenStoreSettings();
  Future<StoreSettingsModel> updateStoreSettings({
    String? id,
    required double taxPercentage,
    required double serviceChargePercentage,
  });
}

class StoreSettingsRemoteDataSourceImpl
    implements StoreSettingsRemoteDataSource {
  final SupabaseClient supabaseClient;

  StoreSettingsRemoteDataSourceImpl(this.supabaseClient);

  @override
  Stream<StoreSettingsModel> listenStoreSettings() {
    return supabaseClient
        .from('store_settings')
        .stream(primaryKey: ['id'])
        .order('updated_at', ascending: false)
        .map((rows) {
          if (rows.isEmpty) {
            return const StoreSettingsModel.zero();
          }

          return StoreSettingsModel.fromJson(rows.first);
        });
  }

  @override
  Future<StoreSettingsModel> updateStoreSettings({
    String? id,
    required double taxPercentage,
    required double serviceChargePercentage,
  }) async {
    final payload = {
      'tax_percentage': taxPercentage,
      'service_charge_percentage': serviceChargePercentage,
      'updated_at': DateTime.now().toIso8601String(),
    };

    if (id != null && id.trim().isNotEmpty) {
      final row = await supabaseClient
          .from('store_settings')
          .update(payload)
          .eq('id', id)
          .select()
          .single();

      return StoreSettingsModel.fromJson(row);
    }

    final row = await supabaseClient
        .from('store_settings')
        .insert(payload)
        .select()
        .single();

    return StoreSettingsModel.fromJson(row);
  }
}
