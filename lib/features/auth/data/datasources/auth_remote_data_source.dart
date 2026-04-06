import 'package:flow_pos/core/error/server_exception.dart';
import 'package:flow_pos/features/auth/data/models/user_model.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract interface class AuthRemoteDataSource {
  Session? get currentUserSession;
  Future<UserModel> signUpWithEmailAndPassword(
    String name,
    String email,
    String password,
  );
  Future<UserModel> signInWithEmailAndPassword(String email, String password);
  Future<UserModel?> getCurrentUserData();
  Future<void> signOut();
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final SupabaseClient supabaseClient;
  AuthRemoteDataSourceImpl(this.supabaseClient);

  @override
  Session? get currentUserSession => supabaseClient.auth.currentSession;

  @override
  Future<UserModel> signUpWithEmailAndPassword(
    String name,
    String email,
    String password,
  ) async {
    try {
      final response = await supabaseClient.auth.signUp(
        password: password,
        email: email,
        data: {'name': name, 'role': 'cashier'},
      );

      if (response.user == null) {
        throw const ServerException('User is null');
      }

      return _resolveUserData(response.user!);
    } on AuthException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<UserModel> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      final response = await supabaseClient.auth.signInWithPassword(
        password: password,
        email: email,
      );

      if (response.user == null) {
        throw const ServerException('User is null');
      }

      return _resolveUserData(response.user!);
    } on AuthException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  Future<UserModel> _resolveUserData(User authUser) async {
    final metadata = authUser.userMetadata ?? const <String, dynamic>{};
    dynamic profile;

    try {
      debugPrint('Fetching profile for User ID: ${authUser.id}');
      profile = await supabaseClient
          .from('profiles')
          .select()
          .eq('id', authUser.id)
          .maybeSingle();

      if (profile != null) {
        debugPrint('Found DB Profile: $profile');
        return UserModel.fromJson(profile).copyWith(
          email: authUser.email,
          name: profile['name']?.toString() ?? metadata['name']?.toString(),
          role: profile['role']?.toString() ?? metadata['role']?.toString(),
        );
      } else {
        debugPrint('No profile row found for ID: ${authUser.id}');
      }
    } on PostgrestException catch (e) {
      debugPrint('Database Error fetching profile: ${e.message}');
      if (e.code != 'PGRST116') {
        throw ServerException('Database Error: ${e.message}');
      }
    } catch (e) {
      debugPrint('System Error fetching profile: $e');
      throw ServerException('System Error: $e');
    }

    final name = (profile != null ? profile['name']?.toString() : null) ??
        metadata['name']?.toString() ??
        'User';

    final role = (profile != null ? profile['role']?.toString() : null) ??
        metadata['role']?.toString() ??
        'cashier';

    return UserModel.fromJson(authUser.toJson()).copyWith(
      email: authUser.email,
      name: name,
      role: role,
    );
  }

  @override
  Future<UserModel?> getCurrentUserData() async {
    try {
      if (currentUserSession != null) {
        final profile = await supabaseClient
            .from('profiles')
            .select()
            .eq('id', currentUserSession!.user.id)
            .maybeSingle();

        if (profile != null) {
          return UserModel.fromJson(profile).copyWith(
            email: currentUserSession!.user.email,
          );
        }

        // Fallback: If profile row is missing, use session data temporarily
        return UserModel.fromJson(currentUserSession!.user.toJson()).copyWith(
          email: currentUserSession!.user.email,
          name: currentUserSession!.user.userMetadata?['name']?.toString(),
          role: currentUserSession!.user.userMetadata?['role']?.toString(),
        );
      }

      return null;
    } catch (e) {
      throw ServerException('Failed to fetch user data: $e');
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await supabaseClient.auth.signOut();
    } on AuthException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
}
