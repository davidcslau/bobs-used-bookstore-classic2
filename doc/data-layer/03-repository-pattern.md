# Repository Pattern Implementation

## Overview

The application implements the Repository pattern to abstract data access logic and provide a clean API for business services. Repository interfaces are defined in the Domain layer while implementations reside in the Data layer.

## Repository Architecture

```
Domain Layer (Bookstore.Domain)
  └── Interfaces (IBookRepository, ICustomerRepository, etc.)

Data Layer (Bookstore.Data)
  └── Repositories/
      ├── BookRepository.cs
      ├── CustomerRepository.cs
      ├── OrderRepository.cs
      ├── ShoppingCartRepository.cs
      ├── AddressRepository.cs
      ├── OfferRepository.cs
      └── ReferenceDataRepository.cs
```

## Repository Implementations

### 1. BookRepository

**Interface**: `IBookRepository` (Bookstore.Domain/Books/)
**Implementation**: `BookRepository` (Bookstore.Data/Repositories/)

**Methods**:

```csharp
Task<Book> GetAsync(int id);
Task<IPaginatedList<Book>> ListAsync(BookFilters filters, int pageIndex, int pageSize);
Task<IPaginatedList<Book>> ListAsync(string searchString, string sortBy, int pageIndex, int pageSize);
Task AddAsync(Book book);
Task UpdateAsync(Book book);
Task SaveChangesAsync();
Task<BookStatistics> GetStatisticsAsync();
```

**Key Features**:
- Supports filtering by name, author, genre, publisher, condition, book type
- Low stock filtering
- Search across multiple fields
- Pagination support
- Eager loading of related entities
- Statistics calculation (low stock, out of stock counts)

**Implementation Highlights**:

```csharp
public async Task<IPaginatedList<Book>> ListAsync(BookFilters filters, int pageIndex, int pageSize)
{
    var query = dbContext.Book.AsQueryable();

    // Apply filters
    if (!string.IsNullOrWhiteSpace(filters.Name))
        query = query.Where(x => x.Name.Contains(filters.Name));
    
    if (!string.IsNullOrWhiteSpace(filters.Author))
        query = query.Where(x => x.Author.Contains(filters.Author));
    
    if (filters.ConditionId.HasValue)
        query = query.Where(x => x.ConditionId == filters.ConditionId);
    
    if (filters.LowStock)
        query = query.Where(x => x.Quantity <= Book.LowBookThreshold);

    // Include related entities
    query = query
        .Include(x => x.Genre)
        .Include(x => x.Publisher)
        .Include(x => x.BookType)
        .Include(x => x.Condition);

    // Create and populate paginated list
    var result = new PaginatedList<Book>(query, pageIndex, pageSize);
    await result.PopulateAsync();
    
    return result;
}
```

### 2. CustomerRepository

**Interface**: `ICustomerRepository` (Bookstore.Domain/Customers/)
**Implementation**: `CustomerRepository` (Bookstore.Data/Repositories/)

**Methods**:

```csharp
Task<Customer> GetByIdAsync(int id);
Task<Customer> GetBySubAsync(string sub);
Task AddAsync(Customer customer);
Task UpdateAsync(Customer customer);
Task SaveChangesAsync();
```

**Key Features**:
- Lookup by ID or authentication Sub (subject identifier)
- Support for authentication provider integration
- Create or update pattern for user registration

**Implementation Highlights**:

```csharp
public async Task<Customer> GetBySubAsync(string sub)
{
    return await dbContext.Customer
        .SingleOrDefaultAsync(x => x.Sub == sub);
}
```

### 3. OrderRepository

**Interface**: `IOrderRepository` (Bookstore.Domain/Orders/)
**Implementation**: `OrderRepository` (Bookstore.Data/Repositories/)

**Methods**:

```csharp
Task<Order> GetAsync(int id);
Task<IPaginatedList<Order>> ListAsync(int customerId, int pageIndex, int pageSize);
Task<IPaginatedList<Order>> ListAsync(OrderFilters filters, int pageIndex, int pageSize);
Task AddAsync(Order order);
Task UpdateAsync(Order order);
Task SaveChangesAsync();
Task<OrderStatistics> GetStatisticsAsync();
```

**Key Features**:
- Filter orders by customer
- Filter by order status
- Include order items and customer details
- Statistics for admin dashboard
- Pagination for order history

**Implementation Highlights**:

```csharp
public async Task<IPaginatedList<Order>> ListAsync(int customerId, int pageIndex, int pageSize)
{
    var query = dbContext.Order
        .Where(x => x.CustomerId == customerId)
        .Include(x => x.OrderItems)
        .Include("OrderItems.Book")
        .Include(x => x.Address)
        .OrderByDescending(x => x.CreatedOn);

    var result = new PaginatedList<Order>(query, pageIndex, pageSize);
    await result.PopulateAsync();
    
    return result;
}
```

### 4. ShoppingCartRepository

**Interface**: `IShoppingCartRepository` (Bookstore.Domain/Carts/)
**Implementation**: `ShoppingCartRepository` (Bookstore.Data/Repositories/)

**Methods**:

