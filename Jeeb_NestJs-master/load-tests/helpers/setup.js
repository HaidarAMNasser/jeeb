import http from 'k6/http';
import { check } from 'k6';
import { BASE_URL, DEFAULT_HEADERS } from '../config/options.js';

const tokenCache = {};

export function login(email, password) {
  const cacheKey = `${email}:${password}`;
  if (tokenCache[cacheKey]) {
    return tokenCache[cacheKey];
  }

  const payload = JSON.stringify({ email, password });
  const res = http.post(`${BASE_URL}/auth/login`, payload, {
    headers: DEFAULT_HEADERS,
  });

  const success = check(res, {
    'login successful': (r) => r.status === 200,
  });

  if (success) {
    const token = res.json('data.access_token');
    tokenCache[cacheKey] = token;
    return token;
  }
  return null;
}

export function getAuthHeaders(email, password) {
  const token = login(email, password);
  if (!token) return null;
  return {
    ...DEFAULT_HEADERS,
    Authorization: `Bearer ${token}`,
  };
}

export function getProfile(authHeaders) {
  const res = http.get(`${BASE_URL}/auth/profile`, {
    headers: authHeaders,
  });
  return res;
}

export function createOrder(authHeaders, ownerId, productIds) {
  const payload = JSON.stringify({
    ownerId,
    items: [{ productId: (productIds && productIds[0]) || 4, quantity: 1 }],
    deliveryCoordinates: { latitude: 33.5138, longitude: 36.2765 },
    areaId: 2,
    paymentMethod: 'CASH',
    note: 'Load test order',
  });

  const res = http.post(`${BASE_URL}/orders`, payload, {
    headers: authHeaders,
  });

  check(res, {
    'order created': (r) => r.status === 201 || r.status === 200,
  });

  return res;
}

export function confirmOrder(authHeaders, orderId) {
  const payload = JSON.stringify({
    status: 'confirm',
    mealPreparationTime: 15,
    deliveryTime: 25,
  });

  const res = http.patch(`${BASE_URL}/orders/${orderId}/status`, payload, {
    headers: authHeaders,
  });

  return res;
}

export function updateOrderStatus(authHeaders, orderId, status) {
  const payload = JSON.stringify({ status });
  const res = http.patch(`${BASE_URL}/orders/${orderId}/status`, payload, {
    headers: authHeaders,
  });
  return res;
}

export function getOrders(authHeaders, params = {}) {
  const query = Object.entries(params)
    .map(([k, v]) => `${encodeURIComponent(k)}=${encodeURIComponent(v)}`)
    .join('&');
  const url = `${BASE_URL}/orders${query ? '?' + query : ''}`;
  const res = http.get(url, { headers: authHeaders });
  return res;
}

export function getOrderById(authHeaders, orderId) {
  const res = http.get(`${BASE_URL}/orders/${orderId}`, {
    headers: authHeaders,
  });
  return res;
}
