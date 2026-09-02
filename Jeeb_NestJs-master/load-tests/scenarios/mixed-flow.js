import http from 'k6/http';
import { check, sleep, group } from 'k6';
import { Trend, Rate } from 'k6/metrics';
import {
  BASE_URL,
  DEFAULT_HEADERS,
  STAGES_100_USERS,
  SLEEP_DURATION,
} from '../config/options.js';
import { login } from '../helpers/setup.js';

const endpointDuration = new Trend('all_endpoints_duration_ms');
const errorRate = new Rate('all_error_rate');

export const options = {
  stages: STAGES_100_USERS,
  thresholds: {
    all_endpoints_duration_ms: ['p(95)<1000', 'p(99)<3000'],
    all_error_rate: ['rate<0.05'],
    http_req_duration: ['p(95)<1000', 'p(99)<3000'],
    http_req_failed: ['rate<0.05'],
  },
};

const ENDPOINTS = [
  { method: 'GET', path: '/auth/profile', role: 'CUSTOMER' },
  { method: 'GET', path: '/orders?limit=10&page=1', role: 'CUSTOMER' },
  { method: 'GET', path: '/orders/1', role: 'CUSTOMER' },
  { method: 'GET', path: '/orders?limit=10&page=1', role: 'MERCHANT' },
  { method: 'GET', path: '/orders?status=searching', role: 'DELIVERY' },
];

const LOGIN_CREDENTIALS = {
  ADMIN: { email: 'loadtest.admin@jeeb.com', password: 'password' },
  MERCHANT: { email: 'loadtest.merchant1@jeeb.com', password: 'password' },
  CUSTOMER: { email: 'loadtest.customer1@jeeb.com', password: 'password' },
  DELIVERY: { email: 'loadtest.delivery1@jeeb.com', password: 'password' },
};

export default function () {
  group('Mixed Flow - All Roles', () => {
    for (const ep of ENDPOINTS) {
      const creds = LOGIN_CREDENTIALS[ep.role];
      const token = login(creds.email, creds.password);
      if (!token) {
        errorRate.add(1);
        continue;
      }

      const authHeaders = {
        ...DEFAULT_HEADERS,
        Authorization: `Bearer ${token}`,
      };

      const res = http.get(`${BASE_URL}${ep.path}`, {
        headers: authHeaders,
      });

      endpointDuration.add(res.timings.duration);
      errorRate.add(res.status !== 200);

      check(res, {
        [`GET ${ep.path} status 200`]: (r) => r.status === 200,
      });

      sleep(0.2);
    }
  });

  sleep(SLEEP_DURATION);
}
