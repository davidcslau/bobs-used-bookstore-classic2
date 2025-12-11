# Entity Framework Configuration

## Overview

The application uses Entity Framework 6.5.1 with a Code-First approach. The `ApplicationDbContext` class serves as the central point for database configuration and entity management.

## ApplicationDbContext

### Location
`Bookstore.Data/ApplicationDbContext.cs`

### Implementation

```csharp
public class ApplicationDbContext : DbContext
{
    public ApplicationDbContext(string connectionString) : base(connectionString) { }

    public DbSet<Address> Address { get; set; }
    public DbSet<Book> Book { get; set; }
    public DbSet<Customer> Customer { get; set; }
    public DbSet<Order> Order { get; set; }
    public DbSet<ShoppingCart> ShoppingCart { get; set; }
    public DbSet<OrderItem> OrderItem { get; set; }
    public DbSet<Offer> Offer { get; set; }
    public DbSet<ReferenceDataItem> ReferenceData { get; set; }

    protected override void OnModelCreating(DbModelBuilder modelBuilder)
    {
        // Configuration...
    }
}
```

### Constructor Configuration
- Accepts connection string as parameter
- Passed from dependency injection container
- Retrieved from configuration at runtime

### Lifetime Management
- **Scope**: InstancePerRequest (Autofac)
- Created once per HTTP request
- Automatically disposed at end of request
- Provides Unit of Work pattern

## DbSet Declarations

### Entity Sets
Each DbSet<T> represents a table in the database:

```csharp
public DbSet<Book> Book { get; set; }          // Books table
public DbSet<Customer> Customer { get; set; }  // Customer table
public DbSet<Order> Order { get; set; }        // Order table
public DbSet<OrderItem> OrderItem { get; set; } // OrderItem table
public DbSet<ShoppingCart> ShoppingCart { get; set; } // ShoppingCart table
public DbSet<Address> Address { get; set; }    // Address table
public DbSet<Offer> Offer { get; set; }        // Offer table
public DbSet<ReferenceDataItem> ReferenceData { get; set; } // ReferenceData table
```

Note: ShoppingCartItem is not exposed as DbSet but accessible through ShoppingCart navigation property.

## Fluent API Configuration

### Convention Removal

```csharp
// Remove pluralization to use singular table names
modelBuilder.Conventions.Remove<PluralizingTableNameConvention>();
```

**Rationale**: Singular table names match entity names for consistency.

### Customer Configuration

```csharp
// Configure Sub column as unique identifier
modelBuilder.Entity<Customer>()
    .Property(x => x.Sub)
    .HasColumnType("nvarchar")
    .HasMaxLength(450);

// Create unique index on Sub
modelBuilder.Entity<Customer>()
    .HasIndex(x => x.Sub)
    .IsUnique();
```

**Purpose**: 
- Sub field stores authentication provider subject ID (from Cognito)
- Must be unique to prevent duplicate accounts
- Limited to 450 characters (SQL Server index limitation)

### Book Relationships

```csharp
// Publisher relationship
modelBuilder.Entity<Book>()
    .HasRequired(x => x.Publisher)
    .WithMany()
    .HasForeignKey(x => x.PublisherId)
    .WillCascadeOnDelete(false);

// BookType relationship
modelBuilder.Entity<Book>()
    .HasRequired(x => x.BookType)
    .WithMany()
    .HasForeignKey(x => x.BookTypeId)
    .WillCascadeOnDelete(false);

// Genre relationship
modelBuilder.Entity<Book>()
    .HasRequired(x => x.Genre)
    .WithMany()
    .HasForeignKey(x => x.GenreId)
    .WillCascadeOnDelete(false);

// Condition relationship
modelBuilder.Entity<Book>()
    .HasRequired(x => x.Condition)
    .WithMany()
    .HasForeignKey(x => x.ConditionId)
    .WillCascadeOnDelete(false);
```

**Key Points**:
- HasRequired: Foreign key cannot be null
- WithMany: One reference data can have many books
- WillCascadeOnDelete(false): Prevent accidental deletion of books when reference data is deleted