```csharp
Task<ShoppingCart> GetByCorrelationIdAsync(string correlationId);
Task AddAsync(ShoppingCart cart);
Task UpdateAsync(ShoppingCart cart);
Task DeleteAsync(ShoppingCart cart);
Task SaveChangesAsync();
```

**Key Features**:
- Lookup by correlation ID (session/user identifier)
- Include shopping cart items and books
- Support for cart and wishlist items
- Delete cart after checkout

**Implementation Highlights**:

```csharp
public async Task<ShoppingCart> GetByCorrelationIdAsync(string correlationId)
{
    return await dbContext.ShoppingCart
        .Include(x => x.ShoppingCartItems)
        .Include("ShoppingCartItems.Book")
        .Include("ShoppingCartItems.Book.Genre")
        .Include("ShoppingCartItems.Book.Condition")
        .SingleOrDefaultAsync(x => x.CorrelationId == correlationId);
}
```

### 5. AddressRepository

**Interface**: `IAddressRepository` (Bookstore.Domain/Addresses/)
**Implementation**: `AddressRepository` (Bookstore.Data/Repositories/)

**Methods**:

```csharp
Task<Address> GetAsync(int id);
Task<IEnumerable<Address>> ListAsync(int customerId);
Task AddAsync(Address address);
Task UpdateAsync(Address address);
Task SaveChangesAsync();
```

**Key Features**:
- List addresses by customer
- Filter active addresses
- Simple CRUD operations

**Implementation Highlights**:

```csharp
public async Task<IEnumerable<Address>> ListAsync(int customerId)
{
    return await dbContext.Address
        .Where(x => x.CustomerId == customerId && x.IsActive)
        .ToListAsync();
}
```

### 6. OfferRepository

**Interface**: `IOfferRepository` (Bookstore.Domain/Offers/)
**Implementation**: `OfferRepository` (Bookstore.Data/Repositories/)

**Methods**:

```csharp
Task<Offer> GetAsync(int id);
Task<IPaginatedList<Offer>> ListAsync(int customerId, int pageIndex, int pageSize);
Task<IPaginatedList<Offer>> ListAsync(OfferFilters filters, int pageIndex, int pageSize);
Task AddAsync(Offer offer);
Task UpdateAsync(Offer offer);
Task SaveChangesAsync();
Task<OfferStatistics> GetStatisticsAsync();
```

**Key Features**:
- Filter by customer
- Filter by offer status (pending, approved, rejected)
- Include related customer and reference data
- Statistics for admin dashboard

### 7. ReferenceDataRepository

**Interface**: `IReferenceDataRepository` (Bookstore.Domain/ReferenceData/)
**Implementation**: `ReferenceDataRepository` (Bookstore.Data/Repositories/)

**Methods**:

```csharp
Task<ReferenceDataItem> GetAsync(int id);
Task<IEnumerable<ReferenceDataItem>> ListAsync(ReferenceDataType dataType);
Task<IEnumerable<ReferenceDataItem>> ListAsync();
Task AddAsync(ReferenceDataItem item);
Task UpdateAsync(ReferenceDataItem item);
Task DeleteAsync(int id);
Task SaveChangesAsync();
```

**Key Features**:
- Filter by reference data type (Genre, Publisher, BookType, Condition)
- List all reference data
- CRUD operations for admin management

**Implementation Highlights**:

```csharp
public async Task<IEnumerable<ReferenceDataItem>> ListAsync(ReferenceDataType dataType)
{
    return await dbContext.ReferenceData
        .Where(x => x.DataType == dataType)
        .OrderBy(x => x.Text)
        .ToListAsync();
}
```

## Common Patterns

### 1. Constructor Injection

All repositories receive DbContext via constructor:

```csharp
public class BookRepository : IBookRepository
{
    private readonly ApplicationDbContext dbContext;

    public BookRepository(ApplicationDbContext dbContext)
    {
        this.dbContext = dbContext;
    }
}
```

### 2. Async Operations

All repository methods are async:

```csharp
Task<Book> GetAsync(int id);
Task SaveChangesAsync();
```

### 3. Eager Loading

Related entities loaded explicitly:

```csharp
return await dbContext.Book
    .Include(x => x.Genre)
    .Include(x => x.Publisher)
    .SingleAsync(x => x.Id == id);
```

### 4. Pagination

Using PaginatedList<T> helper:

```csharp
var result = new PaginatedList<Book>(query, pageIndex, pageSize);
await result.PopulateAsync();
return result;
```

### 5. SaveChanges Pattern

Separate SaveChanges method (Unit of Work):

```csharp
await repository.AddAsync(book);
await repository.SaveChangesAsync(); // Commits transaction
```

## PaginatedList Helper

**Location**: `Bookstore.Data/PaginatedList.cs`

**Purpose**: Provides pagination support with metadata

