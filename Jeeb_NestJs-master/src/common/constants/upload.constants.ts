export const PAYMENT_RECEIPT_CONFIG = {
  MAX_IMAGES_PER_ORDER: 5,
  MAX_FILE_SIZE: 5 * 1024 * 1024,
  ALLOWED_MIMETYPES: [
    'image/jpeg',
    'image/jpg',
    'image/png',
    'image/gif',
    'image/webp',
  ],
  ALLOWED_EXTENSIONS: ['.jpg', '.jpeg', '.png', '.gif', '.webp'],
  UPLOAD_PATH: 'payment-receipts/',
};

export const DELIVERY_RESTRICTIONS = {
  MAX_INCOMPLETE_ORDERS: 0,
  INCOMPLETE_STATUSES: [
    'PENDING',
    'CONFIRMED',
    'SEARCHING',
    'PREPARING',
    'READY_FOR_PICKUP',
    'ASSIGNED',
    'PICKED_UP',
    'ON_THE_WAY',
    'DELIVERED',
    'PAID',
  ],
  BLOCKED_STATUSES: [
    'PENDING',
    'CONFIRMED',
    'SEARCHING',
    'PREPARING',
    'READY_FOR_PICKUP',
    'ASSIGNED',
    'PICKED_UP',
    'ON_THE_WAY',
    'DELIVERED',
    'PAID',
  ],
};

export const DRIVER_SEARCH_CONFIG = {
  MAX_INCOMPLETE_ORDERS_FOR_SEARCH: 3,
};
