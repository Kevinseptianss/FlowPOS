import 'package:flow_pos/core/error/server_exception.dart';
import 'package:flow_pos/features/auth/data/models/user_model.dart';
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

    try {
      final profile = await supabaseClient
          .from('profiles')
          .select()
          .eq('id', authUser.id)
          .maybeSingle();

      if (profile != null) {
        return UserModel.fromJson(profile).copyWith(
          email: authUser.email,
          name: profile['name']?.toString() ?? metadata['name']?.toString(),
          role: profile['role']?.toString() ?? metadata['role']?.toString(),
        );
      }
    } catch (_) {
      // Fallback to auth payload when profile is not yet available.
    }

    return UserModel.fromJson(authUser.toJson()).copyWith(
      email: authUser.email,
      name: metadata['name']?.toString(),
      role: metadata['role']?.toString(),
    );
  }

  @override
  Future<UserModel?> getCurrentUserData() async {
    try {
      if (currentUserSession != null) {
        final user = await supabaseClient
            .from('profiles')
            .select()
            .eq('id', currentUserSession!.user.id);

        return UserModel.fromJson(
          user.first,
        ).copyWith(email: currentUserSession!.user.email);
      }

      return null;
    } catch (e) {
      throw ServerException(e.toString());
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
