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
import { login, getProfile } from '../helpers/setup.js';

const loginDuration = new Trend('auth_login_duration_ms');
const profileDuration = new Trend('auth_profile_duration_ms');
const loginFailRate = new Rate('auth_login_fail_rate');
const profileFailRate = new Rate('auth_profile_fail_rate');

export const options = {
  stages: STAGES_100_USERS,
  thresholds: {
    ...THRESHOLDS,
    auth_login_duration_ms: ['p(95)<800', 'p(99)<3000'],
    auth_profile_duration_ms: ['p(95)<500', 'p(99)<2000'],
    auth_login_fail_rate: ['rate<0.02'],
    auth_profile_fail_rate: ['rate<0.02'],
  },
};

const TEST_CREDENTIALS = [
  { email: 'loadtest.admin@jeeb.com', password: 'password' },
  { email: 'loadtest.merchant1@jeeb.com', password: 'password' },
  { email: 'loadtest.customer1@jeeb.com', password: 'password' },
  { email: 'loadtest.delivery1@jeeb.com', password: 'password' },
];

export default function () {
  group('Auth Flow', () => {
    const creds = TEST_CREDENTIALS[Math.floor(Math.random() * TEST_CREDENTIALS.length)];

    group('Login', () => {
      const payload = JSON.stringify({
        email: creds.email,
        password: creds.password,
      });
      const res = http.post(`${BASE_URL}/auth/login`, payload, {
        headers: DEFAULT_HEADERS,
      });

      loginDuration.add(res.timings.duration);
      loginFailRate.add(res.status !== 200);

      const success = check(res, {
        'login status 200': (r) => r.status === 200,
        'login has access_token': (r) => r.json('data.access_token') !== undefined,
      });

      if (success) {
        const token = res.json('data.access_token');
        const authHeaders = {
          ...DEFAULT_HEADERS,
          Authorization: `Bearer ${token}`,
        };

        sleep(0.3);

        group('Get Profile', () => {
          const profileRes = http.get(`${BASE_URL}/auth/profile`, {
            headers: authHeaders,
          });

          profileDuration.add(profileRes.timings.duration);
          profileFailRate.add(profileRes.status !== 200);

          check(profileRes, {
            'profile status 200': (r) => r.status === 200,
            'profile has email': (r) => r.json('data.email') !== undefined,
          });
        });
      }
    });
  });

  sleep(SLEEP_DURATION);
}
