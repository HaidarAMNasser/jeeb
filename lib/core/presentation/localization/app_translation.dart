import 'package:easy_localization/easy_localization.dart';

/// Centralized translation class
/// Usage: AppTranslation.onboardingTitle instead of 'onboarding_title_1'.tr()
class AppTranslation {
  AppTranslation._();

  // App Info
  static String get appName => 'app_name'.tr();
  static String get craftedBy => 'crafted_by'.tr();
  static String get countryEgypt => 'country_egypt'.tr();

  // Common
  static String get welcome => 'welcome'.tr();
  static String get skip => 'skip'.tr();
  static String get next => 'next'.tr();
  static String get done => 'done'.tr();
  static String get getStarted => 'get_started'.tr();
  static String get home => 'home'.tr();
  static String get settings => 'settings'.tr();
  static String get profile => 'profile'.tr();
  static String get logout => 'logout'.tr();

  // Splash
  static String get splashTitle => 'splash_title'.tr();
  static String get splashTagline => 'splash_tagline'.tr();

  // Onboarding
  static String get onboardingTitle1 => 'onboarding_title_1'.tr();
  static String get onboardingDesc1 => 'onboarding_desc_1'.tr();
  static String get onboardingTitle2 => 'onboarding_title_2'.tr();
  static String get onboardingDesc2 => 'onboarding_desc_2'.tr();
  static String get onboardingTitle3 => 'onboarding_title_3'.tr();
  static String get onboardingDesc3 => 'onboarding_desc_3'.tr();
  static String get onboardingTitle4 => 'onboarding_title_4'.tr();
  static String get onboardingDesc4 => 'onboarding_desc_4'.tr();
  static String get termsAndConditions => 'terms_and_conditions'.tr();
  static String get allowNotifications => 'allow_notifications'.tr();
  static String get notificationsEnabledSuccess => 'notifications_enabled_success'.tr();

  // Home
  static String get homeTitle => 'home_title'.tr();
  static String get homeSubtitle => 'home_subtitle'.tr();
  static String get homeCtaTitle => 'home_cta_title'.tr();
  static String get homeCtaSubtitle => 'home_cta_subtitle'.tr();
  static String get startBuilding => 'start_building'.tr();
  static String get madeWithLove => 'made_with_love'.tr();
  static String get createdBy => 'created_by'.tr();

  // Category
  static String get categories => 'categories'.tr();
  static String get addCategory => 'add_category'.tr();
  static String get categoryName => 'category_name'.tr();
  static String get pleaseEnterCategoryName => 'please_enter_category_name'.tr();
  static String get categoryAddedSuccessfully => 'category_added_successfully'.tr();

  // Product
  static String get products => 'products'.tr();
  static String get addProduct => 'add_product'.tr();
  static String get editProduct => 'edit_product'.tr();
  static String get productName => 'product_name'.tr();
  static String get productDescription => 'product_description'.tr();
  static String get productPrice => 'product_price'.tr();
  static String get productQuantity => 'product_quantity'.tr();
  static String get selectCategory => 'select_category'.tr();
  static String get productImages => 'product_images'.tr();
  static String get addImage => 'add_image'.tr();
  static String get removeImage => 'remove_image'.tr();
  static String get noImagesAdded => 'no_images_added'.tr();
  static String get enterImageUrl => 'enter_image_url'.tr();
  static String get add => 'add'.tr();
  static String get pleaseEnterProductName => 'please_enter_product_name'.tr();
  static String get pleaseEnterProductPrice => 'please_enter_product_price'.tr();
  static String get invalidProductPrice => 'invalid_product_price'.tr();
  static String get pleaseSelectCategory => 'please_select_category'.tr();
  static String get pleaseAddAtLeastOneImage => 'please_add_at_least_one_image'.tr();
  static String get productCreatedSuccessfully => 'product_created_successfully'.tr();
  static String get productUpdatedSuccessfully => 'product_updated_successfully'.tr();
  static String get productDeletedSuccessfully => 'product_deleted_successfully'.tr();
  static String get deleteProduct => 'delete_product'.tr();
  static String get areYouSureDeleteProduct => 'are_you_sure_delete_product'.tr();
  static String get areYouSureWantToDeleteThisProduct => 'are_you_sure_want_to_delete_this_product'.tr();
  static String get delete => 'delete'.tr();
  static String get edit => 'edit'.tr();
  static String get save => 'save'.tr();
  static String get cancel => 'cancel'.tr();
  static String get confirm => 'confirm'.tr();
  static String get rating => 'rating'.tr();
  static String get noProductsFound => 'no_products_found'.tr();
  static String get noCategoriesFound => 'no_categories_found'.tr();
  static String get loading => 'loading'.tr();
  static String get errorOccurred => 'error_occurred'.tr();
  static String get retry => 'retry'.tr();
  static String get noInternetConnection => 'no_internet_connection'.tr();
  static String get noDataFound => 'no_data_found'.tr();
  static String get somethingWentWrong => 'something_went_wrong'.tr();
  static String get productDetails => 'product_details'.tr();

