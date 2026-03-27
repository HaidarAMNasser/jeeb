import 'package:get_it/get_it.dart';
import 'package:dio/dio.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:jeeb_app/features/delivery/home/presentation/bloc/delivery_home_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../network/network_info.dart';
import '../../presentation/routes/navigation_service.dart';
import '../services/storage_service.dart';
import '../services/dio_factory.dart';
import '../services/notification_service.dart';
import '../api/api_service.dart';
import '../../config/app_config.dart';
import '../../../features/product/list_product/data/data_sources/list_product_data_source.dart';
import '../../../features/product/list_product/data/repositories/list_product_repository.dart';
import '../../../features/product/product_details/data/data_sources/product_details_data_source.dart';
import '../../../features/product/product_details/data/repositories/product_details_repository.dart';
import '../../../features/category/list_category/data/data_sources/list_category_data_source.dart';
import '../../../features/category/list_category/data/repositories/list_category_repository.dart';
import '../../../features/category/list_category/presentation/bloc/list_category_bloc.dart';
import '../../../features/auth/login/data/data_sources/login_remote_data_source.dart';
import '../../../features/auth/login/data/repositories/login_repository.dart';
import '../../../features/auth/login/presentation/bloc/login_bloc.dart';
import '../../../features/auth/register/data/data_sources/register_remote_data_source.dart';
import '../../../features/auth/register/data/repositories/register_repository.dart';
import '../../../features/auth/register/presentation/bloc/register_bloc.dart';
import '../../../features/auth/verify/data/data_sources/verify_remote_data_source.dart';
import '../../../features/auth/verify/data/repositories/verify_repository.dart';
import '../../../features/auth/verify/presentation/bloc/verify_bloc.dart';
import '../../../features/auth/forgot_password/data/data_sources/forgot_password_remote_data_source.dart';
import '../../../features/auth/forgot_password/data/repositories/forgot_password_repository.dart';
import '../../../features/auth/forgot_password/presentation/bloc/forgot_password_bloc.dart';
import '../../../features/auth/reset_password/data/data_sources/reset_password_remote_data_source.dart';
import '../../../features/auth/reset_password/data/repositories/reset_password_repository.dart';
import '../../../features/auth/reset_password/presentation/bloc/reset_password_bloc.dart';
import '../../../features/auth/profile/data/data_sources/profile_remote_data_source.dart';
import '../../../features/auth/profile/data/repositories/profile_repository.dart';
import '../../../features/auth/profile/presentation/bloc/profile_bloc.dart';
import '../../../features/auth/logout/data/data_sources/logout_remote_data_source.dart';
import '../../../features/auth/logout/data/repositories/logout_repository.dart';
import '../../../features/auth/logout/presentation/bloc/logout_bloc.dart';
import '../../../features/get_settings/data/data_sources/get_settings_data_source.dart';
import '../../../features/get_settings/data/repositories/get_settings_repository.dart';
import '../../../features/country/data/data_sources/country_remote_data_source.dart';
import '../../../features/country/data/repositories/country_repository.dart';
import '../../../features/country/presentation/bloc/country_bloc.dart';
import '../../../features/city/data/data_sources/city_remote_data_source.dart';
import '../../../features/city/data/repositories/city_repository.dart';
import '../../../features/city/presentation/bloc/city_bloc.dart';
import '../../../features/merchant/list_merchant/data/data_sources/list_merchant_data_source.dart';
import '../../../features/merchant/list_merchant/data/repositories/list_merchant_repository.dart';
import '../../../features/merchant/merchant_details/data/data_sources/merchant_details_data_source.dart';
import '../../../features/merchant/merchant_details/data/repositories/merchant_details_repository.dart';

import '../../../features/order/list_order/data/data_sources/list_order_data_source.dart';
import '../../../features/order/list_order/data/repositories/list_order_repository.dart';
import '../../../features/order/order_details/data/data_sources/order_details_data_source.dart';
import '../../../features/order/order_details/data/repositories/order_details_repository.dart';
import '../../../features/order/manage_order/data/data_sources/manage_order_remote_data_source.dart';
import '../../../features/order/manage_order/data/repositories/manage_order_repository.dart';
import '../../../features/order/manage_order/presentation/bloc/manage_order_bloc.dart';

import '../../../features/order/list_order/presentation/bloc/list_order_bloc.dart';
import '../../../features/offer/list_offer/data/data_sources/list_offer_data_source.dart';
import '../../../features/offer/list_offer/data/repositories/list_offer_repository.dart';
import '../../../features/offer/offer_details/data/data_sources/offer_details_data_source.dart';
import '../../../features/offer/offer_details/data/repositories/offer_details_repository.dart';

