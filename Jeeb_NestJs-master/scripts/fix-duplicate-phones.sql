-- Fix duplicate phone numbers in users table
-- This script will update duplicate phone numbers to unique values

-- First, find and update duplicate phone numbers
UPDATE users 
SET phone = phone || '-' || id::text
WHERE phone IN (
  SELECT phone 
  FROM users 
  GROUP BY phone 
  HAVING COUNT(*) > 1
);

-- Verify the update
SELECT phone, COUNT(*) as count 
FROM users 
GROUP BY phone 
ORDER BY count DESC;

-- Show sample users to verify
SELECT id, phone, email, role FROM users LIMIT 10;
