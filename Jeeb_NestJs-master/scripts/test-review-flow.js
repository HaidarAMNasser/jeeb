
const { Client } = require('pg');
const bcrypt = require('bcrypt');
// const fetch = require('node-fetch'); // Native fetch in Node 18+

// Config
const DB_CONFIG = {
  host: 'localhost',
  port: 5432,
  user: 'postgres',
  password: '20012001', // From .env
  database: 'delivery_jeeb_db',
};

const API_URL = 'http://localhost:3001/api/v1';

async function run() {
  const client = new Client(DB_CONFIG);
  await client.connect();

  try {
    console.log('--- Starting Test Flow ---');

    const userEmail = 'reviewer@test.com';
    const userPass = 'password123';
    let token = '';
    let userId = 0;

    // 1. Authenticating (Try Login, if fail, Direct DB Insert)
    console.log('1. Authenticating...');
    const loginRes = await fetch(`${API_URL}/auth/login`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ email: userEmail, password: userPass }),
    });

    if (loginRes.ok) {
      const resBody = await loginRes.json();
      console.log('Login Response 1:', JSON.stringify(resBody, null, 2));
      
      // Handle nested data structure
      const authData = resBody.data || resBody; 
      token = authData.access_token || authData.accessToken;
      
      if (authData.user) {
        userId = authData.user.id;
      } else {
        const u = await client.query('SELECT id FROM users WHERE email = $1', [userEmail]);
        userId = u.rows[0].id;
      }
      console.log('   Logged in successfully. UserID:', userId);
    } else {
      console.log('   Login failed. Creating user directly in DB...');
      
      // Check if user exists but password wrong? Or just insert if not exists.
      const userCheck = await client.query('SELECT id FROM users WHERE email = $1', [userEmail]);
      
      if (userCheck.rows.length === 0) {
        const hashedPassword = await bcrypt.hash(userPass, 10);
        // Insert User
        const insertUser = await client.query(`
          INSERT INTO users ("firstName", "lastName", "email", "password", "phone", "role", "notificationChannel", "createdAt", "updatedAt", "verifiedAt")
          VALUES ('Reviewer', 'Test', $1, $2, '9999999999', 'CUSTOMER', 'WHATSAPP', NOW(), NOW(), NOW())
          RETURNING id
        `, [userEmail, hashedPassword]);
        userId = insertUser.rows[0].id;
        console.log('   User inserted directly into DB. ID:', userId);
      } else {
        // User exists but login failed (maybe wrong password in DB vs script). 
        // Update password.
        userId = userCheck.rows[0].id;
        const hashedPassword = await bcrypt.hash(userPass, 10);
        await client.query('UPDATE users SET password = $1, "verifiedAt" = NOW() WHERE id = $2', [hashedPassword, userId]);
        console.log('   User password updated and verified directly in DB.');
      }

      // Retry Login
      const loginRes2 = await fetch(`${API_URL}/auth/login`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ email: userEmail, password: userPass }),
      });

      if (loginRes2.ok) {
        const data = await loginRes2.json();
        console.log('Login Response:', data);
        token = data.accessToken;
        // If user object is missing, we use the userId we got/set earlier from DB
        if (!userId && data.user) userId = data.user.id;
        console.log('   Logged in successfully after DB update.');
      } else {
        const err = await loginRes2.text();
        throw new Error(`Failed to login even after DB insert: ${err}`);
      }
    }

    // 2. Ensure Restaurant Exists
    console.log('2. Preparing Data (Restaurant)...');
    let restaurantId = 0;
    const restRes = await client.query('SELECT id FROM restaurants LIMIT 1');
    if (restRes.rows.length > 0) {
      restaurantId = restRes.rows[0].id;
    } else {
      const insertRest = await client.query(`
        INSERT INTO restaurants (name, "ownerId", address, "lat", "lng", "isActive", "isApproved", "createdAt", "updatedAt")
        VALUES ('Test Restaurant', $1, '123 Test St', 0.0, 0.0, true, true, NOW(), NOW())
        RETURNING id
      `, [userId]);
      restaurantId = insertRest.rows[0].id;
      console.log('   Created Test Restaurant:', restaurantId);
    }

    // 3. Create Order
    console.log('3. Creating Test Order...');
    // Delete previous reviews for this user/order to avoid conflicts
    // We'll clean up reviews for this orderId later if we reuse it, but here we create NEW order every time?
    // Creating new order every time is safer for unique constraint.
    const insertOrder = await client.query(`
      INSERT INTO orders ("customerId", "restaurantId", "totalAmount", "status", "createdAt", "updatedAt", "currencyCode", "exchangeRate", "paymentMethod")
      VALUES ($1, $2, 1000, 'DELIVERED', NOW(), NOW(), 'SAR', 1, 'CASH')
      RETURNING id
    `, [userId, restaurantId]);
    const orderId = insertOrder.rows[0].id;
    console.log(`   Created Order ID: ${orderId}`);

    // 4. Submit Review via API
    console.log('4. Submitting Review via API...');
    const reviewPayload = {
      orderId: orderId,
      rating: 5,
      comment: 'Great service! API Test.',
    };

    const reviewRes = await fetch(`${API_URL}/reviews`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${token}`,
      },
      body: JSON.stringify(reviewPayload),
    });

    if (reviewRes.ok) {
      const reviewData = await reviewRes.json();
      console.log('   SUCCESS! Review Created:', reviewData);
    } else {
      const err = await reviewRes.text();
      console.error('   FAILED to create review:', err);
    }

  } catch (err) {
    console.error('ERROR:', err);
  } finally {
    await client.end();
  }
}

run();
