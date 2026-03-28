import 'package:flow_pos/features/store_settings/data/models/store_settings_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract interface class StoreSettingsRemoteDataSource {
  Stream<StoreSettingsModel> listenStoreSettings();
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
}
