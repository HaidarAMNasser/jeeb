import 'package:get_it/get_it.dart';
import 'package:dio/dio.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../network/network_info.dart';
import '../../presentation/routes/navigation_service.dart';
import '../services/storage_service.dart';
import '../services/dio_factory.dart';
import '../api/api_service.dart';
import '../../config/app_config.dart';
import '../../../features/auth/login/data/data_sources/login_remote_data_source.dart';
import '../../../features/auth/login/data/repositories/login_repository.dart';
import '../../../features/auth/login/presentation/bloc/login_bloc.dart';
import '../../../features/auth/register/data/data_sources/register_remote_data_source.dart';
import '../../../features/auth/register/data/repositories/register_repository.dart';
import '../../../features/auth/register/presentation/bloc/register_bloc.dart';
import '../../../features/auth/forgot_password/data/data_sources/forgot_password_remote_data_source.dart';
import '../../../features/auth/forgot_password/data/repositories/forgot_password_repository.dart';
import '../../../features/auth/forgot_password/presentation/bloc/forgot_password_bloc.dart';
import '../../../features/auth/reset_password/data/data_sources/reset_password_remote_data_source.dart';
import '../../../features/auth/reset_password/data/repositories/reset_password_repository.dart';
import '../../../features/auth/reset_password/presentation/bloc/reset_password_bloc.dart';
import '../../../features/auth/verify/data/data_sources/verify_remote_data_source.dart';
import '../../../features/auth/verify/data/repositories/verify_repository.dart';
import '../../../features/auth/verify/presentation/bloc/verify_bloc.dart';
import '../../../features/auth/profile/data/data_sources/profile_remote_data_source.dart';
import '../../../features/auth/profile/data/repositories/profile_repository.dart';
import '../../../features/auth/profile/presentation/bloc/profile_bloc.dart';
import '../../../features/country/data/data_sources/country_remote_data_source.dart';
import '../../../features/country/data/repositories/country_repository.dart';
import '../../../features/country/presentation/bloc/country_bloc.dart';
import '../../../features/city/data/data_sources/city_remote_data_source.dart';
import '../../../features/city/data/repositories/city_repository.dart';
import '../../../features/city/presentation/bloc/city_bloc.dart';
import '../../../features/onboarding/presentation/bloc/onboarding_bloc.dart';

final sl = GetIt.instance;

/// Initialize Dependency Injection
Future<void> init() async {
  //! External
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton(() => sharedPreferences);
  sl.registerLazySingleton(() => InternetConnectionChecker.createInstance());

  //! Core Services
  sl.registerLazySingleton<StorageService>(() => StorageServiceImpl(sl()));
  sl.registerLazySingleton(() => NavigationService());

  //! Network
  sl.registerLazySingleton<NetworkInfo>(() => NetworkInfoImpl(sl()));

  //! Dio Factory
  sl.registerLazySingleton<DioFactory>(
    () => DioFactory(sl<StorageService>(), sl<NavigationService>()),
  );

  //! Dio Instance - Initialize asynchronously using registered factory
  final dioFactory = sl<DioFactory>();
  final dio = await dioFactory.getDio();
  sl.registerLazySingleton<Dio>(() => dio);

  //! API Service Client
  sl.registerLazySingleton<AppApiServiceClient>(
    () => AppApiServiceClient(dio: sl<Dio>(), baseUrlApi: AppConfig.baseUrl),
  );

  //! Auth - Login
  sl.registerFactory<LoginRemoteDataSource>(
    () => LoginRemoteDataSourceImpl(sl<AppApiServiceClient>()),
  );
  sl.registerFactory<LoginRepository>(
    () => LoginRepository(sl<LoginRemoteDataSource>(), sl<NetworkInfo>()),
  );
  sl.registerFactory<LoginBloc>(
    () => LoginBloc(sl<LoginRepository>(), sl<StorageService>()),
  );

  //! Auth - Register
  sl.registerFactory<RegisterRemoteDataSource>(
    () => RegisterRemoteDataSourceImpl(),
  );
  sl.registerFactory<RegisterRepository>(
    () => RegisterRepository(sl<RegisterRemoteDataSource>(), sl<NetworkInfo>()),
  );
  sl.registerFactory<RegisterBloc>(
    () => RegisterBloc(sl<RegisterRepository>()),
  );

  //! Auth - Forgot Password
  sl.registerFactory<ForgotPasswordRemoteDataSource>(
    () => ForgotPasswordRemoteDataSourceImpl(),
  );
  sl.registerFactory<ForgotPasswordRepository>(
    () => ForgotPasswordRepository(
        sl<ForgotPasswordRemoteDataSource>(), sl<NetworkInfo>()),
  );
  sl.registerFactory<ForgotPasswordBloc>(
    () => ForgotPasswordBloc(sl<ForgotPasswordRepository>()),
  );

  //! Auth - Reset Password
  sl.registerFactory<ResetPasswordRemoteDataSource>(
    () => ResetPasswordRemoteDataSourceImpl(),
  );
  sl.registerFactory<ResetPasswordRepository>(
    () => ResetPasswordRepository(
        sl<ResetPasswordRemoteDataSource>(), sl<NetworkInfo>()),
  );
  sl.registerFactory<ResetPasswordBloc>(
    () => ResetPasswordBloc(sl<ResetPasswordRepository>()),
  );

  //! Auth - Verify
  sl.registerFactory<VerifyRemoteDataSource>(
    () => VerifyRemoteDataSourceImpl(),
  );
  sl.registerFactory<VerifyRepository>(
    () => VerifyRepository(sl<VerifyRemoteDataSource>(), sl<NetworkInfo>()),
  );
  sl.registerFactory<VerifyBloc>(
    () => VerifyBloc(sl<VerifyRepository>()),
  );

  //! Auth - Profile
  sl.registerFactory<ProfileRemoteDataSource>(
    () => ProfileRemoteDataSourceImpl(),
  );
  sl.registerFactory<ProfileRepository>(
    () => ProfileRepository(sl<ProfileRemoteDataSource>(), sl<NetworkInfo>()),
  );
  sl.registerFactory<ProfileBloc>(
    () => ProfileBloc(sl<ProfileRepository>()),
  );

  //! Country & City (for auth register/profile)
  sl.registerFactory<CountryRemoteDataSource>(
    () => CountryRemoteDataSourceImpl(sl<AppApiServiceClient>()),
  );
  sl.registerFactory<CountryRepository>(
    () => CountryRepository(sl<CountryRemoteDataSource>(), sl<NetworkInfo>()),
  );
  sl.registerFactory<CountryBloc>(() => CountryBloc(sl<CountryRepository>()));

  sl.registerFactory<CityRemoteDataSource>(
    () => CityRemoteDataSourceImpl(sl<AppApiServiceClient>()),
  );
  sl.registerFactory<CityRepository>(
    () => CityRepository(sl<CityRemoteDataSource>(), sl<NetworkInfo>()),
  );
  sl.registerFactory<CityBloc>(() => CityBloc(sl<CityRepository>()));

  //! Onboarding
  sl.registerFactory<OnboardingBloc>(() => OnboardingBloc());
}
