const { Client } = require('pg');
const fetch = (...args) => import('node-fetch').then(({default: fetch}) => fetch(...args));

// Config
const DB_CONFIG = {
  host: 'localhost',
  port: 5432,
  user: 'postgres',
  password: '20012001',
  database: 'delivery_jeeb_db',
};

const API_URL = 'http://localhost:3001/api/v1'; // Check port

async function run() {
  const client = new Client(DB_CONFIG);
  try {
    await client.connect();
    console.log('--- Connected to DB ---');

    // 1. Authenticate (Get Token)
    const userEmail = 'inference_tester@test.com';
    const userPass = 'password123';
    let token = '';

    // Login
    console.log('Logging in...');
    const loginRes = await fetch(`${API_URL}/auth/login`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ email: userEmail, password: userPass }),
    });

    if (!loginRes.ok) {
        console.error('Login failed. Please ensure the user exists.');
        return;
    }
    
    const loginData = await loginRes.json();
    token = loginData.data ? loginData.data.access_token : loginData.access_token;
    console.log('--- Logged in ---');

    // 2. Find Test Data
    console.log('--- Finding Test Data ---');
    
    // Get some Restaurant IDs
    const rRes = await client.query('SELECT id FROM restaurants LIMIT 10');
    const rIds = rRes.rows.map(r => r.id);
    console.log('Restaurant IDs:', rIds);
    
    // Get some Product IDs
    const pRes = await client.query('SELECT id FROM products LIMIT 10');
    const pIds = pRes.rows.map(p => p.id);
    console.log('Product IDs:', pIds);
    
    // Find Unique Restaurant ID (not in Products)
    const uniqueR = rIds.find(id => !pIds.includes(id));
    
    // Find Unique Product ID (not in Restaurants)
    let uniqueP = pIds.find(id => !rIds.includes(id));
    
    if (!uniqueP) {
       console.log('Creating a test product...');
       const validRId = rIds[0];
       const cRes = await client.query('SELECT id FROM categories LIMIT 1');
       let categoryId = cRes.rows.length > 0 ? cRes.rows[0].id : null;
       
       const newP = await client.query(`
         INSERT INTO products (name, description, price, "restaurantId", "categoryId", "createdAt", "updatedAt")
         VALUES ('Test Product', 'Desc', 10, $1, $2, NOW(), NOW())
         RETURNING id
       `, [validRId, categoryId]);
       uniqueP = newP.rows[0].id;
       console.log(`Created Test Product with ID: ${uniqueP}`);
    }
    
    console.log(`Unique Restaurant ID: ${uniqueR}`);
    console.log(`Unique Product ID: ${uniqueP}`);

    if (!uniqueR && !uniqueP) {
        console.error('Could not find ANY unique IDs for testing.');
        return;
    }

    // 3. Cleanup (Remove if exists)
    console.log('\n--- Cleanup ---');
    const idsToTest = [];
    if (uniqueR) idsToTest.push(uniqueR);
    if (uniqueP) idsToTest.push(uniqueP);

    for (const id of idsToTest) {
        await fetch(`${API_URL}/favorites/remove`, {
            method: 'POST',
            headers: { 
              'Content-Type': 'application/json',
              'Authorization': `Bearer ${token}`
            },
            body: JSON.stringify({ entityId: id })
        });
    }

    // 4. Test Add (Single Item)
    for (const id of idsToTest) {
        console.log(`\n--- Test: Add Entity ${id} ---`);
        const addRes = await fetch(`${API_URL}/favorites/add`, {
            method: 'POST',
            headers: { 
              'Content-Type': 'application/json',
              'Authorization': `Bearer ${token}`
            },
            body: JSON.stringify({ entityId: id })
        });
        
        const addData = await addRes.json();
        console.log('Add Response:', JSON.stringify(addData, null, 2));
    }

    // 5. Verify Favorites (Get All)
    console.log('\n--- Test: Get All Favorites ---');
    const getRes = await fetch(`${API_URL}/favorites`, {
        method: 'GET',
        headers: { 
          'Authorization': `Bearer ${token}`
        }
    });
    const getData = await getRes.json();
    const favorites = getData.data || getData; // Adjust based on interceptor
    
    if (uniqueR) {
        const addedR = favorites.find(f => f.entityId === uniqueR);
        // Check if entity exists and has restaurant-specific property (e.g., ownerId)
        // Or just check if it exists, since we can't check entityType anymore
        if (addedR && addedR.entity) {
             // Optional: Check if it looks like a restaurant
             if (addedR.entity.ownerId !== undefined) {
                console.log(`✅ Success: Restaurant ${uniqueR} inferred correctly (Verified by ownerId).`);
             } else {
                console.log(`⚠️ Warning: Restaurant ${uniqueR} added but entity details might be generic.`);
             }
        } else {
            console.log(`❌ Fail: Restaurant ${uniqueR} not found in favorites.`);
        }
    }

    if (uniqueP) {
        const addedP = favorites.find(f => f.entityId === uniqueP);
        if (addedP && addedP.entity) {
             // Optional: Check if it looks like a product
             if (addedP.entity.price !== undefined) {
                console.log(`✅ Success: Product ${uniqueP} inferred correctly (Verified by price).`);
             } else {
                console.log(`⚠️ Warning: Product ${uniqueP} added but entity details might be generic.`);
             }
        } else {
            console.log(`❌ Fail: Product ${uniqueP} not found in favorites.`);
        }
    }

    // 6. Test Remove (Single Item)
    console.log('\n--- Test: Remove ---');
    for (const id of idsToTest) {
        const remRes = await fetch(`${API_URL}/favorites/remove`, {
            method: 'POST',
            headers: { 
              'Content-Type': 'application/json',
              'Authorization': `Bearer ${token}`
            },
            body: JSON.stringify({ entityId: id })
        });
        const remData = await remRes.json();
        console.log(`Remove Entity ${id} Response:`, JSON.stringify(remData, null, 2));
    }

  } catch (err) {
    console.error('Error:', err);
  } finally {
    await client.end();
  }
}

run();
