import http from 'k6/http';
import { check, sleep } from 'k6';
import { BASE_URL, DEFAULT_HEADERS, TEST_USERS } from './config/options.js';

export const options = {
  stages: [
    { duration: '5s', target: 2 },
    { duration: '10s', target: 4 },
    { duration: '5s', target: 0 },
  ],
  thresholds: {
    http_req_duration: ['p(95)<2000', 'p(99)<3000'],
    http_req_failed: ['rate<0.01'],
  },
};

export default function () {
  const user = TEST_USERS[__VU % TEST_USERS.length];

  // 1. Login
  const loginRes = http.post(`${BASE_URL}/auth/login`,
    JSON.stringify({ email: user.email, password: user.password }),
    { headers: DEFAULT_HEADERS }
  );
  check(loginRes, {
    'login 200': (r) => r.status === 200,
    'login has token': (r) => r.json('data.access_token') !== undefined,
  });

  if (loginRes.status !== 200) {
    sleep(1);
    return;
  }

  const token = loginRes.json('data.access_token');
  const authHeaders = { ...DEFAULT_HEADERS, Authorization: `Bearer ${token}` };

  // 2. Get profile
  const profileRes = http.get(`${BASE_URL}/auth/profile`, { headers: authHeaders });
  check(profileRes, {
    'profile 200': (r) => r.status === 200,
  });

  // 3. List areas (lightweight GET)
  const areasRes = http.get(`${BASE_URL}/areas?limit=5`, { headers: authHeaders });
  check(areasRes, {
    'areas 200': (r) => r.status === 200,
  });

  sleep(1);
}
