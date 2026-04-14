import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flow_pos/core/error/server_exception.dart';
import 'package:flow_pos/core/secrets/app_secrets.dart';
import 'package:flow_pos/features/staff/data/models/staff_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;

abstract interface class StaffRemoteDataSource {
  Future<List<StaffModel>> getStaff();
  Future<StaffModel> updateStaffRole(String staffId, String role);
  Future<StaffModel> createStaff(String name, String username, String password);
  Future<void> deleteStaff(String staffId);
  Future<bool> checkUsername(String username);
}

class NoStorage extends GotrueAsyncStorage {
  @override
  Future<void> removeItem({required String key}) async {}
  @override
  Future<void> setItem({required String key, required String value}) async {}
  @override
  Future<String?> getItem({required String key}) async => null;
}

class StaffRemoteDataSourceImpl implements StaffRemoteDataSource {
  final SupabaseClient supabaseClient;
  StaffRemoteDataSourceImpl(this.supabaseClient);

  @override
  Future<List<StaffModel>> getStaff() async {
    try {
      final response = await supabaseClient
          .from('profiles')
          .select()
          .order('name', ascending: true);

      return (response as List).map((data) => StaffModel.fromJson(data)).toList();
    } catch (e) {
      debugPrint('StaffRemoteDataSource.getStaff error: $e');
      throw ServerException(e.toString());
    }
  }

  @override
  Future<StaffModel> updateStaffRole(String staffId, String role) async {
    try {
      final response = await supabaseClient
          .from('profiles')
          .update({'role': role})
          .eq('id', staffId)
          .select()
          .single();
      
      return StaffModel.fromJson(response);
    } catch (e) {
      debugPrint('StaffRemoteDataSource.updateStaffRole error: $e');
      throw ServerException(e.toString());
    }
  }

  @override
  Future<StaffModel> createStaff(String name, String username, String password) async {
    try {
      // Use raw HTTP to ensure 100% isolation. This is version-proof and session-safe.
      final response = await http.post(
        Uri.parse('${AppSecrets.supabaseURL}/auth/v1/signup'),
        headers: {
          'apikey': AppSecrets.supabaseKey,
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'email': '${username.trim().toLowerCase()}@flowpos.local',
          'password': password,
          'data': {
            'name': name,
            'username': username.trim().toLowerCase(),
            'role': 'cashier',
          },
        }),
      );

      if (response.statusCode != 200) {
        final errorData = jsonDecode(response.body);
        debugPrint('Staff Signup HTTP Error: ${response.body}');
        throw ServerException(errorData['msg'] ?? errorData['message'] ?? 'Gagal membuat staff');
      }

      final signUpData = jsonDecode(response.body);
      final userId = signUpData['user']['id'];

      // Fetch the created profile with retry logic
      Map<String, dynamic>? profileResponse;
      for (int i = 0; i < 3; i++) {
        try {
          profileResponse = await supabaseClient
              .from('profiles')
              .select()
              .eq('id', userId)
              .maybeSingle();
          
          if (profileResponse != null) break;
        } catch (_) {}
        await Future.delayed(const Duration(milliseconds: 500));
      }

      if (profileResponse == null) {
        throw const ServerException('Akun berhasil dibuat tapi profil belum tersedia. Silakan refresh.');
      }

      return StaffModel.fromJson(profileResponse);
    } catch (e) {
      debugPrint('StaffRemoteDataSource.createStaff error: $e');
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> deleteStaff(String staffId) async {
    try {
      await supabaseClient.rpc('delete_staff_member', params: {
        'staff_id': staffId,
      });
    } catch (e) {
      debugPrint('StaffRemoteDataSource.deleteStaff error: $e');
      throw ServerException(e.toString());
    }
  }

  @override
  Future<bool> checkUsername(String username) async {
    try {
      final response = await supabaseClient
          .from('profiles')
          .select('username')
          .eq('username', username.trim().toLowerCase())
          .maybeSingle();

      return response == null;
    } catch (e) {
      debugPrint('StaffRemoteDataSource.checkUsername error: $e');
      return false; 
    }
  }
}
