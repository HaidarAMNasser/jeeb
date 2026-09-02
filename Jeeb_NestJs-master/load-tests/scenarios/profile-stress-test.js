import http from 'k6/http';
import { check, sleep } from 'k6';
import { Trend, Rate } from 'k6/metrics';
import { BASE_URL, DEFAULT_HEADERS } from '../config/options.js';

const profileDuration = new Trend('profile_duration_ms');
const profileFailRate = new Rate('profile_fail_rate');

export const options = {
  stages: [
    { duration: '10s', target: 5 },
    { duration: '15s', target: 15 },
    { duration: '10s', target: 20 },
    { duration: '10s', target: 0 },
  ],
  thresholds: {
    profile_duration_ms: ['p(95)<2000', 'p(99)<3000'],
    profile_fail_rate: ['rate<0.05'],
  },
};

const USERS = [
  { email: 'loadtest.admin@jeeb.com', password: 'password', role: 'ADMIN' },
  { email: 'loadtest.merchant1@jeeb.com', password: 'password', role: 'MERCHANT' },
  { email: 'loadtest.customer1@jeeb.com', password: 'password', role: 'CUSTOMER' },
  { email: 'loadtest.delivery1@jeeb.com', password: 'password', role: 'DELIVERY' },
];

export default function () {
  const user = USERS[Math.floor(Math.random() * USERS.length)];

  // Login
  const loginRes = http.post(`${BASE_URL}/auth/login`,
    JSON.stringify({ email: user.email, password: user.password }),
    { headers: DEFAULT_HEADERS }
  );
  const loginOk = check(loginRes, { 'login ok': (r) => r.status === 200 });
  if (!loginOk) {
    profileFailRate.add(1);
    return;
  }

  const token = loginRes.json('data.access_token');
  const authHeaders = { ...DEFAULT_HEADERS, Authorization: `Bearer ${token}` };

  // Profile - measured
  const profileRes = http.get(`${BASE_URL}/auth/profile`, { headers: authHeaders });
  profileDuration.add(profileRes.timings.duration);
  profileFailRate.add(profileRes.status !== 200);

  check(profileRes, {
    'profile 200': (r) => r.status === 200,
    [`profile 200 (${user.role})`]: (r) => r.status === 200,
  });

  if (profileRes.status !== 200) {
    console.log(`PROFILE_FAIL: role=${user.role} status=${profileRes.status} body=${profileRes.body}`);
  }

  sleep(1);
}
