part of 'init_dependencies.dart';

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
  _initStoreSettings();
  _initInventory();
  _initStaff();
  _initShift();

  try {
    debugPrint('Initializing Firebase...');
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    ).timeout(const Duration(seconds: 15));
    
    serviceLocator.registerLazySingleton(() => FirebaseAuth.instance);
    serviceLocator.registerLazySingleton(() => FirebaseFirestore.instance);
    serviceLocator.registerLazySingleton(() => FirebaseStorage.instance);
  } catch (e) {
    debugPrint('Firebase Initialization Error: $e');
    rethrow;
  }

  try {
    debugPrint('Initializing Hive...');
    await Hive.initFlutter();
    final cashierShiftBox = await Hive.openBox<dynamic>('cashier_shift_box');
    serviceLocator.registerLazySingleton<Box<dynamic>>(() => cashierShiftBox);

    final qrisBox = await Hive.openBox<String>('qris_cache');
    serviceLocator.registerLazySingleton<Box<String>>(() => qrisBox, instanceName: 'qris_cache');

    final printerLocalService = await PrinterLocalService.init();
    serviceLocator.registerLazySingleton<PrinterLocalService>(() => printerLocalService);
  } catch (e) {
    debugPrint('Hive Initialization Error: $e');
    rethrow;
  }

  serviceLocator.registerLazySingleton(
    () => CashierShiftLocalService(serviceLocator(), serviceLocator()),
  );
  serviceLocator.registerLazySingleton<ThermalReceiptPrinterService>(
    () => ThermalReceiptPrinterServiceImpl(serviceLocator()),
  );
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
    ..registerFactory(() => CreateMenuItem(serviceLocator()))
    ..registerFactory(() => UpdateMenuItemAvailability(serviceLocator()))
    ..registerFactory(() => UpdateMenuItem(serviceLocator()))
    // Bloc
    ..registerLazySingleton(
      () => MenuItemBloc(
        getAllMenuItems: serviceLocator(),
        getEnabledMenuItems: serviceLocator(),
        createMenuItem: serviceLocator(),
        updateMenuItem: serviceLocator(),
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
    ..registerFactory(() => CreateCategory(serviceLocator()))
    // Bloc
    ..registerLazySingleton(
      () => CategoryBloc(
        getAllCategories: serviceLocator(),
        createCategory: serviceLocator(),
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
    ..registerFactory(() => GetRevenueRange(serviceLocator()))
    ..registerFactory(() => GetAllOrders(serviceLocator()))
    // Bloc
    ..registerLazySingleton(
      () => OrderBloc(
        createOrder: serviceLocator(),
        getMonthlyRevenue: serviceLocator(),
        getRevenueRange: serviceLocator(),
        getAllOrders: serviceLocator(),
        orderRepository: serviceLocator(),
      ),
    );
}

void _initStoreSettings() {
  serviceLocator
    // Datasources
    ..registerFactory<StoreSettingsRemoteDataSource>(
      () => StoreSettingsRemoteDataSourceImpl(serviceLocator()),
    )
    // Repositories
    ..registerFactory<StoreSettingsRepository>(
      () => StoreSettingsRepositoryImpl(serviceLocator()),
    )
    // Usecases
    ..registerFactory(() => GetStoreSettings(serviceLocator()))
    ..registerFactory(() => UpdateStoreSettings(serviceLocator()))
    // Bloc
    ..registerLazySingleton(
      () => StoreSettingsBloc(
        getStoreSettings: serviceLocator(),
        updateStoreSettings: serviceLocator(),
      ),
    );
}

void _initAuth() {
  serviceLocator
    // Datasources
    ..registerFactory<AuthRemoteDataSource>(
      () => AuthRemoteDataSourceImpl(
        serviceLocator<FirebaseAuth>(),
        serviceLocator<FirebaseFirestore>(),
      ),
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
    ..registerFactory(() => ChangePassword(serviceLocator()))
    ..registerFactory(() => CheckOwnerExists(serviceLocator()))
    // Bloc
    ..registerLazySingleton(
      () => AuthBloc(
        signUp: serviceLocator(),
        signIn: serviceLocator(),
        currentUser: serviceLocator(),
        logout: serviceLocator(),
        changePassword: serviceLocator(),
        userBloc: serviceLocator(),
      ),
    );
}

void _initInventory() {
  serviceLocator
    // Datasources
    ..registerFactory<InventoryRemoteDataSource>(
      () => InventoryRemoteDataSourceImpl(serviceLocator()),
    )
    // Repositories
    ..registerFactory<InventoryRepository>(
      () => InventoryRepositoryImpl(serviceLocator()),
    )
    // Usecases
    ..registerFactory(() => GetStockLevels(serviceLocator()))
    ..registerFactory(() => AdjustStock(serviceLocator()))
    ..registerFactory(() => CreatePurchaseOrder(serviceLocator()))
    ..registerFactory(() => GetStockHistory(serviceLocator()))
    // Bloc
    ..registerLazySingleton(
      () => InventoryBloc(
        getStockLevels: serviceLocator(),
        adjustStock: serviceLocator(),
        createPurchaseOrder: serviceLocator(),
        getStockHistory: serviceLocator(),
        inventoryRepository: serviceLocator(),
        orderRepository: serviceLocator(),
      ),
    );
}

void _initStaff() {
  serviceLocator
    // Datasources
    ..registerFactory<StaffRemoteDataSource>(
      () => StaffRemoteDataSourceImpl(
        serviceLocator<FirebaseFirestore>(),
      ),
    )
    // Repositories
    ..registerFactory<StaffRepository>(
      () => StaffRepositoryImpl(serviceLocator()),
    )
    // Bloc
    ..registerLazySingleton(() => StaffBloc(serviceLocator()));
}

void _initShift() {
  serviceLocator
    // Datasources
    ..registerFactory<ShiftRemoteDataSource>(
      () => ShiftRemoteDataSourceImpl(serviceLocator()),
    )
    // Repositories
    ..registerFactory<ShiftRepository>(
      () => ShiftRepositoryImpl(serviceLocator()),
    )
    // Bloc
    ..registerLazySingleton(
      () => ShiftBloc(
        shiftRepository: serviceLocator(),
        shiftLocalService: serviceLocator(),
      ),
    );
}
