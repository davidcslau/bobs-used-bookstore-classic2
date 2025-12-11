# Database Migration: SQL Server to PostgreSQL

## Current State: SQL Server

- SQL Server 2016+ (LocalDB for dev)
- System.Data.SqlClient provider
- T-SQL syntax
- Windows authentication (dev) / SQL auth (prod)

## Target State: PostgreSQL

- PostgreSQL 13+
- Npgsql provider
- PostgreSQL syntax
- Username/password authentication
- Connection string format differences

## Data Type Mappings

### Strings
- `nvarchar(MAX)` → `text` or `varchar`
- `nvarchar(450)` → `varchar(450)`
- Unicode supported by default in PostgreSQL

### Numbers
- `int` → `integer`
- `bigint` → `bigint`
- `decimal(18,2)` → `numeric(18,2)`

### Date/Time
- `datetime` → `timestamp` or `timestamptz`
- Consider timezone handling

### Boolean
- `bit` → `boolean`

### Binary
- `timestamp` (row version) → `bytea` with triggers or use `xmin` system column

### Identity Columns
- `IDENTITY(1,1)` → `SERIAL` or `GENERATED ALWAYS AS IDENTITY`

## Syntax Differences

### String Comparison
**SQL Server**: Case-insensitive by default
```sql
WHERE Name LIKE '%book%'
```

**PostgreSQL**: Case-sensitive by default
```sql
WHERE Name ILIKE '%book%'  -- Case-insensitive
-- OR
WHERE LOWER(Name) LIKE LOWER('%book%')
```

### Date Functions
**SQL Server**:
```sql
GETDATE()
DATEADD(day, 7, GETDATE())
```

**PostgreSQL**:
```sql
NOW() or CURRENT_TIMESTAMP
CURRENT_DATE + INTERVAL '7 days'
```

### TOP vs LIMIT
**SQL Server**:
```sql
SELECT TOP 10 * FROM Book
```

**PostgreSQL**:
```sql
SELECT * FROM Book LIMIT 10
```

### String Concatenation
**SQL Server**: `+` operator
**PostgreSQL**: `||` operator or `CONCAT()`

### Sequences
**SQL Server**: IDENTITY columns
**PostgreSQL**: SERIAL type or explicit SEQUENCE

## EF Core Provider Changes

### Package Reference
**SQL Server**:
```xml
<PackageReference Include="Microsoft.EntityFrameworkCore.SqlServer" Version="8.0.x" />
```

**PostgreSQL**:
```xml
<PackageReference Include="Npgsql.EntityFrameworkCore.PostgreSQL" Version="8.0.x" />
```

### DbContext Configuration
**SQL Server**:
```csharp
services.AddDbContext<ApplicationDbContext>(options =>
    options.UseSqlServer(connectionString));
```

**PostgreSQL**:
```csharp
services.AddDbContext<ApplicationDbContext>(options =>
    options.UseNpgsql(connectionString));
```

### Connection Strings
**SQL Server**:
```
Server=(localdb)\MSSQLLocalDB;Initial Catalog=BookStoreClassic;Integrated Security=SSPI;
```

**PostgreSQL**:
```
Host=localhost;Database=bookstoreclassic;Username=postgres;Password=password;
```

## Migration Strategy

### Approach 1: Schema-First
1. Export SQL Server schema
2. Convert to PostgreSQL schema
3. Migrate data using tools
4. Update EF Core provider
5. Test thoroughly

### Approach 2: Code-First (Recommended)
1. Update EF Core provider to Npgsql
2. Generate new migration for PostgreSQL
3. Apply migration to create schema
4. Migrate data separately
5. Test thoroughly

### Approach 3: Side-by-Side
1. Run both databases temporarily
2. Gradually migrate features
3. Verify data consistency
4. Switch over when ready

## Data Migration Tools

### pgloader
- Automated migration from SQL Server to PostgreSQL
- Handles data type conversion
- Can migrate schema and data

```bash
pgloader mssql://user:pass@server/database pgsql://user:pass@server/database
```

### Custom Scripts
- Export data to CSV
- Import to PostgreSQL using COPY
- More control but more effort

### AWS Database Migration Service (DMS)
- Managed service for database migration
- Supports SQL Server to PostgreSQL
- Handles ongoing replication

## Code Changes Required

### 1. Case-Sensitive Queries
Update LINQ queries that rely on case-insensitive comparison:

```csharp
// May need updates
.Where(x => x.Name.Contains(searchTerm))

// Consider using
.Where(x => x.Name.ToLower().Contains(searchTerm.ToLower()))
// Or configure EF Core for case-insensitive collation
```

### 2. Date Handling
Review date arithmetic:

```csharp
// C# code should remain similar
DeliveryDate = DateTime.Now.AddDays(7)

// But verify SQL generation
```

### 3. String Functions
Most LINQ operations translate correctly, but test:
- String.Contains()
- String.StartsWith()
- String.EndsWith()

### 4. Concurrency Tokens
PostgreSQL doesn't have `timestamp` (rowversion) equivalent:

**Options**:
1. Use `xmin` system column (PostgreSQL specific)
2. Use manual version column (int, increment on update)
3. Use triggers to maintain version

```csharp
modelBuilder.Entity<Book>()
    .Property(b => b.xmin)
    .IsRowVersion();
```

## Testing Strategy

### 1. Schema Validation
- Verify all tables created correctly
- Check foreign keys and constraints
- Verify indexes

### 2. Data Validation
- Compare record counts
- Verify data integrity
- Check for data loss or corruption

### 3. Query Testing
- Run all application queries
- Verify results match
- Check for performance issues

### 4. Application Testing
- Full end-to-end testing
- Verify all CRUD operations
- Test edge cases

## PostgreSQL Advantages

1. **Open Source**: No licensing costs
2. **Linux Native**: Better Linux performance
3. **Advanced Features**: JSON, arrays, full-text search
4. **ACID Compliance**: Strong consistency guarantees
5. **Extensions**: PostGIS, pg_trgm, etc.
6. **Community**: Large, active community

## Potential Challenges

1. **Case Sensitivity**: Requires code updates
2. **Different Syntax**: Some queries may need adjustment
3. **Tooling**: Different management tools (pgAdmin vs SSMS)
4. **Performance Tuning**: Different optimization strategies
5. **Backup/Restore**: Different procedures

## Migration Checklist

- [ ] Install PostgreSQL locally for development
- [ ] Update EF Core provider to Npgsql
- [ ] Generate PostgreSQL migration
- [ ] Test schema creation
- [ ] Plan data migration strategy
- [ ] Execute data migration (staging)
- [ ] Update connection strings
- [ ] Test all queries
- [ ] Performance testing
- [ ] Update documentation

## Effort Estimate

- **Provider update**: 2 hours
- **Schema migration**: 4-6 hours
- **Data migration**: 4-8 hours (depending on volume)
- **Code updates**: 6-10 hours
- **Testing**: 10-15 hours
- **Performance tuning**: 5-10 hours

**Total**: 31-51 hours
