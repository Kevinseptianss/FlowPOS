import 'package:flow_pos/core/common/bloc/user_bloc.dart';
import 'package:flow_pos/core/secrets/app_secrets.dart';
import 'package:flow_pos/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:flow_pos/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:flow_pos/features/auth/domain/repositories/auth_repository.dart';
import 'package:flow_pos/features/auth/domain/usecases/current_user.dart';
import 'package:flow_pos/features/auth/domain/usecases/sign_in.dart';
import 'package:flow_pos/features/auth/domain/usecases/sign_up.dart';
import 'package:flow_pos/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final serviceLocator = GetIt.instance;

Future<void> initDependencies() async {
  _initUser();
  _initAuth();

  final supabase = await Supabase.initialize(
    url: AppSecrets.supabaseURL,
    anonKey: AppSecrets.supabaseKey,
  );

  serviceLocator.registerLazySingleton(() => supabase.client);
}

void _initUser() {
  serviceLocator.registerLazySingleton(() => UserBloc());
}

void _initAuth() {
  serviceLocator
    // Datasources
    ..registerFactory<AuthRemoteDataSource>(
      () => AuthRemoteDataSourceImpl(serviceLocator()),
    )
    // Repositories
    ..registerFactory<AuthRepository>(
      () => AuthRepositoryImpl(serviceLocator()),
    )
    // Usecases
    ..registerFactory(() => SignUp(serviceLocator()))
    ..registerFactory(() => SignIn(serviceLocator()))
    ..registerFactory(() => CurrentUser(serviceLocator()))
    // Bloc
    ..registerLazySingleton(
      () => AuthBloc(
        signUp: serviceLocator(),
        signIn: serviceLocator(),
        currentUser: serviceLocator(),
        userBloc: serviceLocator(),
      ),
    );
}
