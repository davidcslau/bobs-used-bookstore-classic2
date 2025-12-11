# Database Migration from SQL Server to PostgreSQL

## Overview
This document provides guidance for migrating the Bob's Used Bookstore database from SQL Server to PostgreSQL.

## Data Type Mappings

| SQL Server Type | PostgreSQL Type | Notes |
|----------------|----------------|-------|
| `nvarchar(max)` | `text` | Unlimited length text |
| `nvarchar(450)` | `varchar(450)` | Fixed length varchar |
| `int` | `integer` | 4-byte integer |
| `decimal(18,2)` | `numeric(18,2)` | Exact numeric |
| `datetime2` | `timestamp` | Date and time |
| `bit` | `boolean` | True/false |
| `uniqueidentifier` | `uuid` | Unique identifier |

## Schema Changes Required

### Customer Table
```sql
-- SQL Server
Sub nvarchar(450)

-- PostgreSQL  
Sub varchar(450)
```

### Indexes
All indexes are preserved. Unique index on `Customer.Sub` is maintained.

## Migration Steps

### Option 1: Using EF Core Migrations (Recommended for New Databases)

1. **Create Initial Migration**:
```bash
cd app/Bookstore.Web
dotnet ef migrations add InitialCreate --project ../Bookstore.Data
```

2. **Update Database**:
```bash
dotnet ef database update --project ../Bookstore.Data
```

3. **Seed Data**:
The application will automatically seed reference data on first run via `BookstoreDbInitializer.SeedAsync()`.

### Option 2: Manual Data Migration (For Existing Data)

1. **Export from SQL Server**:
```sql
-- Export to CSV files
EXEC sp_configure 'show advanced options', 1;
RECONFIGURE;
EXEC sp_configure 'xp_cmdshell', 1;
RECONFIGURE;

-- Export each table
EXEC xp_cmdshell 'bcp "SELECT * FROM BookStoreClassic.dbo.ReferenceData" queryout "C:\Temp\ReferenceData.csv" -c -t, -T -S localhost'
EXEC xp_cmdshell 'bcp "SELECT * FROM BookStoreClassic.dbo.Customer" queryout "C:\Temp\Customer.csv" -c -t, -T -S localhost'
-- Repeat for all tables
```

2. **Import to PostgreSQL**:
```bash
# Copy files to PostgreSQL server
# Import using psql
psql -U postgres -d BookStoreClassic

\COPY "ReferenceData" FROM 'ReferenceData.csv' WITH (FORMAT csv, DELIMITER ',');
\COPY "Customer" FROM 'Customer.csv' WITH (FORMAT csv, DELIMITER ',');
-- Repeat for all tables
```

3. **Reset Sequences**:
```sql
-- PostgreSQL auto-increment sequences need to be reset
SELECT setval('"ReferenceData_Id_seq"', (SELECT MAX("Id") FROM "ReferenceData"));
SELECT setval('"Customer_Id_seq"', (SELECT MAX("Id") FROM "Customer"));
SELECT setval('"Book_Id_seq"', (SELECT MAX("Id") FROM "Book"));
SELECT setval('"Order_Id_seq"', (SELECT MAX("Id") FROM "Order"));
SELECT setval('"OrderItem_Id_seq"', (SELECT MAX("Id") FROM "OrderItem"));
SELECT setval('"Offer_Id_seq"', (SELECT MAX("Id") FROM "Offer"));
SELECT setval('"Address_Id_seq"', (SELECT MAX("Id") FROM "Address"));
SELECT setval('"ShoppingCart_Id_seq"', (SELECT MAX("Id") FROM "ShoppingCart"));
```

### Option 3: Using Migration Tools

**pgloader** (Recommended for production data migration):
```bash
# Install pgloader
# Ubuntu/Debian
sudo apt-get install pgloader

# Create migration config
cat > bookstore-migration.load <<EOF
LOAD DATABASE
    FROM mssql://username:password@sqlserver-host/BookStoreClassic
    INTO postgresql://postgres:password@postgres-host/BookStoreClassic

WITH include drop, create tables, create indexes, reset sequences

CAST type datetime to timestamp drop default drop not null using zero-dates-to-null,
     type nvarchar to varchar

BEFORE LOAD DO
  \$\$ DROP SCHEMA IF EXISTS public CASCADE; \$\$,
  \$\$ CREATE SCHEMA public; \$\$;
EOF

# Run migration
pgloader bookstore-migration.load
```