  // Auth
  static String get login => 'login'.tr();
  static String get register => 'register'.tr();
  static String get email => 'email'.tr();
  static String get password => 'password'.tr();
  static String get enterEmail => 'enter_email'.tr();
  static String get enterPassword => 'enter_password'.tr();
  static String get loginSuccess => 'login_success'.tr();
  static String get forgotPassword => 'forgot_password'.tr();
  static String get dontHaveAccount => 'dont_have_account'.tr();
  static String get alreadyHaveAccount => 'already_have_account'.tr();
  static String get firstName => 'first_name'.tr();
  static String get lastName => 'last_name'.tr();
  static String get phone => 'phone'.tr();
  static String get enterPhone => 'enter_phone'.tr();
  static String get address => 'address'.tr();
  static String get enterAddress => 'enter_address'.tr();
  static String get selectCountry => 'select_country'.tr();
  static String get selectCity => 'select_city'.tr();
  static String get notificationChannel => 'notification_channel'.tr();
  static String get verifyAccount => 'verify_account'.tr();
  static String get enterOtp => 'enter_otp'.tr();
  static String get otp => 'otp'.tr();
  static String get resendOtp => 'resend_otp'.tr();
  static String get resetPassword => 'reset_password'.tr();
  static String get newPassword => 'new_password'.tr();
  static String get confirmPassword => 'confirm_password'.tr();
  static String get passwordResetSuccess => 'password_reset_success'.tr();
  static String get accountVerifiedSuccess => 'account_verified_success'.tr();
  static String get otpSentSuccess => 'otp_sent_success'.tr();
  static String get notAuthorized => 'not_authorized'.tr();
  static String get pleaseEnterEmail => 'please_enter_email'.tr();
  static String get pleaseEnterPassword => 'please_enter_password'.tr();
  static String get pleaseSelectCountry => 'please_select_country'.tr();
  static String get pleaseSelectCity => 'please_select_city'.tr();
  static String get registerSuccess => 'register_success'.tr();
  static String get pleaseEnterOtp => 'please_enter_otp'.tr();
  static String get sendOtp => 'send_otp'.tr();
  static String get passwordsDoNotMatch => 'passwords_do_not_match'.tr();
  static String get profileUpdatedSuccess => 'profile_updated_success'.tr();
  static String get forgotPasswordDescription => 'forgot_password_description'.tr();
  static String get pleaseSelectCountryFirst => 'please_select_country_first'.tr();
  static String get noCitiesAvailable => 'no_cities_available'.tr();

  // Merchant
  static String get merchants => 'merchants'.tr();
  static String get merchantDetails => 'merchant_details'.tr();
  static String get noMerchantsFound => 'no_merchants_found'.tr();
  static String get location => 'location'.tr();

  // Delivery
  static String get deliveryMen => 'delivery_men'.tr();
  static String get deliveryManDetails => 'delivery_man_details'.tr();
  static String get addDeliveryMan => 'add_delivery_man'.tr();
  static String get editDeliveryMan => 'edit_delivery_man'.tr();
  static String get noDeliveryMenFound => 'no_delivery_men_found'.tr();
  static String get vehicleType => 'vehicle_type'.tr();
  static String get status => 'status'.tr();
}

