import http from 'k6/http';

export default function () {
  let loginRes = http.post(
    'http://localhost:3001/api/v1/auth/login',
    JSON.stringify({ email: 'loadtest.customer1@jeeb.com', password: 'password' }),
    { headers: { 'Content-Type': 'application/json', 'Accept': 'application/json' } }
  );
  console.log('Login status: ' + loginRes.status);
  if (loginRes.status !== 200) { console.log('Login body: ' + loginRes.body); return; }

  let token = loginRes.json('data.access_token');
  
  let orderPayload = JSON.stringify({
    ownerId: 5,
    items: [{ productId: 4, quantity: 1 }],
    deliveryCoordinates: { latitude: 33.5138, longitude: 36.2765 },
    areaId: 2,
    paymentMethod: 'CASH',
    note: 'Test order'
  });
  
  let orderRes = http.post(
    'http://localhost:3001/api/v1/orders',
    orderPayload,
    { headers: { 'Content-Type': 'application/json', 'Accept': 'application/json', 'Authorization': 'Bearer ' + token } }
  );
  console.log('Order status: ' + orderRes.status);
  console.log('Order body: ' + orderRes.body);
}
