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
  static String get notificationsEnabledSuccess =>
      'notifications_enabled_success'.tr();

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
  static String get pleaseEnterCategoryName =>
      'please_enter_category_name'.tr();
  static String get categoryAddedSuccessfully =>
      'category_added_successfully'.tr();

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
  static String get pleaseEnterProductPrice =>
      'please_enter_product_price'.tr();
  static String get invalidProductPrice => 'invalid_product_price'.tr();
  static String get pleaseSelectCategory => 'please_select_category'.tr();
  static String get pleaseAddAtLeastOneImage =>
      'please_add_at_least_one_image'.tr();
  static String get productCreatedSuccessfully =>
      'product_created_successfully'.tr();
  static String get productUpdatedSuccessfully =>
      'product_updated_successfully'.tr();
  static String get productDeletedSuccessfully =>
      'product_deleted_successfully'.tr();
  static String get deleteProduct => 'delete_product'.tr();
  static String get areYouSureDeleteProduct =>
      'are_you_sure_delete_product'.tr();
  static String get areYouSureWantToDeleteThisProduct =>
      'are_you_sure_want_to_delete_this_product'.tr();
  static String get productConfirmedSuccessfully =>
      'product_confirmed_successfully'.tr();
  static String get confirmProduct => 'confirm_product'.tr();
  static String get options => 'options'.tr();
  static String get newPrice => 'new_price'.tr();
  static String get enterNewPrice => 'enter_new_price'.tr();
  static String get productConfirming => 'product_confirming'.tr();
  static String get delete => 'delete'.tr();
  static String get edit => 'edit'.tr();
  static String get merchantDeletedSuccessfully =>
      'merchant_deleted_successfully'.tr();
  static String get areYouSureDeleteMerchant =>
      'are_you_sure_delete_merchant'.tr();
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
  static String get summary => 'summary'.tr();
  static String get availability => 'availability'.tr();
  static String get inStock => 'in_stock'.tr();
  static String get outOfStock => 'out_of_stock'.tr();
  static String get availableForOrder => 'available_for_order'.tr();
  static String get notAvailable => 'not_available'.tr();
  static String get merchant => 'merchant'.tr();
  static String get servesCount => 'serves_count'.tr();
  static String get basePricePercentAdded => 'base_price_percent_added'.tr();
  static String get percentOff => 'percent_off'.tr();
  static String inStockCount(int n) => 'in_stock'.tr(args: [n.toString()]);
  static String servesCountN(int n) => 'serves_count'.tr(args: [n.toString()]);
  static String basePricePercentAddedN(String price, String percent) =>
      'base_price_percent_added'.tr(args: [price, percent]);
  static String percentOffN(int n) => 'percent_off'.tr(args: [n.toString()]);

  // Reviews
  static String get writeReview => 'write_review'.tr();
  static String get yourReview => 'your_review'.tr();
  static String get comment => 'comment'.tr();
  static String get commentHint => 'comment_hint'.tr();
  static String get submitReview => 'submit_review'.tr();
  static String get editReview => 'edit_review'.tr();
  static String get deleteReview => 'delete_review'.tr();
  static String get reviewSubmitted => 'review_submitted'.tr();
  static String get reviewUpdated => 'review_updated'.tr();
  static String get reviewDeleted => 'review_deleted'.tr();
  static String get areYouSureDeleteReview => 'are_you_sure_delete_review'.tr();
  static String get pleaseSelectRating => 'please_select_rating'.tr();
  static String get pleaseEnterComment => 'please_enter_comment'.tr();

  // Auth
  static String get login => 'login'.tr();
  static String get register => 'register'.tr();
  static String get email => 'email'.tr();
  static String get password => 'password'.tr();
  static String get searchResults => 'search_results'.tr();
  static String get noResultsFound => 'no_results_found'.tr();
  static String get startSearching => 'start_searching'.tr();

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
  static String get pleaseEnterAddress => 'please_enter_address'.tr();
  static String get restaurantName => 'restaurant_name'.tr();
  static String get enterRestaurantName => 'enter_restaurant_name'.tr();
  static String get pleaseEnterRestaurantName =>
      'please_enter_restaurant_name'.tr();
  static String get selectCountry => 'select_country'.tr();
  static String get selectCity => 'select_city'.tr();
  static String get notificationChannel => 'notification_channel'.tr();
  static String get verifyAccountMethodTitle =>
      'verify_account_method_title'.tr();
  static String get verifyEmailOtp => 'verify_email_otp'.tr();
  static String get verifyWhatsAppOtp => 'verify_whatsapp_otp'.tr();
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
  static String get sessionExpired => 'session_expired'.tr();
  static String get pleaseEnterEmail => 'please_enter_email'.tr();
  static String get pleaseEnterPassword => 'please_enter_password'.tr();
  static String get pleaseSelectCountry => 'please_select_country'.tr();
  static String get pleaseSelectCity => 'please_select_city'.tr();
  static String get registerSuccess => 'register_success'.tr();
  static String get pleaseEnterOtp => 'please_enter_otp'.tr();
  static String get sendOtp => 'send_otp'.tr();
  static String get passwordsDoNotMatch => 'passwords_do_not_match'.tr();
  static String get customer => 'customer'.tr();
  static String get delivery => 'delivery'.tr();

  // Filters
  static String get filters => 'filters'.tr();
  static String get minPrice => 'min_price'.tr();
  static String get maxPrice => 'max_price'.tr();
  static String get minPriceHint => 'min_price_hint'.tr();
  static String get maxPriceHint => 'max_price_hint'.tr();
  static String get minRating => 'min_rating'.tr();
  static String get apply => 'apply'.tr();
  static String get reset => 'reset'.tr();
  static String get allCategories => 'all_categories'.tr();

  static String get birthday => 'birthday'.tr();
  static String get birthdayHint => 'birthday_hint'.tr();
  static String get joinAsDelivery => 'join_as_delivery'.tr();
  static String get deliveryRegisterDialogText =>
      'delivery_register_dialog_text'.tr();
  static String get contactManagement => 'contact_management'.tr();
  static String get registerManually => 'register_manually'.tr();
  static String get deliveryWaitingTitle => 'delivery_waiting_title'.tr();
  static String get deliveryWaitingSubtitle => 'delivery_waiting_subtitle'.tr();
  static String get refreshPage => 'refresh_page'.tr();
  static String get deliveryPendingToast => 'delivery_pending_toast'.tr();
  static String get whatsappNotAvailable => 'whatsapp_not_available'.tr();
  static String get profileUpdatedSuccess => 'profile_updated_success'.tr();
  static String get logoutSuccess => 'logout_success'.tr();
  static String get logoutError => 'logout_error'.tr();
  static String get areYouSureLogout => 'are_you_sure_logout'.tr();
  static String get forgotPasswordDescription =>
      'forgot_password_description'.tr();
  static String get pleaseSelectCountryFirst =>
      'please_select_country_first'.tr();
  static String get noCitiesAvailable => 'no_cities_available'.tr();

  // Merchant
  static String get merchants => 'merchants'.tr();
  static String get merchantDetails => 'merchant_details'.tr();
  static String get noMerchantsFound => 'no_merchants_found'.tr();
  static String get searchMerchants => 'search_merchants'.tr();
  static String get searchMerchantsHint => 'search_merchants_hint'.tr();
  static String get searchHintRestaurants => 'search_hint_restaurants'.tr();
  static String get searchHintFavoriteFood => 'search_hint_favorite_food'.tr();
  static String get searchHintOffers => 'search_hint_offers'.tr();
  static String get location => 'location'.tr();
  static String get useMyLocation => 'use_my_location'.tr();
  static String get pleaseSelectLocation => 'please_select_location'.tr();
  static String get locationSetFormat => 'location_set_format'.tr();
  static String get pleaseSelectCountryOrLocation =>
      'please_select_country_or_location'.tr();
  static String get locationPermissionDenied =>
      'location_permission_denied'.tr();
  static String get locationPermissionEnableInSettings =>
      'location_permission_enable_in_settings'.tr();

  // Navigation
  static String get basket => 'basket'.tr();
  static String get myOrders => 'my_orders'.tr();
  static String get basketIsEmpty => 'basket_is_empty'.tr();
  static String get addToCart => 'add_to_cart'.tr();
  static String get addedToCart => 'added_to_cart'.tr();
  static String get total => 'total'.tr();
  static String get quantity => 'quantity'.tr();

  static String get locationUnavailable => 'location_unavailable'.tr();
  static String get chooseLocationOnMap => 'choose_location_on_map'.tr();
  static String get updateLocation => 'update_location'.tr();
  static String get currentLocation => 'current_location'.tr();
  static String get noLocationSet => 'no_location_set'.tr();
  static String get accountStatus => 'account_status'.tr();
  static String get accountActive => 'account_active'.tr();
  static String get accountInactive => 'account_inactive'.tr();
  static String get activateAccount => 'activate_account'.tr();
  static String get deactivateAccount => 'deactivate_account'.tr();

  // Delivery
  static String get deliveryMen => 'delivery_men'.tr();
  static String get deliveryManDetails => 'delivery_man_details'.tr();
  static String get addDeliveryMan => 'add_delivery_man'.tr();
  static String get editDeliveryMan => 'edit_delivery_man'.tr();
  static String get confirmDelivery => 'confirm_delivery'.tr();
  static String get noDeliveryMenFound => 'no_delivery_men_found'.tr();
  static String get vehicleType => 'vehicle_type'.tr();
  static String get status => 'status'.tr();
  static String get online => 'online'.tr();
  static String get offline => 'offline'.tr();
  static String get confirmed => 'confirmed'.tr();
  static String get notConfirmed => 'not_confirmed'.tr();
  static String get searchDeliveryMen => 'search_delivery_men'.tr();
  static String get searchDeliveryMenHint => 'search_delivery_men_hint'.tr();
  static String get deliveryManCreatedSuccessfully =>
      'delivery_man_created_successfully'.tr();
  static String get deliveryManUpdatedSuccessfully =>
      'delivery_man_updated_successfully'.tr();
  static String get deliveryManDeletedSuccessfully =>
      'delivery_man_deleted_successfully'.tr();
  static String get deliveryManConfirmedSuccessfully =>
      'delivery_man_confirmed_successfully'.tr();
  static String get areYouSureDeleteDeliveryMan =>
      'are_you_sure_delete_delivery_man'.tr();
  static String get enterFirstName => 'enter_first_name'.tr();
  static String get enterLastName => 'enter_last_name'.tr();
  static String get pleaseEnterFirstName => 'please_enter_first_name'.tr();
  static String get pleaseEnterLastName => 'please_enter_last_name'.tr();
  static String get pleaseEnterPhone => 'please_enter_phone'.tr();
  static String get passwordMustBeAtLeast6Characters =>
      'password_must_be_at_least_6_characters'.tr();
  static String get selectLanguage => 'select_language'.tr();
  static String get changeLanguage => 'change_language'.tr();
  static String get close => 'close'.tr();
  static String get languageChangedSuccessfully =>
      'language_changed_successfully'.tr();

  // Order
  static String get orders => 'orders'.tr();
  static String get orderDetails => 'order_details'.tr();
  static String get noOrdersFound => 'no_orders_found'.tr();
  static String get searchOrders => 'search_orders'.tr();
  static String get searchOrdersHint => 'search_orders_hint'.tr();
  static String get orderCompletedSuccessfully =>
      'order_completed_successfully'.tr();
  static String get orderCancelledSuccessfully =>
      'order_cancelled_successfully'.tr();
  static String get order => 'order'.tr();
  static String get productsCount => 'products_count'.tr();
  static String get people => 'people'.tr();
  static String get latitude => 'latitude'.tr();
  static String get longitude => 'longitude'.tr();
  static String get numberOfPeople => 'number_of_people'.tr();
  static String get deliveryMan => 'delivery_man'.tr();
  static String get areYouSureCompleteOrder =>
      'are_you_sure_complete_order'.tr();
  static String get areYouSureCancelOrder => 'are_you_sure_cancel_order'.tr();
  static String get completeOrder => 'complete_order'.tr();
  static String get cancelOrder => 'cancel_order'.tr();

  // Offer
  static String get offers => 'offers'.tr();
  static String get addOffer => 'add_offer'.tr();
  static String get editOffer => 'edit_offer'.tr();
  static String get offerDetails => 'offer_details'.tr();
  static String get noOffersFound => 'no_offers_found'.tr();
  static String get offerShortDescription => 'offer_short_description'.tr();
  static String get offerLongDescription => 'offer_long_description'.tr();
  static String get selectProducts => 'select_products'.tr();
  static String get offerStartDate => 'offer_start_date'.tr();
  static String get offerEndDate => 'offer_end_date'.tr();
  static String get offerDiscountType => 'offer_discount_type'.tr();
  static String get offerDiscountValue => 'offer_discount_value'.tr();
  static String get offerDiscountPercentage => 'offer_discount_percentage'.tr();
  static String get offerDiscountValueType => 'offer_discount_value_type'.tr();
  static String get offerProductsCount => 'offer_products_count'.tr();
  static String get offerDiscount => 'offer_discount'.tr();
  static String get offerCreatedSuccessfully =>
      'offer_created_successfully'.tr();
  static String get offerUpdatedSuccessfully =>
      'offer_updated_successfully'.tr();
  static String get offerDeletedSuccessfully =>
      'offer_deleted_successfully'.tr();
  static String get areYouSureDeleteOffer => 'are_you_sure_delete_offer'.tr();
  static String get selectDate => 'select_date'.tr();
  static String get showAll => 'show_all'.tr();
  static String get backToLogin => 'back_to_login'.tr();
  static String productsCountN(int n) =>
      'products_count_n'.tr(args: [n.toString()]);
  static String amountOffN(String value) => 'amount_off'.tr(args: [value]);

  static String get favorites => 'favorites'.tr();
  static String get noFavoritesFound => 'no_favorites_found'.tr();
}
