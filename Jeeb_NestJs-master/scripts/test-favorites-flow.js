const { Client } = require('pg');
const bcrypt = require('bcrypt');
// const fetch = require('node-fetch');

// Config (adjust to your env)
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
  try {
    await client.connect();
    console.log('--- Connected to DB ---');

    // 1. Authenticate (Create/Update User)
    console.log('\n--- 1. Authenticating ---');
    const userEmail = 'favorites_tester@test.com';
    const userPass = 'password123';
    let token = '';
    let userId = 0;

    // Ensure user exists
    const userCheck = await client.query('SELECT id FROM users WHERE email = $1', [userEmail]);
    if (userCheck.rows.length === 0) {
      const hashedPassword = await bcrypt.hash(userPass, 10);
      const insertUser = await client.query(`
        INSERT INTO users ("firstName", "lastName", "email", "password", "phone", "role", "notificationChannel", "createdAt", "updatedAt", "verifiedAt")
        VALUES ('Fav', 'Tester', $1, $2, '0599999999', 'CUSTOMER', 'WHATSAPP', NOW(), NOW(), NOW())
        RETURNING id
      `, [userEmail, hashedPassword]);
      userId = insertUser.rows[0].id;
      console.log('   Created new test user:', userId);
    } else {
      userId = userCheck.rows[0].id;
      const hashedPassword = await bcrypt.hash(userPass, 10);
      await client.query('UPDATE users SET password = $1, "verifiedAt" = NOW() WHERE id = $2', [hashedPassword, userId]);
      console.log('   Updated existing test user:', userId);
    }

    // Login
    const loginRes = await fetch(`${API_URL}/auth/login`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ email: userEmail, password: userPass }),
    });

    if (!loginRes.ok) {
      const err = await loginRes.text();
      throw new Error(`Login failed: ${err}`);
    }

    const loginData = await loginRes.json();
    console.log('   Login Response:', JSON.stringify(loginData, null, 2));
    token = loginData.access_token || (loginData.data && loginData.data.access_token);
    console.log('   Logged in successfully. Token received.');


    // 2. Prepare Test Data (Restaurant & Product)
    console.log('\n--- 2. Preparing Test Data ---');
    
    // Ensure at least one restaurant
    let restaurantId;
    const restRes = await client.query('SELECT id FROM restaurants LIMIT 1');
    if (restRes.rows.length > 0) {
      restaurantId = restRes.rows[0].id;
      console.log('   Found existing restaurant ID:', restaurantId);
    } else {
      // Create a dummy restaurant if none (requires a valid user as owner, can use our test user for simplicity)
       const insertRest = await client.query(`
        INSERT INTO restaurants ("nameAr", "nameEn", "ownerId", "categoryId", "cityId", "createdAt", "updatedAt")
        VALUES ('مطعم تجريبي', 'Test Restaurant', $1, 1, 1, NOW(), NOW())
        RETURNING id
      `, [userId]); // Assuming category 1 and city 1 exist, otherwise might fail. Better to use existing if possible.
      restaurantId = insertRest.rows[0].id;
      console.log('   Created test restaurant ID:', restaurantId);
    }

    // Ensure at least one product
    let productId;
    const prodRes = await client.query('SELECT id FROM products LIMIT 1');
    if (prodRes.rows.length > 0) {
      productId = prodRes.rows[0].id;
      console.log('   Found existing product ID:', productId);
    } else {
       // Create dummy product
       // Assuming products table has "name", "restaurantId", "price"
       const insertProd = await client.query(`
        INSERT INTO products ("name", "restaurantId", "price", "createdAt", "updatedAt")
        VALUES ('Test Product', $1, 50, NOW(), NOW())
        RETURNING id
       `, [restaurantId]);
       productId = insertProd.rows[0].id;
       console.log('   Created test product ID:', productId);
    }


    // 3. Test Toggle Favorite (Restaurant) - ADD
    console.log('\n--- 3. Test Toggle Favorite (Restaurant) - ADD ---');
    // Ensure it's removed first, then add it
    await fetch(`${API_URL}/favorites/toggle`, {
      method: 'POST',
      headers: { 
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${token}`
      },
      body: JSON.stringify({
        entityType: 'RESTAURANT',
        entityId: restaurantId
      })
    }); // First call to ensure it's removed (if already added)

    const toggleRestRes = await fetch(`${API_URL}/favorites/toggle`, {
      method: 'POST',
      headers: { 
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${token}`
      },
      body: JSON.stringify({
        entityType: 'RESTAURANT',
        entityId: restaurantId
      })
    }); // Second call to add it
    
    const toggleRestData = await toggleRestRes.json();
    console.log('   Response:', JSON.stringify(toggleRestData));
    if (toggleRestData.data.isFavorite === true) {
      console.log('   ✅ Success: Restaurant added to favorites.');
    } else {
      console.log('   ❌ Failure: Expected isFavorite to be true.');
    }


    // 4. Test Get Favorites (All)
    console.log('\n--- 4. Test Get Favorites (All) ---');
    const getFavRes = await fetch(`${API_URL}/favorites`, {
      method: 'GET',
      headers: { 'Authorization': `Bearer ${token}` }
    });
    const getFavData = await getFavRes.json();
    console.log('   Favorites Count:', getFavData.data.length);
    const foundRest = getFavData.data.find(f => f.entityType === 'RESTAURANT' && f.entityId === restaurantId);
    if (foundRest) {
       console.log('   ✅ Success: Found added restaurant in list.');
       if (foundRest.entity) {
         console.log('   ✅ Success: Entity details populated (Name):', foundRest.entity.name || foundRest.entity.nameEn || foundRest.entity.nameAr);
       } else {
         console.log('   ❌ Failure: Entity details missing.');
       }
    } else {
       console.log('   ❌ Failure: Added restaurant not found in list.');
    }


    // 5. Test Toggle Favorite (Restaurant) - REMOVE
    console.log('\n--- 5. Test Toggle Favorite (Restaurant) - REMOVE ---');
    // Ensure it's added first
    const prepRes = await fetch(`${API_URL}/favorites/toggle`, {
      method: 'POST',
      headers: { 
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${token}`
      },
      body: JSON.stringify({
        entityType: 'RESTAURANT',
        entityId: restaurantId
      })
    });
    const prepData = await prepRes.json();
    
    // If the prep call resulted in removal (isFavorite: false), it means it WAS a favorite.
    // If it resulted in addition (isFavorite: true), it means it WAS NOT a favorite, but now IS.
    // We want it to be a favorite BEFORE the test step.
    
    // So if prepData says it is now FALSE, we need to toggle again to make it TRUE.
    if (prepData.data.isFavorite === false) {
         await fetch(`${API_URL}/favorites/toggle`, {
            method: 'POST',
            headers: { 
                'Content-Type': 'application/json',
                'Authorization': `Bearer ${token}`
            },
            body: JSON.stringify({
                entityType: 'RESTAURANT',
                entityId: restaurantId
            })
        });
    }

    // Now verify removal
    const toggleRestRes2 = await fetch(`${API_URL}/favorites/toggle`, {
      method: 'POST',
      headers: { 
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${token}`
      },
      body: JSON.stringify({
        entityType: 'RESTAURANT',
        entityId: restaurantId
      })
    });
    
    const toggleRestData2 = await toggleRestRes2.json();
    console.log('   Response:', JSON.stringify(toggleRestData2));
    if (toggleRestData2.data.isFavorite === false) {
      console.log('   ✅ Success: Restaurant removed from favorites.');
    } else {
      console.log('   ❌ Failure: Expected isFavorite to be false.');
    }


    // 6. Test Invalid Entity (Error Handling)
    console.log('\n--- 6. Test Invalid Entity (Error Handling) ---');
    const invalidRes = await fetch(`${API_URL}/favorites/toggle`, {
      method: 'POST',
      headers: { 
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${token}`
      },
      body: JSON.stringify({
        entityType: 'RESTAURANT',
        entityId: 999999
      })
    });
    
    if (invalidRes.status === 404) {
      const errData = await invalidRes.json();
      console.log('   ✅ Success: Received 404 for invalid ID. Message:', errData.message);
    } else {
      console.log('   ❌ Failure: Expected 404, got', invalidRes.status);
    }

    // 7. Test Bulk Add
    console.log('\n--- 7. Test Bulk Add (Product) ---');
    const bulkAddRes = await fetch(`${API_URL}/favorites/bulk-add`, {
      method: 'POST',
      headers: { 
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${token}`
      },
      body: JSON.stringify({
        entityType: 'PRODUCT',
        entityIds: [productId]
      })
    });
    const bulkAddData = await bulkAddRes.json();
    console.log('   Response:', JSON.stringify(bulkAddData));
    if (bulkAddData.data.added && bulkAddData.data.added.includes(productId)) {
        console.log('   ✅ Success: Product added via bulk endpoint.');
    } else {
        console.log('   ❌ Failure: Bulk add failed.');
    }

    // 8. Test Bulk Remove
    console.log('\n--- 8. Test Bulk Remove (Product) ---');
    const bulkRemoveRes = await fetch(`${API_URL}/favorites/bulk-remove`, {
      method: 'POST',
      headers: { 
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${token}`
      },
      body: JSON.stringify({
        entityType: 'PRODUCT',
        entityIds: [productId]
      })
    });
    const bulkRemoveData = await bulkRemoveRes.json();
    console.log('   Response:', JSON.stringify(bulkRemoveData));
     if (bulkRemoveData.data.removed && bulkRemoveData.data.removed.includes(productId)) {
        console.log('   ✅ Success: Product removed via bulk endpoint.');
    } else {
        console.log('   ❌ Failure: Bulk remove failed.');
    }


    // 9. Test New Add Endpoint (Single)
    console.log('\n--- 9. Test New Add Endpoint (Single Product) ---');
    const addSingleRes = await fetch(`${API_URL}/favorites/add`, {
      method: 'POST',
      headers: { 
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${token}`
      },
      body: JSON.stringify({
        entityType: 'PRODUCT',
        entityId: productId
      })
    });
    const addSingleData = await addSingleRes.json();
    console.log('   Response:', JSON.stringify(addSingleData));
    if (addSingleData.data.added && addSingleData.data.added.includes(productId)) {
        console.log('   ✅ Success: Product added via new add endpoint (single).');
    } else {
        console.log('   ❌ Failure: New add (single) failed.');
    }

    // 10. Test New Remove Endpoint (Single)
    console.log('\n--- 10. Test New Remove Endpoint (Single Product) ---');
    const removeSingleRes = await fetch(`${API_URL}/favorites/remove`, {
      method: 'POST',
      headers: { 
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${token}`
      },
      body: JSON.stringify({
        entityType: 'PRODUCT',
        entityId: productId
      })
    });
    const removeSingleData = await removeSingleRes.json();
    console.log('   Response:', JSON.stringify(removeSingleData));
    if (removeSingleData.data.removed && removeSingleData.data.removed.includes(productId)) {
        console.log('   ✅ Success: Product removed via new remove endpoint (single).');
    } else {
        console.log('   ❌ Failure: New remove (single) failed.');
    }

    // 11. Test New Add Endpoint (List)
    console.log('\n--- 11. Test New Add Endpoint (List of Products) ---');
    const addListRes = await fetch(`${API_URL}/favorites/add`, {
      method: 'POST',
      headers: { 
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${token}`
      },
      body: JSON.stringify({
        entityType: 'PRODUCT',
        entityIds: [productId]
      })
    });
    const addListData = await addListRes.json();
    console.log('   Response:', JSON.stringify(addListData));
    if (addListData.data.added && addListData.data.added.includes(productId)) {
        console.log('   ✅ Success: Product list added via new add endpoint.');
    } else {
        console.log('   ❌ Failure: New add (list) failed.');
    }
    
    // 12. Test New Remove Endpoint (List)
    console.log('\n--- 12. Test New Remove Endpoint (List of Products) ---');
    const removeListRes = await fetch(`${API_URL}/favorites/remove`, {
      method: 'POST',
      headers: { 
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${token}`
      },
      body: JSON.stringify({
        entityType: 'PRODUCT',
        entityIds: [productId]
      })
    });
    const removeListData = await removeListRes.json();
    console.log('   Response:', JSON.stringify(removeListData));
    if (removeListData.data.removed && removeListData.data.removed.includes(productId)) {
        console.log('   ✅ Success: Product list removed via new remove endpoint.');
    } else {
        console.log('   ❌ Failure: New remove (list) failed.');
    }


    console.log('\n--- Test Completed ---');

  } catch (error) {
    console.error('❌ Test Script Error:', error);
  } finally {
    await client.end();
  }
}

run();
