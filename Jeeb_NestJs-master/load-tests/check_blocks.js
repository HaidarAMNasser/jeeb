const { Pool } = require('pg');
const pool = new Pool({
  host: 'localhost', port: 5432,
  user: 'jeeb_dev_user', password: 'StrongPassword123Dev',
  database: 'jeeb_db_dev'
});

const emails = [
  'loadtest.admin@jeeb.com',
  'loadtest.merchant1@jeeb.com',
  'loadtest.customer1@jeeb.com',
  'loadtest.delivery1@jeeb.com'
];

// Deactivate blocks
pool.query(
  `UPDATE login_blocks SET is_active = false, unblocked_at = NOW() WHERE email = ANY($1) AND is_active = true RETURNING id, email`,
  [emails],
  (err, res) => {
    if (err) console.log('Error:', err.message);
    else console.log('Deactivated blocks:', JSON.stringify(res.rows));
    pool.end();
  }
);