import '../../../features/order/order_details/presentation/bloc/order_details_bloc.dart';
import '../../../features/client_home/presentation/bloc/client_home_bloc.dart';
import '../../../features/favorites/data/data_sources/favorites_remote_data_source.dart';
import '../../../features/favorites/data/repositories/favorites_repository.dart';
import '../../../features/favorites/presentation/bloc/favorites_bloc.dart';
import '../../../features/search/data/data_sources/search_remote_data_source.dart';
import '../../../features/search/data/repositories/search_repository_impl.dart';
import '../../../features/search/domain/repositories/search_repository.dart';
import '../../../features/basket/list_cart/data/data_sources/list_cart_remote_data_source.dart';
import '../../../features/basket/list_cart/data/repositories/list_cart_repository.dart';
import '../../../features/basket/list_cart/presentation/bloc/list_cart_bloc.dart';
import '../../../features/basket/manage_cart/data/data_sources/manage_cart_remote_data_source.dart';
import '../../../features/basket/manage_cart/data/repositories/manage_cart_repository.dart';
import '../../../features/basket/manage_cart/presentation/bloc/manage_cart_bloc.dart';
import '../../../features/notification/update_token/data/data_sources/update_token_remote_data_source.dart';
import '../../../features/notification/update_token/data/repositories/update_token_repository.dart';
import '../../../features/notification/update_token/presentation/bloc/update_token_bloc.dart';

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
  sl.registerLazySingleton<NotificationService>(
    () => NotificationService(sl()),
  );

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

  //! Category List Dependencies
  sl.registerFactory<ListCategoryRemoteDataSource>(
    () => ListCategoryRemoteDataSourceImpl(sl()),
  );
  sl.registerFactory(() => ListCategoryRepository(sl(), sl()));
  sl.registerFactory(() => ListCategoryBloc(sl()));

  //! Product List Dependencies
  sl.registerFactory<ListProductRemoteDataSource>(
    () => ListProductRemoteDataSourceImpl(sl()),
  );
  sl.registerFactory(() => ListProductRepository(sl(), sl()));

  //! Product Details Dependencies
  sl.registerFactory<ProductDetailsRemoteDataSource>(
    () => ProductDetailsRemoteDataSourceImpl(sl()),
  );
  sl.registerFactory(() => ProductDetailsRepository(sl(), sl()));

  //!

  //! Auth Dependencies - Login
  sl.registerFactory<LoginRemoteDataSource>(
    () => LoginRemoteDataSourceImpl(sl<AppApiServiceClient>()),
  );
  sl.registerFactory(() => LoginRepository(sl(), sl()));
  sl.registerFactory(() => LoginBloc(sl(), sl()));

  //! Auth Dependencies - Register
  sl.registerFactory<RegisterRemoteDataSource>(
    () => RegisterRemoteDataSourceImpl(sl<AppApiServiceClient>()),
  );
  sl.registerFactory(() => RegisterRepository(sl(), sl()));
  sl.registerFactory(() => RegisterBloc(sl(), sl<StorageService>()));

  //! Auth Dependencies - Verify
  sl.registerFactory<VerifyRemoteDataSource>(
    () => VerifyRemoteDataSourceImpl(sl<AppApiServiceClient>()),
  );
  sl.registerFactory(() => VerifyRepository(sl(), sl()));
  sl.registerFactory(
    () => VerifyBloc(sl(), sl<StorageService>(), sl<ProfileRepository>()),
  );

  //! Auth Dependencies - Forgot Password
  sl.registerFactory<ForgotPasswordRemoteDataSource>(
    () => ForgotPasswordRemoteDataSourceImpl(sl<AppApiServiceClient>()),
  );
  sl.registerFactory(() => ForgotPasswordRepository(sl(), sl()));
  sl.registerFactory(() => ForgotPasswordBloc(sl()));

  //! Auth Dependencies - Reset Password
  sl.registerFactory<ResetPasswordRemoteDataSource>(
    () => ResetPasswordRemoteDataSourceImpl(sl<AppApiServiceClient>()),
  );
  sl.registerFactory(() => ResetPasswordRepository(sl(), sl()));
  sl.registerFactory(() => ResetPasswordBloc(sl()));

  //! Auth Dependencies - Profile
  sl.registerFactory<ProfileRemoteDataSource>(
    () => ProfileRemoteDataSourceImpl(sl<AppApiServiceClient>()),
  );
  sl.registerFactory(() => ProfileRepository(sl(), sl()));
  sl.registerFactory(
    () => ProfileBloc(sl<ProfileRepository>(), sl<StorageService>()),
  );

  //! Auth Dependencies - Logout
  sl.registerFactory<LogoutRemoteDataSource>(
    () => LogoutRemoteDataSourceImpl(sl<AppApiServiceClient>()),
  );
  sl.registerFactory(() => LogoutRepository(sl(), sl()));
  sl.registerFactory(() => LogoutBloc(sl(), sl()));

  sl.registerFactory<GetSettingsRemoteDataSource>(
    () => GetSettingsRemoteDataSourceImpl(sl<AppApiServiceClient>()),
  );
  sl.registerFactory(() => GetSettingsRepository(sl(), sl()));

  //! Country Dependencies
  sl.registerFactory<CountryRemoteDataSource>(
    () => CountryRemoteDataSourceImpl(sl<AppApiServiceClient>()),
  );
  sl.registerFactory(() => CountryRepository(sl(), sl()));
  sl.registerFactory(() => CountryBloc(sl()));

  //! City Dependencies
  sl.registerFactory<CityRemoteDataSource>(
    () => CityRemoteDataSourceImpl(sl<AppApiServiceClient>()),
  );
  sl.registerFactory(() => CityRepository(sl(), sl()));
  sl.registerFactory(() => CityBloc(sl()));

  //! Merchant List Dependencies
  sl.registerFactory<ListMerchantRemoteDataSource>(
    () => ListMerchantRemoteDataSourceImpl(sl()),
  );
  sl.registerFactory(() => ListMerchantRepository(sl(), sl()));

  //! Merchant Details Dependencies
  sl.registerFactory<MerchantDetailsRemoteDataSource>(
    () => MerchantDetailsRemoteDataSourceImpl(sl()),
  );
  sl.registerFactory(() => MerchantDetailsRepository(sl(), sl()));

  sl.registerFactory<ListOrderRemoteDataSource>(
    () => ListOrderRemoteDataSourceImpl(sl()),
  );
  sl.registerFactory(() => ListOrderRepository(sl(), sl()));
  sl.registerFactory(() => ListOrderBloc(sl()));

  //! Order Details Dependencies
  sl.registerFactory<OrderDetailsRemoteDataSource>(
    () => OrderDetailsRemoteDataSourceImpl(sl()),
  );
  sl.registerFactory(() => OrderDetailsRepository(sl(), sl()));
  sl.registerFactory(() => OrderDetailsBloc(sl()));

  //! Manage Order Dependencies
  sl.registerFactory<ManageOrderRemoteDataSource>(
    () => ManageOrderRemoteDataSourceImpl(sl()),
  );
  sl.registerFactory(() => ManageOrderRepository(sl(), sl()));
  sl.registerFactory(() => ManageOrderBloc(sl()));

  sl.registerFactory(() => DeliveryHomeBloc(sl()));

  sl.registerFactory<ListOfferRemoteDataSource>(
    () => ListOfferRemoteDataSourceImpl(sl()),
  );
  sl.registerFactory(() => ListOfferRepository(sl(), sl()));

  //! Offer Details
  sl.registerFactory<OfferDetailsRemoteDataSource>(
    () => OfferDetailsRemoteDataSourceImpl(sl()),
  );
  sl.registerFactory(() => OfferDetailsRepository(sl(), sl()));

  //! Favorites (customer role; singleton so product list/details share state)
  sl.registerFactory<FavoritesRemoteDataSource>(
    () => FavoritesRemoteDataSourceImpl(sl()),
  );
  sl.registerFactory(() => FavoritesRepository(sl(), sl()));
  sl.registerLazySingleton<FavoritesBloc>(() => FavoritesBloc(sl()));

  //! Client Home (customer role)
  sl.registerFactory<ClientHomeBloc>(
    () => ClientHomeBloc(
      categoryRepository: sl<ListCategoryRepository>(),
      merchantRepository: sl<ListMerchantRepository>(),
      productRepository: sl<ListProductRepository>(),
      offersRepository: sl<ListOfferRepository>(),
      searchRepository: sl<SearchRepository>(),
    ),
  );

  //! Global Search
  sl.registerLazySingleton<SearchRemoteDataSource>(
    () => SearchRemoteDataSourceImpl(sl()),
  );
  sl.registerLazySingleton<SearchRepository>(
    () => SearchRepositoryImpl(sl(), sl()),
  );

  //! Basket / Cart - List endpoint
  sl.registerFactory<ListCartRemoteDataSource>(
    () => ListCartRemoteDataSourceImpl(sl<AppApiServiceClient>()),
  );
  sl.registerFactory(() => ListCartRepository(sl(), sl()));
  sl.registerLazySingleton<ListCartBloc>(() => ListCartBloc(sl(), sl()));

  //! Basket / Cart - Create/Update/Clear endpoints
  sl.registerFactory<ManageCartRemoteDataSource>(
    () => ManageCartRemoteDataSourceImpl(sl<AppApiServiceClient>()),
  );
  sl.registerFactory(() => ManageCartRepository(sl(), sl()));
  sl.registerLazySingleton<ManageCartBloc>(() => ManageCartBloc(sl()));

  //! FCM - Update device token
  sl.registerFactory<UpdateTokenRemoteDataSource>(
    () => UpdateTokenRemoteDataSourceImpl(sl<AppApiServiceClient>()),
  );
  sl.registerFactory(() => UpdateTokenRepository(sl(), sl()));
  sl.registerLazySingleton<UpdateTokenBloc>(() => UpdateTokenBloc(sl(), sl()));
}
