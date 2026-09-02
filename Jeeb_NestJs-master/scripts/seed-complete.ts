import { DataSource } from 'typeorm';
import * as dotenv from 'dotenv';
import * as path from 'path';
import * as bcrypt from 'bcrypt';

dotenv.config({ path: path.resolve(process.cwd(), '.env') });

const { DB_HOST, DB_PORT, DB_USERNAME, DB_PASSWORD, DB_DATABASE } = process.env;

const dataSource = new DataSource({
  type: 'postgres',
  host: DB_HOST || 'localhost',
  port: Number(DB_PORT) || 5432,
  username: DB_USERNAME || 'postgres',
  password: DB_PASSWORD || 'postgres',
  database: DB_DATABASE || 'delivery_jeeb',
  synchronize: false,
});

async function seed() {
  try {
    console.log('Connecting to database...');
    await dataSource.initialize();
    console.log('Database connected.');

    console.log('\n=== Clearing existing data ===');
    const tables = ['order_items', 'orders', 'products', 'merchants', 'users'];
    for (const table of tables) {
      try {
        await dataSource.query(`TRUNCATE TABLE ${table} CASCADE`);
        console.log(`Cleared ${table}`);
      } catch (e: any) {
        console.log(`Table ${table} does not exist yet`);
      }
    }

    const hashedPassword = await bcrypt.hash('password', 10);

    console.log('\n=== Creating Admins ===');
    const adminIds: number[] = [];

    const admins = [
      {
        email: 'sama@jeeb.com',
        firstName: 'Sama',
        lastName: 'Admin',
        phone: '+963950000001',
        role: 'ADMIN',
      },
      {
        email: 'haider@jeeb.com',
        firstName: 'Haider',
        lastName: 'Admin',
        phone: '+963950000002',
        role: 'ADMIN',
      },
      {
        email: 'admin@jeeb.com',
        firstName: 'Admin',
        lastName: 'System',
        phone: '+963950000003',
        role: 'ADMIN',
      },
    ];

    for (const admin of admins) {
      const result = await dataSource.query(
        `INSERT INTO users (email, password, "firstName", "lastName", phone, role, "notificationChannel", "isOnline", "isActive", "verifiedAt", address, "countryId", "cityId", "createdAt", "updatedAt")
         VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, NOW(), NOW())
         RETURNING id`,
        [
          admin.email,
          hashedPassword,
          admin.firstName,
          admin.lastName,
          admin.phone,
          admin.role,
          'EMAIL',
          true,
          true,
          new Date(),
          'Damascus, Syria',
          1,
          1,
        ],
      );
      adminIds.push(result[0].id);
      console.log(`Created Admin: ${admin.email}`);
    }

    console.log('\n=== Creating Merchants ===');
    const merchantIds: number[] = [];

    const merchants = [
      {
        email: 'samamerchant@jeeb.com',
        firstName: 'Sama',
        lastName: 'Merchant',
        phone: '+963960000001',
        restaurantName: 'مطعم سما',
      },
      {
        email: 'haidermerchant@jeeb.com',
        firstName: 'Haider',
        lastName: 'Merchant',
        phone: '+963960000002',
        restaurantName: 'مطعم حيدر',
      },
    ];

    for (const merchant of merchants) {
      const result = await dataSource.query(
        `INSERT INTO users (email, password, "firstName", "lastName", phone, role, "notificationChannel", "isOnline", "isActive", "verifiedAt", address, "countryId", "cityId", "createdAt", "updatedAt")
         VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, NOW(), NOW())
         RETURNING id`,
        [
          merchant.email,
          hashedPassword,
          merchant.firstName,
          merchant.lastName,
          merchant.phone,
          'MERCHANT',
          'WHATSAPP',
          true,
          true,
          new Date(),
          'Damascus, Syria',
          1,
          1,
        ],
      );
      const userId = result[0].id;
      merchantIds.push(userId);

      await dataSource.query(
        `INSERT INTO merchants ("userId", "restaurantName", "isOpen", "isActive", "createdAt", "updatedAt")
         VALUES ($1, $2, $3, $4, NOW(), NOW())`,
        [userId, merchant.restaurantName, true, true],
      );
      console.log(
        `Created Merchant: ${merchant.email} - ${merchant.restaurantName}`,
      );
    }

    console.log('\n=== Creating Products ===');
    const productIds: number[] = [];

    const productsList = [
      {
        merchantId: merchantIds[0],
        name: 'برجر كلاسيك',
        price: 15000,
        hasStock: true,
        stockQuantity: 50,
        isAvailable: true,
      },
      {
        merchantId: merchantIds[0],
        name: 'بيتزا مارجريتا',
        price: 25000,
        hasStock: false,
        stockQuantity: null,
        isAvailable: true,
      },
      {
        merchantId: merchantIds[1],
        name: 'شاورما دجاج',
        price: 12000,
        hasStock: true,
        stockQuantity: 100,
        isAvailable: true,
      },
      {
        merchantId: merchantIds[1],
        name: 'كبة مشوية',
        price: 20000,
        hasStock: false,
        stockQuantity: null,
        isAvailable: true,
      },
    ];

    for (const product of productsList) {
      const result = await dataSource.query(
        `INSERT INTO products ("merchantId", name, price, "hasStock", "stockQuantity", "isAvailable", "createdAt", "updatedAt")
         VALUES ($1, $2, $3, $4, $5, $6, NOW(), NOW())
         RETURNING id`,
        [
          product.merchantId,
          JSON.stringify({ ar: product.name }),
          product.price,
          product.hasStock,
          product.stockQuantity,
          product.isAvailable,
        ],
      );
      productIds.push(result[0].id);
      console.log(
        `Created Product: ${product.name} (Stock: ${product.hasStock ? product.stockQuantity : 'Unlimited'})`,
      );
    }

    console.log('\n=== Creating Customers ===');
    const customerIds: number[] = [];

    const customersList = [
      {
        email: 'samacustomer@jeeb.com',
        firstName: 'Sama',
        lastName: 'Customer',
        phone: '+963970000001',
      },
      {
        email: 'haidercustomer@jeeb.com',
        firstName: 'Haider',
        lastName: 'Customer',
        phone: '+963970000002',
      },
      {
        email: 'johncustomer@jeeb.com',
        firstName: 'John',
        lastName: 'Doe',
        phone: '+963970000003',
      },
      {
        email: 'alincustomer@jeeb.com',
        firstName: 'Alin',
        lastName: 'Smith',
        phone: '+963970000004',
      },
    ];

    for (const customer of customersList) {
      const result = await dataSource.query(
        `INSERT INTO users (email, password, "firstName", "lastName", phone, role, "notificationChannel", "isOnline", "isActive", "verifiedAt", address, "countryId", "cityId", "createdAt", "updatedAt")
         VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, NOW(), NOW())
         RETURNING id`,
        [
          customer.email,
          hashedPassword,
          customer.firstName,
          customer.lastName,
          customer.phone,
          'CUSTOMER',
          'WHATSAPP',
          false,
          true,
          new Date(),
          'Damascus, Syria',
          1,
          1,
        ],
      );
      customerIds.push(result[0].id);
      console.log(`Created Customer: ${customer.email}`);
    }

    console.log('\n=== Creating Orders ===');

    const ordersList = [
      {
        customerId: customerIds[0],
        ownerId: merchantIds[0],
        totalAmount: 15000,
        deliveryFee: 3000,
        status: 'PENDING',
        paymentMethod: 'CASH',
      },
      {
        customerId: customerIds[0],
        ownerId: merchantIds[0],
        totalAmount: 25000,
        deliveryFee: 3000,
        discountAmount: 3750,
        status: 'CONFIRMED',
        paymentMethod: 'CASH',
      },
      {
        customerId: customerIds[1],
        ownerId: merchantIds[1],
        totalAmount: 12000,
        deliveryFee: 3000,
        discountAmount: 1200,
        status: 'PREPARING',
        paymentMethod: 'WALLET',
      },
      {
        customerId: customerIds[1],
        ownerId: merchantIds[1],
        totalAmount: 20000,
        deliveryFee: 3000,
        discountAmount: 3000,
        status: 'READY_FOR_PICKUP',
        paymentMethod: 'CASH',
      },
      {
        customerId: customerIds[2],
        ownerId: merchantIds[0],
        totalAmount: 15000,
        deliveryFee: 3000,
        status: 'ASSIGNED',
        paymentMethod: 'ONLINE',
      },
      {
        customerId: customerIds[2],
        ownerId: merchantIds[1],
        totalAmount: 12000,
        deliveryFee: 3000,
        status: 'PICKED_UP',
        paymentMethod: 'CASH',
      },
      {
        customerId: customerIds[3],
        ownerId: merchantIds[0],
        totalAmount: 40000,
        deliveryFee: 3000,
        couponCode: 'DISCOUNT10',
        tipAmount: 2000,
        status: 'ON_THE_WAY',
        paymentMethod: 'CASH',
      },
      {
        customerId: customerIds[0],
        ownerId: merchantIds[1],
        totalAmount: 20000,
        deliveryFee: 3000,
        status: 'DELIVERED',
        paymentMethod: 'CASH',
      },
      {
        customerId: customerIds[1],
        ownerId: merchantIds[0],
        totalAmount: 15000,
        deliveryFee: 3000,
        status: 'CANCELLED',
        cancelledAt: new Date(),
        previousStatus: 'PENDING',
        paymentMethod: 'CASH',
      },
      {
        customerId: customerIds[2],
        ownerId: merchantIds[1],
        totalAmount: 12000,
        deliveryFee: 3000,
        status: 'REJECTED',
        paymentMethod: 'CASH',
      },
    ];

    for (let i = 0; i < ordersList.length; i++) {
      const order = ordersList[i];
      const result = await dataSource.query(
        `INSERT INTO orders ("customerId", "ownerId", "totalAmount", "deliveryFee", "discountAmount", "couponCode", "tipAmount", "platformCommission", "ownerRevenue", "currencyCode", "exchangeRate", "paymentMethod", status, "deliveryDeadline", "mealPreparationTime", "deliveryTime", "deliveryCoordinates", "createdAt", "updatedAt", "cancelledAt", "previousStatus")
         VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17, NOW(), NOW(), $18, $19)
         RETURNING id`,
        [
          order.customerId,
          order.ownerId,
          order.totalAmount,
          order.deliveryFee,
          order.discountAmount || 0,
          order.couponCode || null,
          order.tipAmount || 0,
          Math.floor(order.totalAmount * 0.1),
          Math.floor(order.totalAmount * 0.8),
          'SYP',
          1,
          order.paymentMethod,
          order.status,
          new Date(Date.now() + 60 * 60 * 1000),
          15,
          30,
          JSON.stringify({
            latitude: 33.5138,
            longitude: 36.2765,
            address: 'Damascus, Syria',
          }),
          order.cancelledAt || null,
          order.previousStatus || null,
        ],
      );
      const orderId = result[0].id;

      const productId = productIds[i % 4];
      const productPrice = productsList[i % 4].price;
      await dataSource.query(
        `INSERT INTO order_items ("orderId", "productId", "productName", quantity, "originalUnitPrice", "unitPrice", "totalPrice")
         VALUES ($1, $2, $3, $4, $5, $6, $7)`,
        [
          orderId,
          productId,
          productsList[i % 4].name,
          1,
          productPrice,
          productPrice,
          productPrice,
        ],
      );

      console.log(
        `Created Order #${orderId}: ${order.status} - ${order.totalAmount} SYP`,
      );
    }

    console.log('\n=== Seeding Summary ===');
    console.log(
      'Admins created: sama@jeeb.com, haider@jeeb.com, admin@jeeb.com',
    );
    console.log(
      'Merchants created: samamerchant@jeeb.com (مطعم سما), haidermerchant@jeeb.com (مطعم حيدر)',
    );
    console.log('Products created: 4 (2 per merchant)');
    console.log(
      'Customers created: samacustomer@jeeb.com, haidercustomer@jeeb.com, johncustomer@jeeb.com, alincustomer@jeeb.com',
    );
    console.log('Orders created: 10 (various statuses)');
    console.log('Password for all accounts: password');
    console.log('========================\n');
  } catch (error) {
    console.error('Seeding failed:', error);
  } finally {
    await dataSource.destroy();
  }
}

seed();
