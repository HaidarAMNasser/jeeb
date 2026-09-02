# 🔧 Fix User-Merchant Constraint Issue - Complete Guide

## Problem Description

When running `npm run db:fix-user-merchant`, you encountered this error:

```
❌ Error fixing user-merchant constraint: QueryFailedError: relation "merchants" does not exist
```

## Root Cause

The `merchants` table doesn't exist in your production database yet. This happens when:
1. New entities are added to the codebase
2. The database schema hasn't been synchronized on the production server
3. The fix script assumes the table exists without checking first

## ✅ Solution (Step-by-Step)

### **Option 1: Recommended Approach**

#### Step 1: Sync Database Schema
Run this command on your production server to create all missing tables:

```bash
npm run db:sync
```

This will:
- Connect to your production database
- Compare the current schema with all Entity files
- Create missing tables (including `merchants`)
- **Note:** It won't delete existing data

#### Step 2: Run the Fixed Script

After the schema is synced, run:

```bash
npm run db:fix-user-merchant:v2
```

This improved version:
- ✅ Checks if `merchants` table exists before running
- ✅ Provides clear error messages
- ✅ Creates merchant records for MERCHANT users without them
- ✅ Uses correct column names matching the Merchant entity

---

### **Option 2: Manual Verification First**

If you want to verify what's in your database first:

#### Step 1: Check Current Database State

Connect to your PostgreSQL database:

```bash
psql -U postgres -d jeeb_db
```

Check if merchants table exists:

```sql
SELECT EXISTS (
  SELECT FROM information_schema.tables 
  WHERE table_schema = 'public' 
  AND table_name = 'merchants'
);
```

Check MERCHANT users:

```sql
SELECT id, email, "firstName", "lastName", role 
FROM users 
WHERE role = 'MERCHANT';
```

Check if any have merchant records:

```sql
SELECT u.id, u.email, m.id as merchant_id
FROM users u
LEFT JOIN merchants m ON u.id = m."userId"
WHERE u.role = 'MERCHANT';
```

#### Step 2: Exit and Run Schema Sync

```bash
\q
npm run db:sync
```

#### Step 3: Run Fix Script

```bash
npm run db:fix-user-merchant:v2
```

---

## 📋 What the Fix Script Does

The script (`fix-user-merchant-constraint-v2.ts`):

1. **Checks prerequisites**: Verifies `merchants` table exists
2. **Finds orphaned users**: Identifies MERCHANT users without merchant records
3. **Creates merchant records**: For each orphaned user, creates a matching merchant record:
   - `userId` = user's ID
   - `restaurantName` = "{firstName} {lastName}'s Restaurant"
   - `email` = user's email
   - `phone` = user's phone
   - `isOpen` = true
   - `minimumOrderAmount` = 0
   - `estimatedDeliveryMinutes` = 30
   - `isActive` = user's isActive or true

4. **Reports results**: Shows how many records were created

---

## 🔍 Understanding the Relationship

### User ↔ Merchant Relationship

```typescript
// User entity
@OneToOne(() => Merchant, (merchant) => merchant.user, {
  nullable: true,
  onDelete: 'CASCADE',
})
@JoinColumn({ name: 'id', referencedColumnName: 'userId' })
merchant?: Merchant | null;

// Merchant entity
@Column({ type: 'int', unique: true })
userId: number;

@OneToOne(() => User, (user) => user.merchant, { onDelete: 'CASCADE' })
@JoinColumn({ name: 'userId' })
user: User;
```

**Key Points:**
- `users.id` = `merchants.userId` (One-to-One relationship)
- A MERCHANT user should have a corresponding merchant record
- The merchant record contains additional business-specific data

---

## ⚠️ Important Notes

### Before Running on Production:

1. **Backup your database first!**
   ```bash
   pg_dump -U postgres jeeb_db > backup_$(date +%Y%m%d_%H%M%S).sql
   ```

2. **Test on staging/local first**
   - Clone production database to staging
   - Run the scripts there
   - Verify everything works

3. **Schedule maintenance window**
   - These operations may lock tables briefly
   - Run during low-traffic periods

---

## 🎯 Expected Output

After successful execution, you should see:

```
🔧 Connecting to database...
✅ Database connected.
🔍 Checking if merchants table exists...
✅ merchants table exists.
🔍 Checking for MERCHANT users without merchant records...
❌ Found 5 MERCHANT users without merchant records:
┌─────────┬───────┬─────────────────────┬───────────┬────────────┬─────────┐
│ (index) │  id   │       email         │ firstName │  lastName  │ phone   │
├─────────┼───────┼─────────────────────┼───────────┼────────────┼─────────┤
│    0    │  123  │ merchant@example.com│   John    │    Doe     │ +123... │
└─────────┴───────┴─────────────────────┴───────────┴────────────┴─────────┘
🏪 Creating merchant records for these users...
   Creating merchant for user: merchant@example.com (ID: 123, userId: 123)
✅ Created 5 merchant records.
🎯 User-merchant constraint fix completed successfully!
```

---

## 🐛 Troubleshooting

### If you still get errors:

1. **Check database connection**
   ```bash
   # Verify .env settings on production
   echo $DB_HOST
   echo $DB_DATABASE
   echo $DB_USERNAME
   ```

2. **Check entity files are deployed**
   ```bash
   # Verify merchant.entity.ts exists
   ls -la src/database/entities/merchant.entity.ts
   ```

3. **Check TypeScript compilation**
   ```bash
   # Rebuild if needed
   npm run build
   ```

4. **Verify permissions**
   ```sql
   -- Check user has permission to create tables
   \du
   ```

---

## 📞 Need Help?

If issues persist:
1. Check the full error message
2. Review database logs
3. Verify all environment variables
4. Test with a simpler query first

---

**Last Updated:** 2026-03-10  
**Author:** AI Assistant
