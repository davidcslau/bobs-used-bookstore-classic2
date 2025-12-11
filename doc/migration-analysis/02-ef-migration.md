# Entity Framework 6.x to EF Core Migration

## Current State: EF 6.5.1

- Code-First approach
- System.Data.Entity namespace
- Fluent API configuration
- DbContext with DbSet<T> properties
- Entity Framework SQL Server provider

## Target State: EF Core 8.0

- Microsoft.EntityFrameworkCore namespace
- Similar Code-First approach
- Updated Fluent API syntax
- DbContext structure similar
- Provider-agnostic design

## Key Differences

### 1. Namespace Changes
```csharp
// EF 6.x
using System.Data.Entity;

// EF Core
using Microsoft.EntityFrameworkCore;
```

### 2. DbContext Configuration

**EF 6.x**:
```csharp
public ApplicationDbContext(string connectionString) : base(connectionString) { }
```

**EF Core**:
```csharp
public ApplicationDbContext(DbContextOptions<ApplicationDbContext> options) 
    : base(options) { }
```

### 3. Fluent API Relationship Configuration

**EF 6.x**:
```csharp
modelBuilder.Entity<Book>()
    .HasRequired(x => x.Publisher)
    .WithMany()
    .HasForeignKey(x => x.PublisherId)
    .WillCascadeOnDelete(false);
```

**EF Core**:
```csharp
modelBuilder.Entity<Book>()
    .HasOne(x => x.Publisher)
    .WithMany()
    .HasForeignKey(x => x.PublisherId)
    .OnDelete(DeleteBehavior.Restrict);
```

### 4. String-Based Include()

**EF 6.x** (deprecated but works):
```csharp
.Include("OrderItems.Book")
```

**EF Core** (strongly-typed recommended):
```csharp
.Include(x => x.OrderItems)
    .ThenInclude(x => x.Book)
```

### 5. Lazy Loading

**EF 6.x**: Enabled by default

**EF Core**: Must explicitly enable
```csharp
services.AddDbContext<ApplicationDbContext>(options =>
    options.UseLazyLoadingProxies());
```

### 6. Database Initializer

**EF 6.x**:
```csharp
Database.SetInitializer(new BookstoreDbInitializer());
```

**EF Core**: Use migrations and seed data in OnModelCreating
```csharp
protected override void OnModelCreating(ModelBuilder modelBuilder)
{
    modelBuilder.Entity<ReferenceDataItem>().HasData(
        new ReferenceDataItem { Id = 1, DataType = ReferenceDataType.Genre, Text = "Fiction" }
    );
}
```

### 7. Async Methods

Most async methods have same signatures but may have different behavior or performance characteristics.

### 8. Migrations

**EF 6.x**:
```bash
Enable-Migrations
Add-Migration InitialCreate
Update-Database
```

**EF Core**:
```bash
dotnet ef migrations add InitialCreate
dotnet ef database update
```

## Migration Tasks

### 1. Package References
**Remove**:
- EntityFramework 6.5.1

**Add**:
- Microsoft.EntityFrameworkCore 8.0.x
- Microsoft.EntityFrameworkCore.SqlServer 8.0.x (or Npgsql.EntityFrameworkCore.PostgreSQL)
- Microsoft.EntityFrameworkCore.Tools 8.0.x
- Microsoft.EntityFrameworkCore.Design 8.0.x

### 2. Update ApplicationDbContext

**Constructor**:
```csharp
// Change from
public ApplicationDbContext(string connectionString) : base(connectionString) { }

// To
public ApplicationDbContext(DbContextOptions<ApplicationDbContext> options) 
    : base(options) { }
```

**OnModelCreating** - Update all fluent API calls:
- HasRequired → HasOne
- HasOptional → HasOne
- WithMany stays the same
- WillCascadeOnDelete → OnDelete(DeleteBehavior.Restrict)

### 3. Update Repository Implementations

**Include Statements**:
```csharp
// Change string-based includes
.Include("OrderItems.Book")

// To strongly-typed
.Include(x => x.OrderItems)
    .ThenInclude(x => x.Book)
```

