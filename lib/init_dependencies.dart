import 'package:flow_pos/core/common/bloc/user_bloc.dart';
import 'package:flow_pos/core/secrets/app_secrets.dart';
import 'package:flow_pos/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:flow_pos/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:flow_pos/features/auth/domain/repositories/auth_repository.dart';
import 'package:flow_pos/features/auth/domain/usecases/current_user.dart';
import 'package:flow_pos/features/auth/domain/usecases/logout.dart';
import 'package:flow_pos/features/auth/domain/usecases/sign_in.dart';
import 'package:flow_pos/features/auth/domain/usecases/sign_up.dart';
import 'package:flow_pos/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:flow_pos/features/category/data/datasources/category_remote_data_source.dart';
import 'package:flow_pos/features/category/data/repositories/category_repository_impl.dart';
import 'package:flow_pos/features/category/domain/repositories/category_repository.dart';
import 'package:flow_pos/features/category/domain/usecases/create_category.dart';
import 'package:flow_pos/features/category/domain/usecases/get_all_categories.dart';
import 'package:flow_pos/features/category/domain/usecases/listen_all_categories.dart';
import 'package:flow_pos/features/category/presentation/bloc/category_bloc.dart';
import 'package:flow_pos/features/menu_item/data/datasources/menu_item_remote_data_source.dart';
import 'package:flow_pos/features/menu_item/data/repositories/menu_item_repository_impl.dart';
import 'package:flow_pos/features/menu_item/domain/repositories/menu_item_repository.dart';
import 'package:flow_pos/features/menu_item/domain/usecases/create_menu_item.dart';
import 'package:flow_pos/features/menu_item/domain/usecases/get_all_menu_items.dart';
import 'package:flow_pos/features/menu_item/domain/usecases/get_enabled_menu_items.dart';
import 'package:flow_pos/features/menu_item/domain/usecases/listen_all_menu_items.dart';
import 'package:flow_pos/features/menu_item/domain/usecases/listen_enabled_menu_items.dart';
import 'package:flow_pos/features/menu_item/domain/usecases/update_menu_item_availability.dart';
import 'package:flow_pos/features/menu_item/presentation/bloc/menu_item_bloc.dart';
import 'package:flow_pos/features/cashier_dashboard/presentation/bloc/cart_bloc.dart';
import 'package:flow_pos/features/cashier_dashboard/presentation/bloc/table_bloc.dart';
import 'package:flow_pos/features/modifier_option/data/datasources/modifier_option_remote_data_source.dart';
import 'package:flow_pos/features/modifier_option/data/repositories/modifier_option_repository_impl.dart';
import 'package:flow_pos/features/modifier_option/domain/repositories/modifier_option_repository.dart';
import 'package:flow_pos/features/modifier_option/domain/usecases/get_all_modifier_group_options.dart';
import 'package:flow_pos/features/modifier_option/domain/usecases/get_all_modifier_options.dart';
import 'package:flow_pos/features/modifier_option/domain/usecases/get_selected_modifier_group_ids.dart';
import 'package:flow_pos/features/modifier_option/domain/usecases/update_menu_modifier_groups.dart';
import 'package:flow_pos/features/modifier_option/domain/usecases/create_modifier_group_with_options.dart';
import 'package:flow_pos/features/modifier_option/presentation/bloc/modifier_option_bloc.dart';
import 'package:flow_pos/features/order/data/datasources/order_remote_data_source.dart';
import 'package:flow_pos/features/order/data/repositories/order_repository_impl.dart';
import 'package:flow_pos/features/order/domain/repositories/order_repository.dart';
import 'package:flow_pos/features/order/domain/usecases/create_order.dart';
import 'package:flow_pos/features/order/domain/usecases/get_all_orders.dart';
import 'package:flow_pos/features/order/domain/usecases/get_monthly_revenue.dart';
import 'package:flow_pos/features/order/domain/usecases/listen_all_orders.dart';
import 'package:flow_pos/features/order/domain/usecases/listen_monthly_revenue.dart';
import 'package:flow_pos/features/order/presentation/bloc/order_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final serviceLocator = GetIt.instance;

Future<void> initDependencies() async {
  _initUser();
  _initAuth();
  _initCategory();
  _initMenuItem();
  _initModifierOption();
  _initCart();
  _initTable();
  _initOrder();

  final supabase = await Supabase.initialize(
    url: AppSecrets.supabaseURL,
    anonKey: AppSecrets.supabaseKey,
  );

  serviceLocator.registerLazySingleton(() => supabase.client);
}

void _initUser() {
  serviceLocator.registerLazySingleton(() => UserBloc());
}