```csharp
public class PaginatedList<T> : IPaginatedList<T>
{
    public List<T> Items { get; set; }
    public int PageIndex { get; set; }
    public int PageSize { get; set; }
    public int TotalCount { get; set; }
    public int TotalPages => (int)Math.Ceiling(TotalCount / (double)PageSize);
    public bool HasPreviousPage => PageIndex > 1;
    public bool HasNextPage => PageIndex < TotalPages;

    public async Task PopulateAsync()
    {
        TotalCount = await query.CountAsync();
        Items = await query
            .Skip((PageIndex - 1) * PageSize)
            .Take(PageSize)
            .ToListAsync();
    }
}
```

## Repository Benefits

### 1. Abstraction
- Business layer doesn't depend on Entity Framework
- Can switch data access technology without changing business logic
- Easier to test with mock repositories

### 2. Centralization
- All query logic in one place
- Consistent eager loading patterns
- Reusable filtering logic

### 3. Testability
- Interface-based design enables mocking
- Unit tests don't require database
- Integration tests can use in-memory database

### 4. Separation of Concerns
- Domain defines contracts (interfaces)
- Data provides implementations
- Web layer uses interfaces only

## Testing Support

### Mock Repository Example

```csharp
var mockRepository = new Mock<IBookRepository>();
mockRepository
    .Setup(x => x.GetAsync(1))
    .ReturnsAsync(new Book("Test Book", "Test Author", "123", 1, 1, 1, 1, 10.00m, 5));

var service = new BookService(mockRepository.Object);
var book = await service.GetBookAsync(1);
```

### Integration Test Example

```csharp
var options = new DbContextOptionsBuilder<ApplicationDbContext>()
    .UseInMemoryDatabase("TestDb")
    .Options;

using var context = new ApplicationDbContext(options);
var repository = new BookRepository(context);

await repository.AddAsync(new Book(...));
await repository.SaveChangesAsync();

var book = await repository.GetAsync(1);
Assert.NotNull(book);
```

## Repository Registration (DI)

```csharp
builder.RegisterType<BookRepository>().As<IBookRepository>();
builder.RegisterType<CustomerRepository>().As<ICustomerRepository>();
builder.RegisterType<OrderRepository>().As<IOrderRepository>();
builder.RegisterType<ShoppingCartRepository>().As<IShoppingCartRepository>();
builder.RegisterType<AddressRepository>().As<IAddressRepository>();
builder.RegisterType<OfferRepository>().As<IOfferRepository>();
builder.RegisterType<ReferenceDataRepository>().As<IReferenceDataRepository>();
```

**Lifetime**: Transient (new instance per resolution)

## Query Optimization Techniques

### 1. Projection for List Views
```csharp
var bookSummaries = await dbContext.Book
    .Select(x => new BookSummaryDto
    {
        Id = x.Id,
        Name = x.Name,
        Price = x.Price
    })
    .ToListAsync();
```

### 2. AsNoTracking for Read-Only
```csharp
var books = await dbContext.Book
    .AsNoTracking()
    .ToListAsync();
```

### 3. Compiled Queries (for frequently used queries)
```csharp
private static readonly Func<ApplicationDbContext, int, Task<Book>> GetBookQuery =
    EF.CompileAsyncQuery((ApplicationDbContext ctx, int id) =>
        ctx.Book
            .Include(x => x.Genre)
            .Single(x => x.Id == id));
```

## Migration to EF Core

### Changes Required

1. **Namespace Changes**:
```csharp
// EF 6.x
using System.Data.Entity;

// EF Core
using Microsoft.EntityFrameworkCore;
```

2. **Include Syntax**:
```csharp
// EF 6.x
.Include("OrderItems.Book")

// EF Core (prefer strongly-typed)
.Include(x => x.OrderItems)
    .ThenInclude(x => x.Book)
```

3. **Find vs FindAsync**:
```csharp
// EF 6.x
var book = await dbContext.Book.FindAsync(id);

// EF Core (same but different implementation)
var book = await dbContext.Book.FindAsync(id);
```

4. **Async Methods**:
Most async methods have same signatures, but performance characteristics may differ.

## Best Practices Applied

1. ✅ **Interface-based design**: All repositories have interfaces
2. ✅ **Async/await**: All data access is asynchronous
3. ✅ **Eager loading**: Explicit Include() for related entities
4. ✅ **Pagination**: Built-in support for large datasets
5. ✅ **Filtering**: Flexible filter objects
6. ✅ **Unit of Work**: SaveChangesAsync() for transaction boundaries
7. ✅ **Dependency Injection**: Constructor injection of DbContext

## Common Anti-Patterns Avoided

1. ❌ **Generic Repository**: Not using one-size-fits-all generic repository
   - ✅ Each repository tailored to entity needs
   
2. ❌ **Leaky Abstractions**: Not exposing IQueryable
   - ✅ Return concrete types or DTOs
   
3. ❌ **N+1 Queries**: Not lazy loading in loops
   - ✅ Eager loading with Include()

## Summary

The repository pattern implementation provides:
- **7 specialized repositories** for different entities
- **Clear interfaces** in Domain layer
- **Concrete implementations** in Data layer
- **Pagination support** via PaginatedList helper
- **Eager loading** for performance
- **Async operations** throughout
- **Testability** via interfaces
- **Separation of concerns** between layers

The pattern facilitates maintainability, testability, and provides a clean API for business services to access data without directly depending on Entity Framework.
