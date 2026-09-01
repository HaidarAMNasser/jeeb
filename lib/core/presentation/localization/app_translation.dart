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
  static String get call => 'call'.tr();
  static String get phoneCopied => 'phone_copied'.tr();
  static String get copyPhone => 'copy_phone'.tr();
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
  static String get changePasswordTitle => 'change_password_title'.tr();
  static String get oldPassword => 'old_password'.tr();
  static String get confirmNewPassword => 'confirm_new_password'.tr();
  static String get enterAsGuest => 'enter_as_guest'.tr();
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
  static String get filterMerchantType => 'filter_merchant_type'.tr();
  static String get filterMerchantTypeRestaurant =>
      'filter_merchant_type_restaurant'.tr();
  static String get filterMerchantTypeStore =>
      'filter_merchant_type_store'.tr();

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
  static String get deleteAccount => 'delete_account'.tr();
  static String get deleteAccountSuccess => 'delete_account_success'.tr();
  static String get deleteAccountError => 'delete_account_error'.tr();
  static String get areYouSureDeleteAccount =>
      'are_you_sure_delete_account'.tr();
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
  static String get createOrder => 'create_order'.tr();
  static String get confirmOrder => 'confirm_order'.tr();

  // Order status tracking screen (`OrderStatusPage` — keys in en.json / ar.json)
  static String get orderStatusTrackingTitle =>
      'order_status_tracking_title'.tr();
  static String get orderStatusTrackingSubtitle =>
      'order_status_tracking_subtitle'.tr();
  static String get orderStatusProblemBanner =>
      'order_status_problem_banner'.tr();
  static String get orderStatusPendingFriendly =>
      'order_status_pending_friendly'.tr();

  /// API [OrderStatus] short labels (lists, badges, `OrderStatus.displayLabel`).
  static String get orderStatusLabelConfirmed =>
      'order_status_label_confirmed'.tr();
  static String get orderStatusLabelSearching =>
      'order_status_label_searching'.tr();
  static String get orderStatusLabelPreparing =>
      'order_status_label_preparing'.tr();
  static String get orderStatusLabelReadyForPickup =>
      'order_status_label_ready_for_pickup'.tr();
  static String get orderStatusLabelAssigned =>
      'order_status_label_assigned'.tr();
  static String get orderStatusLabelPickedUp =>
      'order_status_label_picked_up'.tr();
  static String get orderStatusLabelOnTheWay =>
      'order_status_label_on_the_way'.tr();
  static String get orderStatusLabelDelivered =>
      'order_status_label_delivered'.tr();
  static String get orderStatusLabelPaid => 'order_status_label_paid'.tr();
  static String get orderStatusLabelCompleted =>
      'order_status_label_completed'.tr();
  static String get orderStatusLabelCancelled =>
      'order_status_label_cancelled'.tr();
  static String get orderStatusLabelRejected =>
      'order_status_label_rejected'.tr();
  static String get orderStatusLabelUnknown =>
      'order_status_label_unknown'.tr();

  /// Delivery app — badge copy for mediator payment lifecycle (listing + details only).
  static String get deliveryPayStatusDeliveredNotPaid =>
      'delivery_pay_status_delivered_not_paid'.tr();
  static String get deliveryPayStatusPaidPending =>
      'delivery_pay_status_paid_pending'.tr();
  static String get deliveryPayStatusCompletedPaid =>
      'delivery_pay_status_completed_paid'.tr();

  static String get payAdminMenuTitle => 'pay_admin_menu_title'.tr();
  static String get payAdminOptionPayNow => 'pay_admin_option_pay_now'.tr();
  static String get payAdminOptionAddToList => 'pay_admin_option_add_to_list'.tr();
  static String get payAdminDialogInstructions => 'pay_admin_dialog_instructions'.tr();
  static String get payAdminTotalLabel => 'pay_admin_total_label'.tr();
  static String get payAdminSubmit => 'pay_admin_submit'.tr();
  static String get payAdminSuccess => 'pay_admin_success'.tr();
  static String get payAdminFailure => 'pay_admin_failure'.tr();
  static String get payAdminPickReceipt => 'pay_admin_pick_receipt'.tr();
  static String get payAppBarPay => 'pay_app_bar_pay'.tr();

  static String get orderStepPlaced => 'order_step_placed'.tr();
  static String get orderStepConfirmed => 'order_step_confirmed'.tr();
  static String get orderStepSearching => 'order_step_searching'.tr();
  static String get orderStepPreparing => 'order_step_preparing'.tr();
  static String get orderStepReady => 'order_step_ready'.tr();
  static String get orderStepWithDriver => 'order_step_with_driver'.tr();
  static String get orderStepOnTheWay => 'order_step_on_the_way'.tr();
  static String get orderStepDelivered => 'order_step_delivered'.tr();
  static String get orderStepAssigned => 'order_step_assigned'.tr();
  static String get orderStepPickedUpTimeline => 'order_step_picked_up_timeline'.tr();

  /// Tracking screen — one-line explanation under the status title.
  static String get orderTrackHintPending => 'order_track_hint_pending'.tr();
  static String get orderTrackHintConfirmed => 'order_track_hint_confirmed'.tr();
  static String get orderTrackHintSearching => 'order_track_hint_searching'.tr();
  static String get orderTrackHintAssigned => 'order_track_hint_assigned'.tr();
  static String orderTrackHintAssignedCourier(String name, String phone) =>
      'order_track_hint_assigned_courier'.tr(
        namedArgs: {'name': name, 'phone': phone.isEmpty ? '—' : phone},
      );
  static String get orderTrackHintPreparing => 'order_track_hint_preparing'.tr();
  static String get orderTrackHintReadyForPickup =>
      'order_track_hint_ready_for_pickup'.tr();
  static String get orderTrackHintPickedUp => 'order_track_hint_picked_up'.tr();
  static String get orderTrackHintOnTheWay => 'order_track_hint_on_the_way'.tr();
  static String get orderTrackHintDelivered => 'order_track_hint_delivered'.tr();
  static String get orderTrackHintPaid => 'order_track_hint_paid'.tr();
  static String get orderTrackHintCompleted =>
      'order_track_hint_completed'.tr();
  static String get orderTrackHintCancelled => 'order_track_hint_cancelled'.tr();
  static String get orderTrackHintRejected => 'order_track_hint_rejected'.tr();
  static String get orderTrackHintUnknown => 'order_track_hint_unknown'.tr();

  static String get orderStatusViewDetails => 'order_status_view_details'.tr();
  static String get orderStatusDriverCardTitle =>
      'order_status_driver_card_title'.tr();
  static String get orderStatusDriverCall => 'order_status_driver_call'.tr();
  static String get orderStatusSupportNumberLabel =>
      'order_status_support_number_label'.tr();
  static String get orderStatusSupportCall => 'order_status_support_call'.tr();
  static String get orderStatusDemoStart => 'order_status_demo_start'.tr();
  static String get orderStatusDemoStop => 'order_status_demo_stop'.tr();
  static String get orderNumberLabel => 'order_number_label'.tr();
  static String get orderOwnerRequired => 'order_owner_required'.tr();
  static String get orderItemsInvalid => 'order_items_invalid'.tr();
  static String get payOnDelivery => 'pay_on_delivery'.tr();
  static String get orderPreviewTitle => 'order_preview_title'.tr();
  static String get orderPreviewRestaurant => 'order_preview_restaurant'.tr();
  static String get orderPreviewDistanceM => 'order_preview_distance_m'.tr();
  static String get orderPreviewDistanceKm => 'order_preview_distance_km'.tr();
  static String get orderPreviewPricePerKm => 'order_preview_price_per_km'.tr();
  static String get orderPreviewCommissionRate =>
      'order_preview_commission_rate'.tr();
  static String get orderPreviewDeliveryCost =>
      'order_preview_delivery_cost'.tr();
  static String get orderPreviewMediatorCommission =>
      'order_preview_mediator_commission'.tr();
  static String get orderPreviewGrandTotal => 'order_preview_grand_total'.tr();
  static String get orderPreviewDestination => 'order_preview_destination'.tr();
  static String get orderPreviewPricedItems =>
      'order_preview_priced_items'.tr();
  static String get selectedLocation => 'selected_location'.tr();
  static String get country => 'country'.tr();
  static String get city => 'city'.tr();
  static String get street => 'street'.tr();
  static String get addressDetails => 'address_details'.tr();
  static String get fullName => 'full_name'.tr();
  static String get enterFullName => 'enter_full_name'.tr();
  static String get pleaseEnterFullName => 'please_enter_full_name'.tr();
  static String get pleaseEnterStreet => 'please_enter_street'.tr();
  static String get basketConfirmWaitAddress =>
      'basket_confirm_wait_address'.tr();

  static String get pleaseEnterAddressDetails =>
      'please_enter_address_details'.tr();

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

  static String get deliveryDashboard => 'delivery_dashboard'.tr();
  static String get hello => 'hello'.tr();
  static String get partner => 'partner'.tr();
  static String get activeOrders => 'active_orders'.tr();
  static String get noActiveOrders => 'no_active_orders'.tr();
  static String get pickUpPoint => 'pick_up_point'.tr();
  static String get orderItems => 'order_items'.tr();
  static String moreItemsN(int n) => 'more_items'.tr(args: [n.toString()]);
  static String get deliveryPrice => 'delivery_price'.tr();
  static String get deliveryEarning => 'delivery_earning'.tr();
  static String get orderItemsTotal => 'order_items_total'.tr();
  static String get orderOffersTotal => 'order_offers_total'.tr();
  static String get orderSubtotal => 'order_subtotal'.tr();
  static String get preparationTime => 'preparation_time'.tr();
  /// Backend minutes only (e.g. "46 min") — not a live countdown.
  static String preparationMinutesLabel(int minutes) =>
      'preparation_minutes_label'.tr(args: [minutes.toString()]);
  static String get orderMealPrepRemaining => 'order_meal_prep_remaining'.tr();
  static String get deliveryAcceptTimeLeft => 'delivery_accept_time_left'.tr();
  static String get orderDetailsOffers => 'order_details_offers'.tr();
  static String get orderDetailsItems => 'order_details_items'.tr();
  static String get orderUnitPrice => 'order_unit_price'.tr();
  static String get orderLineTotal => 'order_line_total'.tr();
  static String get orderDiscount => 'order_discount'.tr();
  static String get orderQty => 'order_qty'.tr();
  static String get orderOfferSubtotal => 'order_offer_subtotal'.tr();
  static String get orderOfferDiscount => 'order_offer_discount'.tr();
  static String orderEstimatedDeliveryMinutes(int minutes) =>
      'order_estimated_delivery_minutes'.tr(args: [minutes.toString()]);
  static String get searchPlace => 'search_place'.tr();
  static String get enterLocationName => 'enter_location_name'.tr();
  static String get locationNotFound => 'location_not_found'.tr();
  static String get mapView => 'map_view'.tr();
  static String get myLocation => 'my_location'.tr();
  static String get search => 'search'.tr();
  static String get pending => 'pending'.tr();
  static String get completed => 'completed'.tr();
  static String get cancelled => 'cancelled'.tr();

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
  static String get selectArea => 'select_area'.tr();
  static String get pleaseSelectArea => 'please_select_area'.tr();
  static String get noAreasAvailable => 'no_areas_available'.tr();
  static String get searchAreasHint => 'search_areas_hint'.tr();
  static String get changeLanguage => 'change_language'.tr();
  static String get close => 'close'.tr();
  static String get languageChangedSuccessfully =>
      'language_changed_successfully'.tr();

  // Order
  static String get orders => 'orders'.tr();
  static String get orderDetails => 'order_details'.tr();

  /// Map preview on order details when status is on the way (live tracking later).
  static String get orderDeliveryMapBadge => 'order_delivery_map_badge'.tr();

  /// Delivery map: solid tracked path vs dashed Google driving route.
  static String get deliveryRouteLegendWalked =>
      'delivery_route_legend_walked'.tr();

  /// Demo: simulate driver GPS (dev / QA).
  static String get deliveryFakeGpsStart => 'delivery_fake_gps_start'.tr();
  static String get deliveryFakeGpsStop => 'delivery_fake_gps_stop'.tr();
  static String get deliveryFakeGpsHint => 'delivery_fake_gps_hint'.tr();
  static String get deliveryFakeGpsMapMarker =>
      'delivery_fake_gps_map_marker'.tr();
  static String get deliveryFakeGpsSent => 'delivery_fake_gps_sent'.tr();
  static String get deliveryFakeGpsSendFailed =>
      'delivery_fake_gps_send_failed'.tr();

  /// Opens [Routes.orderStatus] from order details while the order is still active.
  static String get orderTrackOrderCta => 'order_track_order_cta'.tr();
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
  static String get noPendingOrders => 'no_pending_orders'.tr();
  static String get noAssignedOrders => 'no_assigned_orders'.tr();
  static String get noCompletedOrders => 'no_completed_orders'.tr();
  static String get noCancelledOrders => 'no_cancelled_orders'.tr();
  static String get callCustomer => 'call_customer'.tr();
  static String get acceptDelivery => 'accept_delivery'.tr();
  static String get confirmPickup => 'confirm_pickup'.tr();
  static String get rejectDelivery => 'reject_delivery'.tr();
  static String get markAsDelivered => 'mark_as_delivered'.tr();
  static String get markOnTheWay => 'mark_on_the_way'.tr();
  static String get onTheWayDefaultReason => 'on_the_way_default_reason'.tr();
  static String get orderNumber => 'order_number'.tr();
  static String get unableToDeliver => 'unable_to_deliver'.tr();
  static String get pickedUp => 'picked_up'.tr();
  static String get handedToCustomer => 'handed_to_customer'.tr();

  /// Driver enters ETA (minutes) before calling accept-delivery API.
  static String get acceptDeliveryEstimatedTimeTitle =>
      'accept_delivery_estimated_time_title'.tr();
  static String get acceptDeliveryEstimatedTimeLabel =>
      'accept_delivery_estimated_time_label'.tr();
  static String get acceptDeliveryEstimatedTimeHint =>
      'accept_delivery_estimated_time_hint'.tr();
  static String get acceptDeliveryEstimatedTimeEmpty =>
      'accept_delivery_estimated_time_empty'.tr();
  static String acceptDeliveryEstimatedTimeInvalid(int min, int max) =>
      'accept_delivery_estimated_time_invalid'
          .tr(args: [min.toString(), max.toString()]);

  static String get uploadPaymentReceipts => 'upload_payment_receipts'.tr();
  static String get paymentReceiptsSelectHint =>
      'payment_receipts_select_hint'.tr();
  static String get paymentReceiptAddImages => 'payment_receipt_add_images'.tr();
  static String get paymentReceiptSubmit => 'payment_receipt_submit'.tr();
  static String get paymentReceiptInvalidType =>
      'payment_receipt_invalid_type'.tr();
  static String get paymentReceiptFileTooLarge =>
      'payment_receipt_file_too_large'.tr();
  static String get paymentReceiptTooManyImages =>
      'payment_receipt_too_many_images'.tr();
  static String get paymentReceiptNeedOneImage =>
      'payment_receipt_need_one_image'.tr();

  /// [ManageOrderBloc] success snackbars (after accept / pickup / delivered / reject).
  static String get manageOrderSuccessAcceptDelivery =>
      'manage_order_success_accept_delivery'.tr();
  static String get manageOrderSuccessConfirmPickup =>
      'manage_order_success_confirm_pickup'.tr();
  static String get manageOrderSuccessMarkOnTheWay =>
      'manage_order_success_mark_on_the_way'.tr();
  static String get manageOrderSuccessMarkDelivered =>
      'manage_order_success_mark_delivered'.tr();
  static String get manageOrderSuccessMarkPaid =>
      'manage_order_success_mark_paid'.tr();
  static String get manageOrderSuccessRejectDelivery =>
      'manage_order_success_reject_delivery'.tr();
}
