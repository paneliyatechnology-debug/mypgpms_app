import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/network/dio_client.dart';
import 'core/network/socket_service.dart';
import 'core/storage/preferences_service.dart';
import 'features/admission/presentation/bloc/admission_bloc.dart';
import 'features/dashboard/data/datasources/dashboard_remote_data_source.dart';
import 'features/dashboard/data/datasources/payments_remote_data_source.dart';
import 'features/dashboard/data/datasources/visitors_remote_data_source.dart';
import 'features/dashboard/data/datasources/complaints_remote_data_source.dart';
import 'features/dashboard/data/datasources/staff_remote_data_source.dart';
import 'features/dashboard/data/datasources/food_menu_remote_data_source.dart';
import 'features/dashboard/data/datasources/room_shift_remote_data_source.dart';
import 'features/dashboard/data/datasources/checkout_remote_data_source.dart';
import 'features/dashboard/data/datasources/notices_remote_data_source.dart';
import 'features/authentication/data/datasources/auth_remote_data_source.dart';
import 'features/authentication/data/repositories/auth_repository_impl.dart';
import 'features/authentication/domain/repositories/auth_repository.dart';
import 'features/authentication/domain/usecases/check_auth_status_usecase.dart';
import 'features/authentication/domain/usecases/forgot_password_usecase.dart';
import 'features/authentication/domain/usecases/get_me_usecase.dart';
import 'features/authentication/domain/usecases/login_usecase.dart';
import 'features/authentication/domain/usecases/refresh_token_usecase.dart';
import 'features/authentication/domain/usecases/update_profile_usecase.dart';
import 'features/authentication/domain/usecases/verify_otp_usecase.dart';
import 'features/authentication/domain/usecases/verify_phone_usecase.dart';
import 'features/authentication/presentation/bloc/auth_bloc.dart';

final sl = GetIt.instance;

Future<void> initDependencies() async {
  // Storage
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton<SharedPreferences>(() => sharedPreferences);
  sl.registerLazySingleton<PreferencesService>(() => PreferencesService(sl()));

  // Core
  sl.registerLazySingleton<DioClient>(
    () => DioClient(preferencesService: sl()),
  );
  sl.registerLazySingleton<SocketService>(
    () => SocketService(preferencesService: sl()),
  );

  // Features - Dashboard
  sl.registerLazySingleton<DashboardRemoteDataSource>(
    () => DashboardRemoteDataSourceImpl(dioClient: sl()),
  );
  sl.registerLazySingleton<PaymentsRemoteDataSource>(
    () => PaymentsRemoteDataSourceImpl(dioClient: sl()),
  );
  sl.registerLazySingleton<ComplaintsRemoteDataSource>(
    () => ComplaintsRemoteDataSourceImpl(dioClient: sl()),
  );
  sl.registerLazySingleton<StaffRemoteDataSource>(
    () => StaffRemoteDataSourceImpl(dioClient: sl()),
  );
  sl.registerLazySingleton<FoodMenuRemoteDataSource>(
    () => FoodMenuRemoteDataSourceImpl(dioClient: sl()),
  );
  sl.registerLazySingleton<RoomShiftRemoteDataSource>(
    () => RoomShiftRemoteDataSourceImpl(dioClient: sl()),
  );
  sl.registerLazySingleton<CheckoutRemoteDataSource>(
    () => CheckoutRemoteDataSourceImpl(dioClient: sl()),
  );
  sl.registerLazySingleton<VisitorsRemoteDataSource>(
    () => VisitorsRemoteDataSourceImpl(dioClient: sl()),
  );
  sl.registerLazySingleton<NoticesRemoteDataSource>(
    () => NoticesRemoteDataSourceImpl(dioClient: sl()),
  );

  // Features - Authentication
  // Data Sources
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(dioClient: sl()),
  );

  // Repositories
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      remoteDataSource: sl(),
      preferencesService: sl(),
    ),
  );

  // Use Cases
  sl.registerLazySingleton(() => LoginUseCase(sl()));
  sl.registerLazySingleton(() => RefreshTokenUseCase(sl()));
  sl.registerLazySingleton(() => CheckAuthStatusUseCase(sl()));
  sl.registerLazySingleton(() => VerifyPhoneUseCase(sl()));
  sl.registerLazySingleton(() => VerifyOtpUseCase(sl()));
  sl.registerLazySingleton(() => ForgotPasswordUseCase(sl()));
  sl.registerLazySingleton(() => GetMeUseCase(sl()));
  sl.registerLazySingleton(() => UpdateProfileUseCase(sl()));

  // BLoC
  sl.registerFactory(
    () => AuthBloc(
      loginUseCase: sl(),
      checkAuthStatusUseCase: sl(),
      verifyPhoneUseCase: sl(),
      verifyOtpUseCase: sl(),
      forgotPasswordUseCase: sl(),
    ),
  );
  sl.registerFactory(
    () => AdmissionBloc(
      getMeUseCase: sl(),
      updateProfileUseCase: sl(),
      preferencesService: sl(),
    ),
  );
}
