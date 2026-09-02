import { DataSource } from 'typeorm';
import { config } from 'dotenv';
import * as path from 'path';

config();

const dataSource = new DataSource({
  type: 'postgres',
  host: process.env.DB_HOST || 'localhost',
  port: parseInt(process.env.DB_PORT || '5432', 10),
  username: process.env.DB_USERNAME || 'postgres',
  password: process.env.DB_PASSWORD || 'postgres',
  database: process.env.DB_DATABASE || 'delivery_jeeb',
  entities: [path.join(__dirname, '../src/database/entities/**/*.entity.ts')],
  logging: false,
});

async function unblockUser(email: string) {
  try {
    console.log('Connecting to database...');
    await dataSource.initialize();

    const blocks = await dataSource
      .createQueryBuilder()
      .select('loginBlock')
      .from('login_blocks', 'loginBlock')
      .where('loginBlock.email = :email', { email: email.toLowerCase() })
      .andWhere('loginBlock.isActive = :isActive', { isActive: true })
      .getMany();

    if (blocks.length === 0) {
      console.log('❌ No active blocks found for this email.');
      await dataSource.destroy();
      process.exit(0);
    }

    console.log(`\n📊 Found ${blocks.length} active block(s):`);
    blocks.forEach((block: any, index: number) => {
      console.log(`\n${index + 1}. Block ID: ${block.id}`);
      console.log(`   Level: ${block.blockLevel}`);
      console.log(`   Type: ${block.blockType}`);
      console.log(`   Blocked At: ${block.blockedAt}`);
      console.log(`   Expires At: ${block.expiresAt || 'Permanent'}`);
    });

    console.log('\n🗑️  Deactivating blocks...');
    await dataSource
      .createQueryBuilder()
      .update('login_blocks')
      .set({ isActive: false, unblockedAt: new Date() })
      .where('email = :email', { email: email.toLowerCase() })
      .andWhere('isActive = :isActive', { isActive: true })
      .execute();

    console.log(`\n✅ Successfully unblocked ${blocks.length} block(s) for ${email}`);

    await dataSource.destroy();
    process.exit(0);
  } catch (error) {
    console.error('❌ Error:', error);
    await dataSource.destroy();
    process.exit(1);
  }
}

const email = process.argv[2];
if (!email) {
  console.error('❌ Please provide an email address.');
  console.log('Usage: npm run db:unblock -- <email>');
  console.log('Example: npm run db:unblock -- user@example.com');
  process.exit(1);
}

unblockUser(email);