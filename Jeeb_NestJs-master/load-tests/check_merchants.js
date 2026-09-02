const { Pool } = require('pg');
const pool = new Pool({
  host: 'localhost', port: 5432,
  user: 'jeeb_dev_user', password: 'StrongPassword123Dev',
  database: 'jeeb_db_dev'
});

pool.query(`SELECT * FROM products LIMIT 20`, (err, res) => {
  if (err) console.log('Error:', err.message);
  else console.log(JSON.stringify(res.rows, null, 2));
  pool.end();
});
