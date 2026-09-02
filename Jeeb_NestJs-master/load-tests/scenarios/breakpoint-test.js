import http from 'k6/http';
import { check, sleep, group } from 'k6';
import { Trend, Rate, Counter } from 'k6/metrics';
import { BASE_URL, DEFAULT_HEADERS } from '../config/options.js';
import { login } from '../helpers/setup.js';

const reqDuration = new Trend('breakpoint_request_duration_ms');
const errorRate = new Rate('breakpoint_error_rate');
const successCount = new Counter('breakpoint_success_count');
const failureCount = new Counter('breakpoint_failure_count');

export const options = {
  stages: [
    { duration: '30s', target: 10 },
    { duration: '30s', target: 25 },
    { duration: '30s', target: 50 },
    { duration: '30s', target: 100 },
    { duration: '1m', target: 200 },
    { duration: '1m', target: 500 },
    { duration: '30s', target: 1000 },
    { duration: '30s', target: 0 },
  ],
  thresholds: {
    breakpoint_error_rate: [
      { threshold: 'rate<0.90', abortOnFail: false },
    ],
  },
};

export default function () {
  group('Breakpoint Test', () => {
    const token = login('loadtest.customer1@jeeb.com', 'password');
    if (!token) {
      errorRate.add(1);
      failureCount.add(1);
      return;
    }

    const authHeaders = {
      ...DEFAULT_HEADERS,
      Authorization: `Bearer ${token}`,
    };

    group('Order Creation (Heavy)', () => {
      const payload = JSON.stringify({
        ownerId: 5,
        items: [{ productId: 4, quantity: 1 }],
        deliveryCoordinates: {
          latitude: 33.5 + Math.random() * 0.1,
          longitude: 36.27 + Math.random() * 0.1,
        },
        areaId: 2,
        paymentMethod: 'CASH',
      });

      const res = http.post(`${BASE_URL}/orders`, payload, {
        headers: authHeaders,
      });

      reqDuration.add(res.timings.duration);
      errorRate.add(res.status !== 201 && res.status !== 200);

      if (res.status === 201 || res.status === 200) {
        successCount.add(1);
      } else {
        failureCount.add(1);
        console.log('ORDER FAIL: ' + res.status + ' ' + res.body.substring(0, 100));
      }

      check(res, {
        'order created or accepted': (r) => r.status === 201 || r.status === 200,
      });
    });

    sleep(0.1);

    group('Order List + Detail', () => {
      const listRes = http.get(`${BASE_URL}/orders?limit=20`, {
        headers: authHeaders,
      });
      reqDuration.add(listRes.timings.duration);
      errorRate.add(listRes.status !== 200);

      if (listRes.status !== 200) console.log('LIST FAIL: ' + listRes.status + ' ' + listRes.body.substring(0, 100));
      check(listRes, {
        'list orders ok': (r) => r.status === 200,
      });
    });

    sleep(0.1);

    group('Auth Profile', () => {
      const res = http.get(`${BASE_URL}/auth/profile`, {
        headers: authHeaders,
      });
      reqDuration.add(res.timings.duration);
      errorRate.add(res.status !== 200);

      if (res.status !== 200) console.log('PROFILE FAIL: ' + res.status + ' ' + res.body.substring(0, 100));
      check(res, {
        'profile ok': (r) => r.status === 200,
      });
    });
  });

  sleep(0.1);
}
