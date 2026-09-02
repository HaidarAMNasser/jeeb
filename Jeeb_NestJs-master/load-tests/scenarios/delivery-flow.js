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

const acceptOrderDuration = new Trend('delivery_accept_duration_ms');
const rejectOrderDuration = new Trend('delivery_reject_duration_ms');
const listSearchingOrdersDuration = new Trend('delivery_list_searching_duration_ms');
const deliverOrderDuration = new Trend('delivery_deliver_duration_ms');
const acceptFailRate = new Rate('delivery_accept_fail_rate');
const rejectFailRate = new Rate('delivery_reject_fail_rate');

export const options = {
  stages: STAGES_100_USERS,
  thresholds: {
    ...THRESHOLDS,
    delivery_accept_duration_ms: ['p(95)<1500', 'p(99)<5000'],
    delivery_reject_duration_ms: ['p(95)<1000', 'p(99)<3000'],
    delivery_list_searching_duration_ms: ['p(95)<800', 'p(99)<2000'],
    delivery_deliver_duration_ms: ['p(95)<1000', 'p(99)<3000'],
    delivery_accept_fail_rate: ['rate<0.10'],
    delivery_reject_fail_rate: ['rate<0.10'],
  },
};

export default function () {
  group('Delivery Flow', () => {
    const deliveryToken = login('loadtest.delivery1@jeeb.com', 'password');
    if (!deliveryToken) {
      acceptFailRate.add(1);
      return;
    }
    const authHeaders = {
      ...DEFAULT_HEADERS,
      Authorization: `Bearer ${deliveryToken}`,
    };

    group('List Searching Orders', () => {
      const res = http.get(`${BASE_URL}/orders?status=searching`, {
        headers: authHeaders,
      });

      listSearchingOrdersDuration.add(res.timings.duration);

      check(res, {
        'list searching orders status 200': (r) => r.status === 200,
      });
    });

    sleep(0.3);
  });

  sleep(SLEEP_DURATION);
}
