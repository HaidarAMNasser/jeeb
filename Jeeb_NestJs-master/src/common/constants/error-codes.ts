export interface ErrorResponse {
  statusCode: number;
  message: string;
  error?: string;
  details?: Record<string, unknown>;
  timestamp: string;
  path: string;
}

export const ErrorCodes = {
  // ========================================
  // AUTHENTICATION & AUTHORIZATION (1000-1999)
  // ========================================

  // Authentication Errors (1000-1099)
  UNAUTHORIZED: { code: 1001, message: 'Unauthorized - Please login first' },
  INVALID_CREDENTIALS: { code: 1002, message: 'Invalid email or password' },
  TOKEN_EXPIRED: {
    code: 1003,
    message: 'Your session has expired, please login again',
  },
  TOKEN_INVALID: { code: 1004, message: 'Invalid authentication token' },
  ACCOUNT_LOCKED: { code: 1005, message: 'Your account has been locked' },
  ACCOUNT_DISABLED: { code: 1006, message: 'Your account has been disabled' },
  EMAIL_NOT_VERIFIED: { code: 1007, message: 'Please verify your email first' },
  PHONE_NOT_VERIFIED: {
    code: 1008,
    message: 'Please verify your phone number first',
  },
  ACCOUNT_PERMANENTLY_BLOCKED: {
    code: 1009,
    message:
      'Your account has been permanently blocked. Please contact support.',
  },
  IP_BLOCKED: {
    code: 1010,
    message:
      'Your IP has been blocked due to too many failed attempts. Please try again later.',
  },
  LOGIN_ATTEMPTS_EXCEEDED: {
    code: 1011,
    message:
      'Too many failed login attempts. Your account has been temporarily locked.',
  },

  // OTP Errors (1100-1199)
  OTP_INVALID: { code: 1101, message: 'Invalid OTP code' },
  OTP_EXPIRED: { code: 1102, message: 'OTP code has expired' },
  OTP_ALREADY_USED: { code: 1103, message: 'OTP code has already been used' },
  OTP_NOT_SENT: { code: 1104, message: 'OTP code not sent yet' },
  OTP_MISMATCH: { code: 1105, message: 'OTP codes do not match' },
  OTP_RATE_LIMIT_EXCEEDED: {
    code: 1106,
    message: 'Too many OTP requests, please try again later',
  },
  OTP_VERIFY_ATTEMPTS_EXCEEDED: {
    code: 1107,
    message:
      'Too many failed verification attempts. Please try again later.',
  },

  // Authorization Errors (1200-1299)
  FORBIDDEN: {
    code: 1201,
    message: 'You do not have permission to perform this action',
  },
  ACCESS_DENIED: { code: 1202, message: 'Access denied' },
  ROLE_NOT_ALLOWED: {
    code: 1203,
    message: 'Your role does not allow this action',
  },
  ADMIN_ONLY: {
    code: 1204,
    message: 'This action is only available for administrators',
  },
  MERCHANT_ONLY: {
    code: 1205,
    message: 'This action is only available for merchants',
  },
  DELIVERY_ONLY: {
    code: 1206,
    message: 'This action is only available for delivery drivers',
  },
  CUSTOMER_ONLY: {
    code: 1207,
    message: 'This action is only available for customers',
  },

  // ========================================
  // USER ERRORS (2000-2099)
  // ========================================

  USER_NOT_FOUND: { code: 2001, message: 'User not found' },
  USER_ALREADY_EXISTS: { code: 2002, message: 'User already exists' },
  USER_EMAIL_EXISTS: { code: 2003, message: 'Email already registered' },
  USER_PHONE_EXISTS: { code: 2004, message: 'Phone number already registered' },
  USER_PROFILE_INCOMPLETE: {
    code: 2005,
    message: 'User profile is incomplete',
  },
  USER_CANNOT_SELF_DELETE: {
    code: 2006,
    message: 'You cannot delete your own account',
  },
  USER_FIREBASE_TOKEN_REQUIRED: {
    code: 2007,
    message: 'Firebase token is required',
  },
  USER_FIREBASE_TOKEN_UPDATED: {
    code: 2008,
    message: 'Firebase token updated successfully',
  },
  USER_INVALID_ROLE: { code: 2009, message: 'Invalid user role' },
  ACCOUNT_PENDING: { code: 2010, message: 'Your account is pending review by the administrator' },

  // ========================================
  // ORDER ERRORS (4000-4099)
  // ========================================

  // Order Creation Errors (4000-4049)
  INVALID_RESTAURANT_ID: { code: 4001, message: 'Invalid restaurant ID' },
  RESTAURANT_NOT_FOUND: { code: 4002, message: 'Restaurant not found' },
  RESTAURANT_NOT_AVAILABLE: {
    code: 4003,
    message: 'Restaurant is not available',
  },
  RESTAURANT_CLOSED: { code: 4004, message: 'Restaurant is currently closed' },
  RESTAURANT_OUT_OF_DELIVERY_RANGE: {
    code: 4005,
    message: 'Restaurant is out of delivery range',
  },

  INVALID_PRODUCT_ID: { code: 4011, message: 'Invalid product ID' },
  PRODUCT_NOT_FOUND: { code: 4012, message: 'Product not found' },
  PRODUCT_NOT_AVAILABLE: { code: 4013, message: 'Product is not available' },
  PRODUCT_OUT_OF_STOCK: { code: 4014, message: 'Product is out of stock' },
  INSUFFICIENT_STOCK: { code: 4015, message: 'Insufficient stock for product' },
  PRODUCT_NOT_OWNED_BY_MERCHANT: {
    code: 4016,
    message: 'Product does not belong to this merchant',
  },
  PRODUCT_PRICE_CHANGED: {
    code: 4017,
    message: 'Product price has been updated',
  },
  PRODUCT_DELETED: { code: 4018, message: 'Product has been removed' },

  INVALID_OFFER_ID: { code: 4021, message: 'Invalid offer ID' },
  OFFER_NOT_FOUND: { code: 4022, message: 'Offer not found' },
  OFFER_NOT_ACTIVE: { code: 4023, message: 'Offer is not currently active' },
  OFFER_EXPIRED: { code: 4024, message: 'Offer has expired' },
  OFFER_NOT_OWNED_BY_MERCHANT: {
    code: 4025,
    message: 'Offer does not belong to this merchant',
  },
  OFFER_ALREADY_APPLIED: {
    code: 4026,
    message: 'Offer has already been applied to this order',
  },
  OFFER_MINIMUM_ORDER_NOT_MET: {
    code: 4027,
    message: 'Minimum order amount not met for this offer',
  },

  INVALID_ORDER_ITEMS: { code: 4031, message: 'Invalid order items' },
  EMPTY_ORDER_ITEMS: {
    code: 4032,
    message: 'Order must have at least one item',
  },
  INVALID_QUANTITY: {
    code: 4033,
    message: 'Quantity must be greater than zero',
  },
  OWNER_ID_REQUIRED: { code: 4034, message: 'Owner ID is required' },
  ORDER_TOTAL_ZERO: { code: 4035, message: 'Order total cannot be zero' },

  // Delivery Errors (4050-4099)
  INVALID_DELIVERY_COORDINATES: {
    code: 4051,
    message: 'Delivery coordinates are required',
  },
  INVALID_DELIVERY_ADDRESS: { code: 4052, message: 'Invalid delivery address' },
  INVALID_TIP_AMOUNT: { code: 4053, message: 'Tip amount cannot be negative' },
  DELIVERY_ADDRESS_TOO_FAR: {
    code: 4055,
    message: 'Delivery address is too far from restaurant',
  },
  DELIVERY_NOT_AVAILABLE: {
    code: 4056,
    message: 'Delivery not available for this location',
  },

  INVALID_COUPON: { code: 4061, message: 'Invalid coupon code' },
  COUPON_EXPIRED: { code: 4062, message: 'Coupon has expired' },
  COUPON_NOT_APPLICABLE: {
    code: 4063,
    message: 'Coupon is not applicable for this order',
  },
  COUPON_ALREADY_USED: { code: 4064, message: 'Coupon has already been used' },
  COUPON_LIMIT_REACHED: { code: 4065, message: 'Coupon usage limit reached' },
  COUPON_MINIMUM_AMOUNT_NOT_MET: {
    code: 4066,
    message: 'Minimum order amount not met for this coupon',
  },

  PAYMENT_METHOD_REQUIRED: {
    code: 4071,
    message: 'Payment method is required',
  },
  PAYMENT_METHOD_INVALID: { code: 4072, message: 'Invalid payment method' },
  PAYMENT_FAILED: { code: 4073, message: 'Payment failed, please try again' },
  PAYMENT_CANCELLED: { code: 4074, message: 'Payment was cancelled' },
  PAYMENT_TIMEOUT: { code: 4075, message: 'Payment request timed out' },
  INSUFFICIENT_BALANCE: { code: 4076, message: 'Insufficient wallet balance' },

  // Order Status Errors (4100-4149)
  ORDER_NOT_FOUND: { code: 4101, message: 'Order not found' },
  INVALID_ORDER_ID: { code: 4102, message: 'Invalid order ID' },

  ORDER_ALREADY_CONFIRMED: {
    code: 4103,
    message: 'Order has already been confirmed',
  },
  ORDER_ALREADY_PREPARING: {
    code: 4104,
    message: 'Order is already being prepared',
  },
  ORDER_ALREADY_READY: {
    code: 4105,
    message: 'Order is already ready for pickup',
  },
  ORDER_ALREADY_PICKED_UP: {
    code: 4106,
    message: 'Order has already been picked up',
  },
  ORDER_ALREADY_ON_THE_WAY: {
    code: 4107,
    message: 'Order is already on the way',
  },
  ORDER_ALREADY_DELIVERED: {
    code: 4108,
    message: 'Order has already been delivered',
  },
  ORDER_ALREADY_CANCELLED: {
    code: 4109,
    message: 'Order has already been cancelled',
  },
  ORDER_ALREADY_REJECTED: {
    code: 4110,
    message: 'Order has already been rejected',
  },
  ORDER_SEARCHING_DRIVER: {
    code: 4111,
    message: 'Order is searching for available driver',
  },

  INVALID_STATUS_TRANSITION: {
    code: 4121,
    message: 'Invalid status transition from current status',
  },
  INVALID_ORDER_STATUS_FILTER: {
    code: 4122,
    message:
      'You cannot filter by PAID or COMPLETE status. These orders are shown as DELIVERED.',
  },
  UNAUTHORIZED_STATUS_CHANGE: {
    code: 4122,
    message: 'You are not authorized to change the status',
  },
  CANNOT_CANCEL_ORDER: {
    code: 4123,
    message: 'Order cannot be cancelled at this stage',
  },
  CANNOT_CANCEL_DELIVERED_ORDER: {
    code: 4124,
    message: 'Delivered orders cannot be cancelled',
  },

  // Merchant specific errors (4150-4199)
  MERCHANT_EMAIL_EXISTS: {
    code: 4151,
    message: 'Merchant email already exists',
  },
  MERCHANT_CREATION_FAILED: {
    code: 4152,
    message: 'Failed to create merchant profile',
  },
  MERCHANT_NOT_FOUND: { code: 4153, message: 'Merchant not found' },
  MERCHANT_PROFILE_NOT_FOUND: {
    code: 4154,
    message: 'Merchant profile not found',
  },
  MERCHANT_ALREADY_EXISTS: {
    code: 4155,
    message: 'Merchant profile already exists for this user',
  },
  MERCHANT_CANNOT_UPDATE_COMMISSION: {
    code: 4156,
    message: 'Merchants cannot update commission fields',
  },
  MERCHANT_SHOP_CLOSED: {
    code: 4157,
    message: 'Merchant shop is currently closed',
  },
  MERCHANT_SHOP_NOT_OPEN: {
    code: 4158,
    message: 'Merchant shop is not open at this time',
  },

  // Product Authorization Errors (4200-4249)
  PRODUCT_ACCESS_DENIED: {
    code: 4201,
    message: 'You do not have permission to access this product',
  },
  PRODUCT_UPDATE_DENIED: {
    code: 4202,
    message: 'You can only update your own products',
  },
  PRODUCT_DELETE_DENIED: {
    code: 4203,
    message: 'You can only delete your own products',
  },
  PRODUCT_NOT_OWNED: { code: 4204, message: 'You do not own this product' },

  // ========================================
  // DELIVERY ERRORS (5000-5099)
  // ========================================

  DELIVERY_ORDER_NOT_FOUND: {
    code: 5001,
    message: 'Order not found for delivery assignment',
  },
  DELIVERY_INVALID_STATUS: {
    code: 5002,
    message:
      'Order must be in SEARCHING or READY_FOR_PICKUP status to assign delivery',
  },
  DELIVERY_NO_DRIVERS_FOUND: {
    code: 5003,
    message: 'No available drivers found nearby',
  },
  DELIVERY_NO_DRIVERS_IN_RANGE: {
    code: 5004,
    message: 'No drivers available within delivery range',
  },
  DELIVERY_ALREADY_ASSIGNED: {
    code: 5005,
    message: 'Order already has active delivery assignment',
  },
  DELIVERY_DRIVER_NOT_FOUND: {
    code: 5006,
    message: 'Delivery driver not found',
  },
  DELIVERY_DRIVER_NOT_AVAILABLE: {
    code: 5007,
    message: 'Delivery driver is not available',
  },
  DELIVERY_DRIVER_BUSY: {
    code: 5008,
    message: 'Delivery driver is currently busy with another order',
  },
  DELIVERY_TIMEOUT_EXPIRED: {
    code: 5009,
    message: 'Delivery assignment timeout has expired',
  },
  DELIVERY_ALREADY_ACCEPTED: {
    code: 5010,
    message: 'Delivery assignment already accepted',
  },
  DELIVERY_ALREADY_REJECTED: {
    code: 5011,
    message: 'Delivery assignment already rejected',
  },
  DELIVERY_CANNOT_ACCEPT: {
    code: 5012,
    message: 'You cannot accept this delivery at this time',
  },
  DELIVERY_CANNOT_REJECT: {
    code: 5013,
    message: 'You cannot reject this delivery at this time',
  },
  DELIVERY_SEARCH_FAILED: {
    code: 5014,
    message: 'Failed to search for available drivers',
  },
  DELIVERY_NOTIFICATION_FAILED: {
    code: 5015,
    message: 'Failed to notify drivers about new delivery',
  },
  DELIVERY_ALL_DRIVERS_NOTIFIED: {
    code: 5016,
    message: 'All available drivers have been notified',
  },

  // ========================================
  // NOTIFICATION ERRORS (5100-5199)
  // ========================================

  NOTIFICATION_FAILED: { code: 5101, message: 'Failed to send notification' },
  NOTIFICATION_FIREBASE_ERROR: {
    code: 5102,
    message: 'Firebase notification service error',
  },
  NOTIFICATION_FIREBASE_TOKEN_INVALID: {
    code: 5103,
    message: 'Invalid Firebase token',
  },
  NOTIFICATION_FIREBASE_TOKEN_MISSING: {
    code: 5104,
    message: 'Firebase token is missing for user',
  },
  NOTIFICATION_EMAIL_ERROR: {
    code: 5105,
    message: 'Failed to send email notification',
  },
  NOTIFICATION_WHATSAPP_ERROR: {
    code: 5106,
    message: 'Failed to send WhatsApp notification',
  },
  NOTIFICATION_SMS_ERROR: {
    code: 5107,
    message: 'Failed to send SMS notification',
  },
  NOTIFICATION_CHANNEL_INVALID: {
    code: 5108,
    message: 'Invalid notification channel',
  },
  NOTIFICATION_CHANNEL_NOT_CONFIGURED: {
    code: 5109,
    message: 'Notification channel is not configured',
  },
  NOTIFICATION_TOPIC_INVALID: {
    code: 5110,
    message: 'Invalid notification topic',
  },
  NOTIFICATION_TYPE_INVALID: {
    code: 5111,
    message: 'Invalid notification type',
  },
  NOTIFICATION_RECIPIENT_NOT_FOUND: {
    code: 5112,
    message: 'Notification recipient not found',
  },
  NOTIFICATION_ALREADY_READ: {
    code: 5113,
    message: 'Notification is already marked as read',
  },
  NOTIFICATION_MARK_READ_FAILED: {
    code: 5114,
    message: 'Failed to mark notifications as read',
  },
  NOTIFICATION_TITLE_REQUIRED: {
    code: 5115,
    message: 'Notification title is required',
  },
  NOTIFICATION_BODY_REQUIRED: {
    code: 5116,
    message: 'Notification body is required',
  },
  NOTIFICATION_USER_NOT_FOUND: {
    code: 5117,
    message: 'User not found for notification',
  },

  // ========================================
  // DRIVER LOCATOR ERRORS (5200-5299)
  // ========================================

  DRIVER_LOCATOR_INVALID_COORDINATES: {
    code: 5201,
    message: 'Invalid driver coordinates',
  },
  DRIVER_LOCATOR_FIREBASE_ERROR: {
    code: 5202,
    message: 'Failed to fetch driver locations from Firebase',
  },
  DRIVER_LOCATOR_MOCK_MODE: {
    code: 5203,
    message: 'Driver locator is running in mock mode',
  },
  DRIVER_LOCATOR_LOCATION_NOT_FOUND: {
    code: 5204,
    message: 'Driver location not found',
  },
  DRIVER_LOCATOR_PERMISSION_DENIED: {
    code: 5205,
    message: 'Location permission denied',
  },

  // ========================================
  // ORDER AUTHORIZATION ERRORS (4150-4199) - Legacy aliases
  // ========================================

  CUSTOMER_CANNOT_UPDATE_OTHER_ORDERS: {
    code: 4201,
    message: 'You can only update your own orders',
  },
  MERCHANT_CANNOT_UPDATE_OTHER_RESTAURANT_ORDERS: {
    code: 4202,
    message: 'You can only update your restaurant orders',
  },

  // ========================================
  // LEGACY ALIASES - For backward compatibility
  // ========================================

  OFFER_PRODUCT_NOT_OWNED_BY_MERCHANT: {
    code: 4025,
    message: 'Product in offer does not belong to this merchant',
  },

  // ========================================
  // VALIDATION ERRORS (6000-6099)
  // ========================================

  VALIDATION_ERROR: { code: 6001, message: 'Validation error' },
  INVALID_INPUT: { code: 6002, message: 'Invalid input provided' },
  MISSING_REQUIRED_FIELD: { code: 6003, message: 'Required field is missing' },
  FIELD_TOO_SHORT: { code: 6004, message: 'Field length is too short' },
  FIELD_TOO_LONG: { code: 6005, message: 'Field length is too long' },
  INVALID_FORMAT: { code: 6006, message: 'Invalid format' },
  INVALID_EMAIL: { code: 6007, message: 'Invalid email format' },
  INVALID_PHONE: { code: 6008, message: 'Invalid phone number format' },
  INVALID_URL: { code: 6009, message: 'Invalid URL format' },
  INVALID_DATE: { code: 6010, message: 'Invalid date format' },
  INVALID_NUMBER: { code: 6011, message: 'Invalid number' },
  NUMBER_OUT_OF_RANGE: { code: 6012, message: 'Number is out of valid range' },
  INVALID_ENUM_VALUE: { code: 6013, message: 'Invalid value for enum field' },
  UNSUPPORTED_FILE_TYPE: { code: 6014, message: 'Unsupported file type' },
  FILE_TOO_LARGE: { code: 6015, message: 'File size exceeds maximum allowed' },
  FILE_UPLOAD_FAILED: { code: 6016, message: 'File upload failed' },

  // ========================================
  // RESOURCE ERRORS (7000-7099)
  // ========================================

  RESOURCE_NOT_FOUND: { code: 7001, message: 'Resource not found' },
  RESOURCE_ALREADY_EXISTS: { code: 7002, message: 'Resource already exists' },
  RESOURCE_DELETED: { code: 7003, message: 'Resource has been deleted' },
  RESOURCE_INACTIVE: { code: 7004, message: 'Resource is inactive' },
  RESOURCE_SUSPENDED: { code: 7005, message: 'Resource has been suspended' },

  // Category Errors (7100-7149)
  CATEGORY_NOT_FOUND: { code: 7101, message: 'Category not found' },
  CATEGORY_ALREADY_EXISTS: { code: 7102, message: 'Category already exists' },
  CATEGORY_HAS_PRODUCTS: {
    code: 7103,
    message: 'Cannot delete category with existing products',
  },
  CATEGORY_INVALID: { code: 7104, message: 'Invalid category' },

  // Area Errors (7150-7199)
  AREA_NOT_FOUND: { code: 7151, message: 'Area not found' },
  AREA_INVALID_PRICE_RANGE: {
    code: 7152,
    message: 'min_price must be less than or equal to max_price',
  },

  // City/Country Errors (7200-7249)
  CITY_NOT_FOUND: { code: 7201, message: 'City not found' },
  COUNTRY_NOT_FOUND: { code: 7202, message: 'Country not found' },
  CITY_NOT_DELIVERABLE: {
    code: 7203,
    message: 'Delivery not available to this city',
  },

  // Review Errors (7300-7349)
  REVIEW_NOT_FOUND: { code: 7301, message: 'Review not found' },
  REVIEW_ALREADY_EXISTS: {
    code: 7302,
    message: 'You have already reviewed this order',
  },
  REVIEW_CANNOT_RATE_OWN: {
    code: 7303,
    message: 'You cannot rate your own order',
  },
  REVIEW_ORDER_NOT_DELIVERED: {
    code: 7304,
    message: 'You can only rate delivered orders',
  },

  // ========================================
  // SYSTEM ERRORS (8000-8099)
  // ========================================

  INTERNAL_SERVER_ERROR: { code: 8001, message: 'Internal server error' },
  SERVICE_UNAVAILABLE: {
    code: 8002,
    message: 'Service temporarily unavailable',
  },
  DATABASE_ERROR: { code: 8003, message: 'Database operation failed' },
  REDIS_CONNECTION_ERROR: {
    code: 8004,
    message: 'Cache service connection failed',
  },
  EXTERNAL_API_ERROR: { code: 8005, message: 'External service call failed' },
  THIRD_PARTY_SERVICE_ERROR: {
    code: 8006,
    message: 'Third-party service error',
  },
  MAINTENANCE_MODE: { code: 8007, message: 'System is under maintenance' },
  RATE_LIMIT_EXCEEDED: {
    code: 8008,
    message: 'Rate limit exceeded, please try again later',
  },
  CONCURRENT_OPERATION_DETECTED: {
    code: 8009,
    message: 'Concurrent operation detected, please retry',
  },

  // ========================================
  // FILE & IMAGE ERRORS (9000-9099)
  // ========================================

  IMAGE_NOT_FOUND: { code: 9001, message: 'Image not found' },
  IMAGE_UPLOAD_FAILED: { code: 9002, message: 'Image upload failed' },
  IMAGE_INVALID_FORMAT: { code: 9003, message: 'Invalid image format' },
  IMAGE_TOO_LARGE: {
    code: 9004,
    message: 'Image size exceeds maximum allowed',
  },
  IMAGE_PROCESSING_FAILED: { code: 9005, message: 'Image processing failed' },
  STORAGE_FULL: { code: 9006, message: 'Storage capacity reached' },
} as const;

export type ErrorCodeKey = keyof typeof ErrorCodes;

export function getErrorMessage(
  key: ErrorCodeKey,
  customMessage?: string,
): string {
  if (customMessage) {
    return customMessage;
  }
  return ErrorCodes[key].message;
}

export function createErrorResponse(
  key: ErrorCodeKey,
  statusCode: number,
  customMessage?: string,
  details?: Record<string, unknown>,
): ErrorResponse {
  return {
    statusCode,
    message: getErrorMessage(key, customMessage),
    error: `ERROR_${ErrorCodes[key].code}`,
    details,
    timestamp: new Date().toISOString(),
    path: '',
  };
}
