export interface MerchantResponse {
  id: number;
  userId?: number;
  merchantId?: number;
  firstName?: string;
  lastName?: string;
  name?: string;
  email?: string;
  phone?: string;
  role?: string;
  restaurantName?: string;
  isOpen?: boolean;
  description?: string;
  hidePhoneNumber?: boolean;
  isActive?: boolean;
  isOnline?: boolean;
  address?: string;
  city?: any;
  cityId?: number | null;
  country?: any;
  countryId?: number | null;
  notificationChannel?: string;
  verifiedAt?: Date | null;
  createdAt?: Date;
  updatedAt?: Date;
  deletedAt?: Date | null;
  images?: any[];
  imageId?: number | null;
  image?: any;
  firebaseToken?: string | null;
  birthday?: Date | null;
  location?: { lat: number; lng: number } | null;
  currentLat?: number | null;
  currentLng?: number | null;
  officeOwnerId?: number | null;
  estimatedDeliveryMinutes?: number | null;
}

export function sanitizeMerchantResponse(
  merchantData: any,
  userData: any,
): MerchantResponse | null {
  if (!merchantData && !userData) return null;

  const shouldHidePhone = merchantData?.hidePhoneNumber === true;

  const mainImage =
    userData?.images && userData.images.length > 0 ? userData.images[0] : null;
  const imageId = mainImage?.id ?? null;

  const response: MerchantResponse = {
    id: merchantData?.userId || userData?.id || 0,
    userId: merchantData?.userId || userData?.id,
    merchantId: merchantData?.id,
    firstName: userData?.firstName,
    lastName: userData?.lastName,
    name: userData
      ? `${userData.firstName || ''} ${userData.lastName || ''}`.trim()
      : merchantData?.restaurantName || '',
    email: userData?.email,
    restaurantName: merchantData?.restaurantName || undefined,
    isOpen: merchantData?.isOpen,
    description: merchantData?.description || undefined,
    hidePhoneNumber: merchantData?.hidePhoneNumber,
    isActive: userData?.isActive,
    isOnline: userData?.isOnline,
    address: userData?.address,
    city: userData?.city,
    cityId: userData?.cityId,
    country: userData?.country,
    countryId: userData?.countryId,
    notificationChannel: userData?.notificationChannel,
    verifiedAt: userData?.verifiedAt,
    createdAt: merchantData?.createdAt || userData?.createdAt,
    updatedAt: merchantData?.updatedAt || userData?.updatedAt,
    deletedAt: userData?.deletedAt,
    images: userData?.images,
    imageId,
    image: mainImage,
    role: userData?.role,
    firebaseToken: userData?.firebaseToken,
    birthday: userData?.birthday,
    location: userData?.location,
    currentLat: userData?.currentLat,
    currentLng: userData?.currentLng,
    officeOwnerId: userData?.officeOwnerId,
    estimatedDeliveryMinutes: merchantData?.estimatedDeliveryMinutes ?? null,
  };

  if (!shouldHidePhone && userData?.phone) {
    response.phone = userData?.phone;
  }

  return response;
}

export function sanitizeMerchantForProduct(
  merchantUserData: any,
  merchantData?: any,
): {
  id: number;
  name?: string;
  phone?: string;
  hidePhoneNumber?: boolean;
} | null {
  if (!merchantUserData) return null;

  const name =
    `${merchantUserData.firstName || ''} ${merchantUserData.lastName || ''}`.trim();
  const shouldHidePhone = merchantData?.hidePhoneNumber === true;

  const response: any = {
    id: merchantData?.id || merchantUserData.id || 0,
    name: name || undefined,
    hidePhoneNumber: merchantData?.hidePhoneNumber,
  };

  if (!shouldHidePhone && merchantUserData.phone) {
    response.phone = merchantUserData.phone;
  }

  return response;
}