void _initModifierOption() {
  serviceLocator
    // Datasources
    ..registerFactory<ModifierOptionRemoteDataSource>(
      () => ModifierOptionRemoteDataSourceImpl(serviceLocator()),
    )
    // Repositories
    ..registerFactory<ModifierOptionRepository>(
      () => ModifierOptionRepositoryImpl(serviceLocator()),
    )
    // Usecases
    ..registerFactory(() => GetAllModifierOptions(serviceLocator()))
    ..registerFactory(() => GetAllModifierGroupOptions(serviceLocator()))
    ..registerFactory(() => CreateModifierGroupWithOptions(serviceLocator()))
    ..registerFactory(() => GetSelectedModifierGroupIds(serviceLocator()))
    ..registerFactory(() => UpdateMenuModifierGroups(serviceLocator()))
    // Bloc
    ..registerLazySingleton(
      () => ModifierOptionBloc(
        getAllModifierOptions: serviceLocator(),
        createModifierGroupWithOptions: serviceLocator(),
        getAllModifierGroupOptions: serviceLocator(),
        getSelectedModifierGroupIds: serviceLocator(),
      ),
    );
}

void _initMenuItem() {
  serviceLocator
    // Datasources
    ..registerFactory<MenuItemRemoteDataSource>(
      () => MenuItemRemoteDataSourceImpl(serviceLocator()),
    )
    // Repositories
    ..registerFactory<MenuItemRepository>(
      () => MenuItemRepositoryImpl(serviceLocator()),
    )
    // Usecases
    ..registerFactory(() => GetAllMenuItems(serviceLocator()))
    ..registerFactory(() => GetEnabledMenuItems(serviceLocator()))
    ..registerFactory(() => ListenAllMenuItems(serviceLocator()))
    ..registerFactory(() => ListenEnabledMenuItems(serviceLocator()))
    ..registerFactory(() => CreateMenuItem(serviceLocator()))
    ..registerFactory(() => UpdateMenuItemAvailability(serviceLocator()))
    // Bloc
    ..registerLazySingleton(
      () => MenuItemBloc(
        getAllMenuItems: serviceLocator(),
        getEnabledMenuItems: serviceLocator(),
        createMenuItem: serviceLocator(),
        listenAllMenuItems: serviceLocator(),
        listenEnabledMenuItems: serviceLocator(),
        updateMenuItemAvailability: serviceLocator(),
      ),
    );
}

void _initCategory() {
  serviceLocator
    // Datasources
    ..registerFactory<CategoryRemoteDataSource>(
      () => CategoryRemoteDataSourceImpl(serviceLocator()),
    )
    // Repositories
    ..registerFactory<CategoryRepository>(
      () => CategoryRepositoryImpl(serviceLocator()),
    )
    // Usecases
    ..registerFactory(() => GetAllCategories(serviceLocator()))
    ..registerFactory(() => ListenAllCategories(serviceLocator()))
    ..registerFactory(() => CreateCategory(serviceLocator()))
    // Bloc
    ..registerLazySingleton(
      () => CategoryBloc(
        getAllCategories: serviceLocator(),
        createCategory: serviceLocator(),
        listenAllCategories: serviceLocator(),
      ),
    );
}

void _initCart() {
  serviceLocator.registerLazySingleton(() => CartBloc());
}

void _initTable() {
  serviceLocator.registerLazySingleton(() => TableBloc());
}

void _initOrder() {
  serviceLocator
    // Datasources
    ..registerFactory<OrderRemoteDataSource>(
      () => OrderRemoteDataSourceImpl(serviceLocator()),
    )
    // Repositories
    ..registerFactory<OrderRepository>(
      () => OrderRepositoryImpl(serviceLocator()),
    )
    // Usecases
    ..registerFactory(() => CreateOrder(serviceLocator()))
    ..registerFactory(() => GetMonthlyRevenue(serviceLocator()))
    ..registerFactory(() => GetAllOrders(serviceLocator()))
    ..registerFactory(() => ListenMonthlyRevenue(serviceLocator()))
    ..registerFactory(() => ListenAllOrders(serviceLocator()))
    // Bloc
    ..registerLazySingleton(
      () => OrderBloc(
        createOrder: serviceLocator(),
        getMonthlyRevenue: serviceLocator(),
        getAllOrders: serviceLocator(),
        listenMonthlyRevenue: serviceLocator(),
        listenAllOrders: serviceLocator(),
      ),
    );
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
    ..registerFactory(() => Logout(serviceLocator()))
    // Bloc
    ..registerLazySingleton(
      () => AuthBloc(
        signUp: serviceLocator(),
        signIn: serviceLocator(),
        currentUser: serviceLocator(),
        logout: serviceLocator(),
        userBloc: serviceLocator(),
      ),
    );
}
