-- Script to clean up orphaned order_items records
-- Run this before syncing the database schema

-- 1. First, find orphaned order_items (where productId doesn't exist in products table)
SELECT oi.id, oi.productId, oi.productName, oi.orderId
FROM order_items oi
LEFT JOIN products p ON oi."productId" = p.id
WHERE oi."productId" IS NOT NULL AND p.id IS NULL;

-- 2. Delete orphaned order_items that reference non-existent products
DELETE FROM order_items
WHERE "productId" IN (
    SELECT oi."productId"
    FROM order_items oi
    LEFT JOIN products p ON oi."productId" = p.id
    WHERE oi."productId" IS NOT NULL AND p.id IS NULL
);

-- 3. Also clean up orphaned offer items (where offerId doesn't exist in offers table)
SELECT oi.id, oi."offerId", oi."productName", oi."orderId"
FROM order_items oi
LEFT JOIN offers o ON oi."offerId" = o.id
WHERE oi."offerId" IS NOT NULL AND o.id IS NULL;

-- 4. Delete orphaned order_items that reference non-existent offers
DELETE FROM order_items
WHERE "offerId" IN (
    SELECT oi."offerId"
    FROM order_items oi
    LEFT JOIN offers o ON oi."offerId" = o.id
    WHERE oi."offerId" IS NOT NULL AND o.id IS NULL
);

-- 5. Verify the cleanup
SELECT COUNT(*) as remaining_orphans FROM order_items oi
LEFT JOIN products p ON oi."productId" = p.id
WHERE oi."productId" IS NOT NULL AND p.id IS NULL;
