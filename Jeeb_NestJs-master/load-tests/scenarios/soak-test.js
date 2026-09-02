import http from 'k6/http';
import { check, sleep, group } from 'k6';
import { Trend, Rate, Counter } from 'k6/metrics';
import {
  BASE_URL,
  DEFAULT_HEADERS,
  STAGES_100_USERS,
  SLEEP_DURATION,
} from '../config/options.js';
import { login } from '../helpers/setup.js';

const orderCreateDuration = new Trend('soak_order_create_ms');
const orderListDuration = new Trend('soak_order_list_ms');
const profileDuration = new Trend('soak_profile_ms');
const errorRate = new Rate('soak_error_rate');

export const options = {
  stages: [
    { duration: '2m', target: 50 },
    { duration: '10m', target: 50 },
    { duration: '2m', target: 100 },
    { duration: '30m', target: 100 },
    { duration: '2m', target: 0 },
  ],
  thresholds: {
    soak_error_rate: ['rate<0.05'],
    http_req_duration: ['p(95)<1500'],
  },
};

const endpoints = [
  { method: 'GET', path: '/auth/profile', role: 'CUSTOMER' },
  { method: 'GET', path: '/orders?limit=10&page=1', role: 'CUSTOMER' },
  { method: 'GET', path: '/orders/1', role: 'CUSTOMER' },
  { method: 'GET', path: '/orders?limit=10&page=1&status=pending', role: 'MERCHANT' },
];

const LOGIN_CREDENTIALS = {
  ADMIN: { email: 'loadtest.admin@jeeb.com', password: 'password' },
  MERCHANT: { email: 'loadtest.merchant1@jeeb.com', password: 'password' },
  CUSTOMER: { email: 'loadtest.customer1@jeeb.com', password: 'password' },
  DELIVERY: { email: 'loadtest.delivery1@jeeb.com', password: 'password' },
};

export default function () {
  group('Soak Test - Sustained Load', () => {
    for (const ep of endpoints) {
      const creds = LOGIN_CREDENTIALS[ep.role];
      const token = login(creds.email, creds.password);
      if (!token) {
        errorRate.add(1);
        continue;
      }

      const res = http.get(`${BASE_URL}${ep.path}`, {
        headers: { ...DEFAULT_HEADERS, Authorization: `Bearer ${token}` },
      });

      errorRate.add(res.status !== 200);
      check(res, { 'endpoint ok': (r) => r.status === 200 });
      sleep(0.3);
    }
  });

  sleep(SLEEP_DURATION);
}