### Offer Relationships

```csharp
// Same pattern as Book for reference data relationships
modelBuilder.Entity<Offer>()
    .HasRequired(x => x.Publisher)
    .WithMany()
    .HasForeignKey(x => x.PublisherId)
    .WillCascadeOnDelete(false);

// Similar for BookType, Genre, Condition
```

### Order Configuration

```csharp
modelBuilder.Entity<Order>()
    .HasRequired(x => x.Customer)
    .WithMany()
    .WillCascadeOnDelete(false);
```

**Rationale**: Orders should not be deleted if customer is deleted (data retention).

### ReferenceData Table Mapping

```csharp
modelBuilder.Entity<ReferenceDataItem>()
    .ToTable("ReferenceData");
```

**Purpose**: Explicitly map entity to specific table name (matches database script).

### ShoppingCartItem Composite Key

```csharp
// Define composite primary key
modelBuilder.Entity<ShoppingCartItem>()
    .HasKey(x => new { x.Id, x.ShoppingCartId });

// Configure Id as identity column within composite key
modelBuilder.Entity<ShoppingCartItem>()
    .Property(x => x.Id)
    .HasDatabaseGeneratedOption(DatabaseGeneratedOption.Identity);
```

**Rationale**: 
- Composite key (Id, ShoppingCartId) ensures uniqueness per cart
- Id auto-increments for line item tracking
- Supports multiple carts with same item Id values

### Database Initializer

```csharp
Database.SetInitializer(new BookstoreDbInitializer());
```

**Purpose**: Seed reference data on first database creation.

## Entity Framework Features Used

### 1. Code-First Approach
- Entities define database schema
- No need for database-first or manual SQL
- Migrations can track schema changes

### 2. Lazy Loading
```csharp
// Navigation properties load on demand
var book = await context.Book.FindAsync(id);
var publisher = book.Publisher; // Lazy loaded here
```

### 3. Eager Loading
```csharp
// Load related entities upfront
var books = await context.Book
    .Include(x => x.Genre)
    .Include(x => x.Publisher)
    .Include(x => x.BookType)
    .Include(x => x.Condition)
    .ToListAsync();
```

### 4. Async Operations
```csharp
await context.Book.ToListAsync();
await context.SaveChangesAsync();
await context.Book.FindAsync(id);
await context.Book.SingleAsync(x => x.Id == id);
```

### 5. Change Tracking
- DbContext automatically tracks entity changes
- SaveChanges() generates appropriate SQL (INSERT, UPDATE, DELETE)

### 6. Optimistic Concurrency
```csharp
public byte[] RowVersion { get; set; } // In Entity base class
```
- Timestamp field used for concurrency detection
- DbUpdateConcurrencyException thrown on conflicts

## Connection String Management

### Development
```xml
<connectionStrings>
  <add name="BookstoreDatabaseConnection" 
       connectionString="Server=(localdb)\MSSQLLocalDB;Initial Catalog=BookStoreClassic;MultipleActiveResultSets=true;Integrated Security=SSPI;" 
       providerName="System.Data.SqlClient" />
</connectionStrings>
```

### Production (AWS RDS)
Retrieved from AWS Systems Manager Parameter Store:
```csharp
var connectionString = BookstoreConfiguration.GetConnectionString("BookstoreDatabaseConnection");
```

### Key Settings
- **MultipleActiveResultSets=true**: Allows multiple result sets on one connection
- **Integrated Security=SSPI**: Windows authentication (dev)
- **SQL Authentication**: Used in production with username/password

## Database Initialization

### BookstoreDbInitializer

**Location**: `Bookstore.Data/BookstoreDbInitializer.cs`

**Purpose**: Seed initial reference data required for application to function.

**Seed Data**:
- Genres (Fiction, Non-Fiction, Mystery, etc.)
- Publishers
- Book Types (Hardcover, Paperback, etc.)
- Conditions (New, Like New, Good, Acceptable)

**Execution**: Runs on first access if database doesn't exist.

## Migration Strategy

