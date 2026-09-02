export const API_PREFIX = 'api';
export const API_VERSION = 'v1';

export const AUTH_ROUTES = {
  BASE: 'auth',
  REGISTER: 'register',
  LOGIN: 'login',
  VERIFY: 'verify',
  RESEND_OTP: 'resend-otp',
  FORGOT_PASSWORD: 'forgot-password',
  RESET_PASSWORD: 'reset-password',
  LOGOUT: 'logout',
  PROFILE: 'profile',
  FIREBASE_TOKEN: 'firebase-token',
  CUSTOMER_INIT: 'register/customer/init',
  CUSTOMER_VERIFY_PHONE: 'register/customer/verify-phone',
  CUSTOMER_REGISTER: 'register/customer',
};

export const ADMIN_AUTH_ROUTES = {
  BASE: 'admin/auth',
  CREATE_USER: 'create-user', // For creating Admins/Merchants
};

export const PRODUCTS_ROUTES = {
  BASE: 'products',
  GET_ONE: ':id',
  UPDATE: ':id',
  DELETE: ':id',
  DELETE_IMAGE: 'images/:imageId',
};

export const OFFERS_ROUTES = {
  BASE: 'offers',
  GET_ONE: ':id',
  UPDATE: ':id',
  DELETE: ':id',
};

export const CATEGORIES_ROUTES = {
  BASE: 'categories',
  GET_ONE: ':id',
  UPDATE: ':id',
  DELETE: ':id',
};

export const REVIEWS_ROUTES = {
  BASE: 'reviews',
  GET_ONE: ':id',
  UPDATE: ':id',
  DELETE: ':id',
  BY_PRODUCT: 'product/:productId',
  BY_DRIVER: 'driver/:driverId',
  BY_MERCHANT: 'merchant/:merchantId',
};

export const USERS_ROUTES = {
  BASE: 'users',
  SEARCH: 'search',
  CUSTOMER: 'customer',
  CUSTOMERS: 'customers',
  CUSTOMER_BY_ID: 'customers/:id',
  MERCHANT: 'merchant',
  MERCHANTS: 'merchants',
  MERCHANT_BY_ID: 'merchants/:id',
  MERCHANT_CONFIRM: 'merchants/:id/confirm',
  MERCHANT_RESET_PASSWORD: 'merchants/:id/reset-password',
  DELIVERY: 'delivery',
  DELIVERIES: 'deliveries',
  DELIVERY_BY_ID: 'deliveries/:id',
  DELIVERY_CONFIRM: 'deliveries/:id/confirm',
  DELIVERY_RESET_PASSWORD: 'deliveries/:id/reset-password',
  OFFICE_OWNER: 'office-owner',
  OFFICE_OWNERS: 'office-owners',
  OFFICE_OWNER_BY_ID: 'office-owners/:id',
  FIREBASE_TOKEN: 'firebase-token',
};

export const ORDERS_ROUTES = {
  BASE: 'orders',
  GET_ONE: ':id',
  CONFIRM: ':id/confirm',
  PREPARING: ':id/preparing',
  READY_FOR_PICKUP: ':id/ready-for-pickup',
  PICKED_UP: ':id/picked-up',
  ON_THE_WAY: ':id/on-the-way',
  DELIVERED: ':id/delivered',
  PENDING: ':id/pending',
  CANCEL: ':id/cancel',
  REJECT: ':id/reject',
  ACCEPT_DELIVERY: ':id/accept-delivery',
  REJECT_DELIVERY: ':id/reject-delivery',
  SEND_NOTIFICATIONS: ':id/send-delivery-notifications',
  UPDATE: ':id',
  PAID: 'paid',
  COMPLETE: ':id/complete',
  UNASSIGN_DRIVER: ':id/unassign-driver',
};

export const CITIES_ROUTES = {
  BASE: 'cities',
  GET_ONE: ':id',
};

export const COUNTRIES_ROUTES = {
  BASE: 'countries',
  GET_ONE: ':id',
};

export const SETTINGS_ROUTES = {
  BASE: 'settings',
  BY_ID: ':id',
};

export const LOCATION_ROUTES = {
  BASE: 'location',
  COUNTRIES: 'countries',
  CITIES: 'countries/:countryId/cities',
  UPDATE: 'update',
  DRIVER_LOCATION: ':driverId',
};

export const COUPONS_ROUTES = {
  BASE: 'coupons',
  VALIDATE: 'validate',
};

export const DISCOUNTS_ROUTES = {
  BASE: 'discounts',
  APPLICABLE: 'applicable',
};

export const FAVORITES_ROUTES = {
  BASE: 'favorites',
  TOGGLE: 'toggle',
};

export const GLOBAL_SEARCH_ROUTES = {
  BASE: 'search',
};

export const NOTIFICATIONS_ROUTES = {
  BASE: 'notifications',
  SEND_TO_USER: 'send-to-user',
  SEND_TO_ALL: 'send-to-all',
  SEND_TO_CUSTOMERS: 'send-to-customers',
  MARK_READ: 'mark-read',
  GET_ONE: ':id',
};

export const DISTANCE_ROUTES = {
  BASE: 'distance',
  CALCULATE: 'calculate',
  CALCULATE_DELIVERY_COST: 'calculate-delivery-cost',
};

export const TRACKING_ROUTES = {
  BASE: 'tracking',
  UPDATE_LOCATION: 'update-location',
};

export const STATISTICS_ROUTES = {
  BASE: 'statistics',
  MERCHANTS: 'merchants',
};

export const AREAS_ROUTES = {
  BASE: 'areas',
  GET_ONE: ':id',
  UPDATE: ':id',
  DELETE: ':id',
};