**Find Usage**: Review all `.Find()` and `.FindAsync()` calls (behavior may differ)

### 4. Registration in DI

**EF 6.x (Autofac)**:
```csharp
var connectionString = BookstoreConfiguration.GetConnectionString("BookstoreDatabaseConnection");
builder.RegisterType<ApplicationDbContext>()
    .WithParameter("connectionString", connectionString)
    .InstancePerRequest();
```

**EF Core (Built-in DI)**:
```csharp
services.AddDbContext<ApplicationDbContext>(options =>
    options.UseSqlServer(configuration.GetConnectionString("BookstoreDatabaseConnection")));
```

### 5. Composite Key Configuration

**EF 6.x**:
```csharp
modelBuilder.Entity<ShoppingCartItem>()
    .HasKey(x => new { x.Id, x.ShoppingCartId });

modelBuilder.Entity<ShoppingCartItem>()
    .Property(x => x.Id)
    .HasDatabaseGeneratedOption(DatabaseGeneratedOption.Identity);
```

**EF Core**:
```csharp
modelBuilder.Entity<ShoppingCartItem>()
    .HasKey(x => new { x.Id, x.ShoppingCartId });

modelBuilder.Entity<ShoppingCartItem>()
    .Property(x => x.Id)
    .ValueGeneratedOnAdd();
```

### 6. Index Configuration

**EF 6.x**:
```csharp
modelBuilder.Entity<Customer>()
    .HasIndex(x => x.Sub)
    .IsUnique();
```

**EF Core** (same):
```csharp
modelBuilder.Entity<Customer>()
    .HasIndex(x => x.Sub)
    .IsUnique();
```

### 7. Convention Removal

**EF 6.x**:
```csharp
modelBuilder.Conventions.Remove<PluralizingTableNameConvention>();
```

**EF Core**: Use explicit table naming or configure conventions differently
```csharp
// No direct equivalent, but can use
modelBuilder.Entity<Book>().ToTable("Book");
// Or configure globally
```

## Testing Strategy

### 1. Unit Tests
- Mock DbContext using in-memory provider
- Test repository methods
- Verify LINQ query translation

### 2. Integration Tests
- Use in-memory database for fast tests
- Test actual database operations
- Verify migrations

### 3. Performance Testing
- Compare query performance
- Check for N+1 query issues
- Verify connection pooling

## Known Issues and Solutions

### Issue 1: Lazy Loading
**Problem**: Lazy loading disabled by default in EF Core

**Solutions**:
1. Enable lazy loading proxies (requires virtual navigation properties)
2. Use explicit loading: `.Load()`
3. Use eager loading: `.Include()`

**Recommendation**: Use explicit eager loading for better control

### Issue 2: String Include()
**Problem**: String-based Include deprecated in EF Core

**Solution**: Convert all to strongly-typed:
```csharp
.Include(x => x.OrderItems)
    .ThenInclude(x => x.Book)
```

### Issue 3: Database Initializer
**Problem**: No SetInitializer in EF Core

**Solution**: Use migrations with seed data:
```csharp
protected override void OnModelCreating(ModelBuilder modelBuilder)
{
    modelBuilder.Entity<ReferenceDataItem>().HasData(/* seed data */);
}
```

### Issue 4: Client-Side Evaluation
**Problem**: EF Core 3.0+ doesn't allow client-side evaluation by default

**Solution**: Explicitly use `.AsEnumerable()` or `.ToList()` before client evaluation

## Migration Checklist

- [ ] Update package references
- [ ] Update namespaces
- [ ] Update DbContext constructor
- [ ] Convert all fluent API configuration
- [ ] Update string-based Include() to strongly-typed
- [ ] Update DI registration
- [ ] Create initial migration
- [ ] Test all repository methods
- [ ] Performance testing
- [ ] Update seed data approach

## Effort Estimate

- **Package updates**: 1 hour
- **DbContext conversion**: 2-3 hours
- **Fluent API updates**: 3-4 hours
- **Repository updates**: 4-5 hours
- **Testing**: 5-10 hours
- **Documentation**: 2 hours

**Total**: 17-25 hours
