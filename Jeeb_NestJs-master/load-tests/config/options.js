export const BASE_URL = __ENV.K6_BASE_URL || 'http://localhost:3000/api/v1';

export const DEFAULT_HEADERS = {
  'Content-Type': 'application/json',
  'Accept': 'application/json',
};

export const STAGES_100_USERS = [
  { duration: '30s', target: 10 },
  { duration: '1m', target: 50 },
  { duration: '2m', target: 100 },
  { duration: '1m', target: 100 },
  { duration: '30s', target: 0 },
];

export const STAGES_BREAKPOINT = [
  { duration: '1m', target: 10 },
  { duration: '1m', target: 50 },
  { duration: '1m', target: 100 },
  { duration: '1m', target: 200 },
  { duration: '1m', target: 500 },
  { duration: '30s', target: 0 },
];

export const THRESHOLDS = {
  http_req_duration: ['p(95)<500', 'p(99)<2000'],
  http_req_failed: ['rate<0.01'],
  checks: ['rate>0.99'],
};

export const SLEEP_DURATION = '0.5';

export const TEST_USERS = [
  { email: 'loadtest.admin@jeeb.com', password: 'password', role: 'ADMIN' },
  { email: 'loadtest.merchant1@jeeb.com', password: 'password', role: 'MERCHANT' },
  { email: 'loadtest.customer1@jeeb.com', password: 'password', role: 'CUSTOMER' },
  { email: 'loadtest.delivery1@jeeb.com', password: 'password', role: 'DELIVERY' },
];