## Verification Steps

### 1. Row Count Verification
```sql
-- SQL Server
SELECT 'ReferenceData' as TableName, COUNT(*) as RowCount FROM ReferenceData
UNION ALL
SELECT 'Customer', COUNT(*) FROM Customer
UNION ALL
SELECT 'Book', COUNT(*) FROM Book
UNION ALL
SELECT 'Order', COUNT(*) FROM [Order]
UNION ALL
SELECT 'Offer', COUNT(*) FROM Offer;

-- PostgreSQL (compare results)
SELECT 'ReferenceData' as TableName, COUNT(*) as RowCount FROM "ReferenceData"
UNION ALL
SELECT 'Customer', COUNT(*) FROM "Customer"
UNION ALL
SELECT 'Book', COUNT(*) FROM "Book"
UNION ALL
SELECT 'Order', COUNT(*) FROM "Order"
UNION ALL
SELECT 'Offer', COUNT(*) FROM "Offer";
```

### 2. Data Integrity Checks
```sql
-- Check for NULL values in required fields
SELECT * FROM "Customer" WHERE "Sub" IS NULL;
SELECT * FROM "Book" WHERE "Name" IS NULL OR "ISBN" IS NULL;

-- Verify foreign key relationships
SELECT b.* FROM "Book" b
LEFT JOIN "ReferenceData" g ON b."GenreId" = g."Id"
WHERE g."Id" IS NULL;
```

### 3. Application Testing
- Start the application
- Verify login functionality
- Test CRUD operations for each entity
- Verify search and filtering
- Test image upload
- Verify shopping cart functionality
- Test order placement

## Rollback Plan

Keep SQL Server database backups before migration:
```sql
BACKUP DATABASE BookStoreClassic 
TO DISK = 'C:\Backups\BookStoreClassic_PreMigration.bak'
WITH FORMAT, INIT, NAME = 'Pre-Migration Backup';
```

## Performance Tuning

### PostgreSQL Configuration
```sql
-- Add indexes for frequently queried columns
CREATE INDEX idx_book_name ON "Book"("Name");
CREATE INDEX idx_book_author ON "Book"("Author");
CREATE INDEX idx_order_customerid ON "Order"("CustomerId");
CREATE INDEX idx_order_createddate ON "Order"("CreatedDate");

-- Analyze tables for query optimization
ANALYZE "Book";
ANALYZE "Order";
ANALYZE "Customer";
```

### Connection Pooling
Update connection string for optimal pooling:
```
Host=postgres-host;Database=BookStoreClassic;Username=postgres;Password=password;Pooling=true;MinPoolSize=5;MaxPoolSize=100;
```

## Common Issues and Solutions

### Issue 1: Case Sensitivity
**Problem**: PostgreSQL is case-sensitive for identifiers in quotes.
**Solution**: EF Core automatically quotes identifiers. Ensure table names match exactly.

### Issue 2: Date/Time Handling
**Problem**: SQL Server `datetime2` vs PostgreSQL `timestamp`.
**Solution**: EF Core handles conversion automatically. Ensure timezone-aware queries if needed.

### Issue 3: String Comparison
**Problem**: SQL Server is case-insensitive by default, PostgreSQL is case-sensitive.
**Solution**: Use `ILIKE` for case-insensitive searches or create case-insensitive collations:
```sql
CREATE COLLATION case_insensitive (provider = icu, locale = 'und-u-ks-level2', deterministic = false);
ALTER TABLE "Customer" ALTER COLUMN "Email" TYPE varchar(255) COLLATE case_insensitive;
```

### Issue 4: Identity Columns
**Problem**: SQL Server uses `IDENTITY`, PostgreSQL uses `SERIAL`/`SEQUENCE`.
**Solution**: EF Core creates sequences automatically. No action needed.

## Timeline Estimate
- Small dataset (< 10,000 records): 1-2 hours
- Medium dataset (10,000 - 100,000 records): 4-8 hours  
- Large dataset (> 100,000 records): 1-2 days

## Contact and Support
Refer to the main documentation in `/doc/migration-analysis/database-migration.md` for detailed analysis.
