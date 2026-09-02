import http from 'k6/http';
import { check, sleep, group } from 'k6';
import { Trend, Rate } from 'k6/metrics';
import {
  BASE_URL,
  DEFAULT_HEADERS,
  THRESHOLDS,
  SLEEP_DURATION,
  STAGES_100_USERS,
} from '../config/options.js';
import { login } from '../helpers/setup.js';

const createOrderDuration = new Trend('order_create_duration_ms');
const confirmOrderDuration = new Trend('order_confirm_duration_ms');
const listOrdersDuration = new Trend('order_list_duration_ms');
const getOrderDuration = new Trend('order_get_by_id_duration_ms');
const createOrderFailRate = new Rate('order_create_fail_rate');
const confirmOrderFailRate = new Rate('order_confirm_fail_rate');

export const options = {
  stages: STAGES_100_USERS,
  thresholds: {
    ...THRESHOLDS,
    order_create_duration_ms: ['p(95)<1500', 'p(99)<5000'],
    order_confirm_duration_ms: ['p(95)<1000', 'p(99)<3000'],
    order_list_duration_ms: ['p(95)<800', 'p(99)<2000'],
    order_get_by_id_duration_ms: ['p(95)<500', 'p(99)<1500'],
    order_create_fail_rate: ['rate<0.05'],
    order_confirm_fail_rate: ['rate<0.05'],
  },
};

export default function () {
  group('Order Flow', () => {
    const customerHeaders = login('loadtest.customer1@jeeb.com', 'password');
    if (!customerHeaders) {
      createOrderFailRate.add(1);
      return;
    }
    const authHeaders = {
      ...DEFAULT_HEADERS,
      Authorization: `Bearer ${customerHeaders}`,
    };

    group('Create Order', () => {
      const deliveryCoords = {
        latitude: 33.5 + Math.random() * 0.05,
        longitude: 36.27 + Math.random() * 0.05,
      };

      const payload = JSON.stringify({
        merchantId: 1,
        productIds: [1],
        deliveryCoordinates: deliveryCoords,
        areaId: 1,
        note: 'Load test order - ' + __VU,
      });

      const res = http.post(`${BASE_URL}/orders`, payload, {
        headers: authHeaders,
      });

      createOrderDuration.add(res.timings.duration);
      createOrderFailRate.add(res.status !== 201 && res.status !== 200);

      const orderSuccess = check(res, {
        'create order success': (r) => r.status === 201 || r.status === 200,
        'order has id': (r) => r.json('data.id') !== undefined,
      });

      if (orderSuccess) {
        const orderId = res.json('data.id');

        sleep(0.5);
      }
    });

    sleep(0.3);

    group('List Orders', () => {
      const res = http.get(`${BASE_URL}/orders?limit=10&page=1`, {
        headers: authHeaders,
      });

      listOrdersDuration.add(res.timings.duration);

      check(res, {
        'list orders status 200': (r) => r.status === 200,
        'list orders has data': (r) => r.json('data') !== undefined,
      });
    });

    sleep(0.3);

    group('Get Order By ID', () => {
      const res = http.get(`${BASE_URL}/orders/1`, {
        headers: authHeaders,
      });

      getOrderDuration.add(res.timings.duration);

      check(res, {
        'get order by id status 200': (r) => r.status === 200,
        'order has id': (r) => r.json('data.id') !== undefined,
      });
    });
  });

  sleep(SLEEP_DURATION);
}