### EF 6.x Migrations (Not currently enabled)
```bash
# Enable migrations
Enable-Migrations

# Add migration
Add-Migration InitialCreate

# Update database
Update-Database
```

### Current Approach
- Database initializer creates schema on first run
- Manual SQL script available for production deployment
- No automated migration history

## Query Optimization Patterns

### 1. Include for Eager Loading
```csharp
var books = await context.Book
    .Include(x => x.Genre)
    .Include(x => x.Publisher)
    .ToListAsync();
```

### 2. AsNoTracking for Read-Only
```csharp
var books = await context.Book
    .AsNoTracking()
    .ToListAsync();
```
**Benefit**: Better performance when entities won't be modified.

### 3. Pagination
```csharp
var books = await context.Book
    .OrderBy(x => x.Name)
    .Skip((pageIndex - 1) * pageSize)
    .Take(pageSize)
    .ToListAsync();
```

### 4. Selective Loading
```csharp
// Only load needed fields
var bookNames = await context.Book
    .Select(x => new { x.Id, x.Name })
    .ToListAsync();
```

## Transaction Management

### Implicit Transactions
```csharp
// Single SaveChanges() is automatically wrapped in transaction
order.AddOrderItem(book, quantity);
book.ReduceStockLevel(quantity);
await context.SaveChangesAsync(); // Both updates in one transaction
```

### Explicit Transactions
```csharp
using (var transaction = context.Database.BeginTransaction())
{
    try
    {
        await context.SaveChangesAsync();
        // Other operations
        transaction.Commit();
    }
    catch
    {
        transaction.Rollback();
        throw;
    }
}
```

## EF 6.x to EF Core Migration Considerations

### Changes Required
1. **Namespace**: `System.Data.Entity` → `Microsoft.EntityFrameworkCore`
2. **DbSet**: Similar but some API differences
3. **Fluent API**: Different syntax for relationships
4. **Lazy Loading**: Requires explicit configuration in EF Core
5. **Include**: String-based Include() not recommended in EF Core
6. **Migrations**: Different command structure
7. **Database Initializer**: Different seeding approach

### Breaking Changes
- No more `Database.SetInitializer()`
- Change `HasRequired/HasOptional` to `IsRequired()`
- Change `WillCascadeOnDelete()` to `OnDelete(DeleteBehavior)`
- Composite keys use `HasKey()` differently
- Connection string management different

### Example EF Core Conversion
```csharp
// EF 6.x
modelBuilder.Entity<Book>()
    .HasRequired(x => x.Publisher)
    .WithMany()
    .HasForeignKey(x => x.PublisherId)
    .WillCascadeOnDelete(false);

// EF Core
modelBuilder.Entity<Book>()
    .HasOne(x => x.Publisher)
    .WithMany()
    .HasForeignKey(x => x.PublisherId)
    .OnDelete(DeleteBehavior.Restrict);
```

## Performance Characteristics

### Query Performance
- Simple queries: < 100ms
- Complex queries with includes: 100-500ms
- Pagination: Efficient with proper indexes

### Memory Usage
- DbContext: ~10-50MB depending on tracked entities
- Connection pooling: Reduces overhead
- Dispose properly to release resources

### Connection Pooling
- Enabled by default
- Min Pool Size: 0
- Max Pool Size: 100 (default)

## Best Practices Applied

1. ✅ **One DbContext per request**: InstancePerRequest lifetime
2. ✅ **Async/await**: All database operations are async
3. ✅ **Explicit loading control**: Use Include() vs lazy loading
4. ✅ **Connection string externalization**: Configuration-based
5. ✅ **No cascade deletes**: Explicit data management
6. ✅ **Concurrency tokens**: RowVersion fields

## Summary

The Entity Framework configuration is straightforward with Code-First approach, fluent API for relationships, and proper lifetime management. The configuration focuses on:
- Singular table names
- No cascade deletes for data safety
- Composite key support for ShoppingCartItem
- Unique constraint on Customer.Sub
- Database initialization for reference data

The migration to EF Core will require updates to fluent API syntax and namespace changes but the overall structure and patterns can remain similar.
