# Data Access Layer Documentation - Bob's Used Bookstore Classic

**Document Version:** 1.0  
**Date:** December 11, 2024  
**Namespace:** Bookstore.Data  
**ORM:** Entity Framework 6.5.1

---

## Table of Contents
1. [Overview](#overview)
2. [ApplicationDbContext](#applicationdbcontext)
3. [Repository Pattern Implementation](#repository-pattern-implementation)
4. [Database Schema](#database-schema)
5. [Entity Framework Mappings](#entity-framework-mappings)
6. [Supporting Services](#supporting-services)
7. [Configuration](#configuration)

---

## Overview

The Data Access Layer is responsible for all database interactions using Entity Framework 6.5.1. It implements the Repository pattern to abstract database operations and provide a clean API for the business layer.

**Key Technologies:**
- Entity Framework 6.5.1 (Code-First approach)
- SQL Server (LocalDB for development, RDS for production)
- Repository Pattern
- Async/Await for all database operations
- LINQ for queries

**Database Provider:**
- System.Data.SqlClient
- EntityFramework.SqlServer

---

## ApplicationDbContext

**Location:** `Bookstore.Data/ApplicationDbContext.cs`

### Overview

The `ApplicationDbContext` is the main Entity Framework DbContext that manages entity configuration and database connection.

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
}
```

### Entity Configuration

The `OnModelCreating` method configures entity mappings and relationships:

#### 1. Table Naming Convention
```csharp
modelBuilder.Conventions.Remove<PluralizingTableNameConvention>();
```
- Removes EF's default pluralization
- Table names match entity names exactly (Book, not Books)

#### 2. Customer Configuration
```csharp
modelBuilder.Entity<Customer>()
    .Property(x => x.Sub)
    .HasColumnType("nvarchar")
    .HasMaxLength(450);

modelBuilder.Entity<Customer>()
    .HasIndex(x => x.Sub)
    .IsUnique();
```
- Sub column: nvarchar(450) with unique index
- Sub is the authentication identifier (Cognito or local)

#### 3. Book Configuration
```csharp
modelBuilder.Entity<Book>()
    .HasRequired(x => x.Publisher)
    .WithMany()
    .HasForeignKey(x => x.PublisherId)
    .WillCascadeOnDelete(false);

// Similar for BookType, Genre, Condition
```
- Foreign key relationships to ReferenceData
- Cascade delete disabled (preserve reference data)
- Required relationships (cannot create book without reference data)

#### 4. Offer Configuration
```csharp
modelBuilder.Entity<Offer>()
    .HasRequired(x => x.Publisher)
    .WithMany()
    .HasForeignKey(x => x.PublisherId)
    .WillCascadeOnDelete(false);

// Similar for BookType, Genre, Condition
```
- Same pattern as Book entity
- Foreign keys to ReferenceData
- No cascade delete

#### 5. Order Configuration
```csharp
modelBuilder.Entity<Order>()
    .HasRequired(x => x.Customer)
    .WithMany()
    .WillCascadeOnDelete(false);
```
- Required relationship to Customer
- No cascade delete (preserve customer data)

#### 6. ReferenceData Table Mapping
```csharp
modelBuilder.Entity<ReferenceDataItem>()
    .ToTable("ReferenceData");
```
- Explicitly maps entity to "ReferenceData" table

#### 7. ShoppingCartItem Composite Key
```csharp
modelBuilder.Entity<ShoppingCartItem>()
    .HasKey(x => new { x.Id, x.ShoppingCartId });

modelBuilder.Entity<ShoppingCartItem>()
    .Property(x => x.Id)
    .HasDatabaseGeneratedOption(DatabaseGeneratedOption.Identity);
```
- Composite primary key: (Id, ShoppingCartId)
- Id is auto-generated identity

#### 8. Database Initializer
```csharp
Database.SetInitializer(new BookstoreDbInitializer());
```
- Sets custom initializer for database seeding

---

## Repository Pattern Implementation

### Repository Interface Structure

All repositories follow a consistent interface pattern defined in the Domain layer:

```csharp
public interface IRepository<T> where T : Entity
{
    Task<T> GetAsync(int id);
    Task<IPaginatedList<T>> ListAsync(TFilter filters, int pageIndex, int pageSize);
    Task CreateAsync(T entity);
    Task UpdateAsync(T entity);
    Task DeleteAsync(int id);
}
```

### 1. BookRepository

**Location:** `Bookstore.Data/Repositories/BookRepository.cs`

**Interface:** `IBookRepository` (in Bookstore.Domain)

**Key Methods:**

```csharp
async Task<Book> GetAsync(int id)
{
    return await dbContext.Book
        .Include("Genre")
        .Include("Publisher")
        .Include("BookType")
        .Include("Condition")
        .SingleAsync(x => x.Id == id);
}
```
- Eager loads related ReferenceData entities
- Uses Include for navigation properties

```csharp
async Task<IPaginatedList<Book>> ListAsync(BookFilters filters, int pageIndex, int pageSize)
{
    var query = dbContext.Book.AsQueryable();
    
    // Apply filters
    if (!string.IsNullOrWhiteSpace(filters.Name))
        query = query.Where(x => x.Name.Contains(filters.Name));
    
    if (!string.IsNullOrWhiteSpace(filters.Author))
        query = query.Where(x => x.Author.Contains(filters.Author));
    
    if (filters.ConditionId.HasValue)
        query = query.Where(x => x.ConditionId == filters.ConditionId);
    
    // Include related entities
    query = query
        .Include(x => x.Genre)
        .Include(x => x.Publisher)
        .Include(x => x.BookType)
        .Include(x => x.Condition);
    
    // Paginate
    var result = new PaginatedList<Book>(query, pageIndex, pageSize);
    await result.PopulateAsync();
    
    return result;
}
```
- Dynamic filtering based on BookFilters
- Eager loading of navigation properties
- Pagination support

**CRUD Operations:**
- `CreateAsync(Book book)` - Adds new book
- `UpdateAsync(Book book)` - Updates existing book
- `DeleteAsync(int id)` - Removes book
- `GetBookStatisticsAsync()` - Returns inventory stats

### 2. OrderRepository

**Location:** `Bookstore.Data/Repositories/OrderRepository.cs`

**Key Methods:**

```csharp
async Task<Order> GetAsync(int id)
{
    return await dbContext.Order
        .Include(x => x.Customer)
        .Include(x => x.Address)
        .Include("OrderItems.Book")
        .Include("OrderItems.Book.Genre")
        .Include("OrderItems.Book.Publisher")
        .Include("OrderItems.Book.BookType")
        .Include("OrderItems.Book.Condition")
        .SingleAsync(x => x.Id == id);
}
```
- Complex eager loading with nested includes
- Loads Order → OrderItems → Books → ReferenceData

```csharp
async Task<Order> CreateOrderFromCartAsync(int customerId, int addressId, string correlationId)
{
    // 1. Get shopping cart with items
    var cart = await GetCartWithItems(correlationId);
    
    // 2. Create order
    var order = new Order(customerId, addressId);
    
    // 3. Add order items and reduce book quantities
    foreach (var cartItem in cart.ShoppingCartItems)
    {
        order.AddOrderItem(cartItem.Book, cartItem.Quantity);
        cartItem.Book.ReduceStockLevel(cartItem.Quantity);
    }
    
    // 4. Clear cart items
    cart.ShoppingCartItems.Clear();
    
    // 5. Save changes (transaction)
    dbContext.Order.Add(order);
    await dbContext.SaveChangesAsync();
    
    return order;
}
```
- Complex business transaction
- Multiple entity updates in single transaction
- EF manages transaction automatically with SaveChangesAsync

### 3. OfferRepository

**Location:** `Bookstore.Data/Repositories/OfferRepository.cs`

**Key Features:**
- Filters by customer, status, date ranges
- Eager loads customer and reference data
- Pagination support
- Statistics aggregation

### 4. ShoppingCartRepository

**Location:** `Bookstore.Data/Repositories/ShoppingCartRepository.cs`

**Key Methods:**

```csharp
async Task<ShoppingCart> GetOrCreateByCorrelationIdAsync(string correlationId)
{
    var cart = await dbContext.ShoppingCart
        .Include(x => x.ShoppingCartItems)
        .Include("ShoppingCartItems.Book")
        .Include("ShoppingCartItems.Book.Genre")
        .Include("ShoppingCartItems.Book.Publisher")
        .Include("ShoppingCartItems.Book.BookType")
        .Include("ShoppingCartItems.Book.Condition")
        .SingleOrDefaultAsync(x => x.CorrelationId == correlationId);
    
    if (cart == null)
    {
        cart = new ShoppingCart(correlationId);
        dbContext.ShoppingCart.Add(cart);
        await dbContext.SaveChangesAsync();
    }
    
    return cart;
}
```
- Gets existing cart or creates new one
- Session-based using correlation ID
- Eager loads all related data

### 5. CustomerRepository

**Location:** `Bookstore.Data/Repositories/CustomerRepository.cs`

**Key Methods:**
- `GetBySubAsync(string sub)` - Find customer by authentication identifier
- `CreateOrUpdateAsync(Customer customer)` - Upsert operation
- Standard CRUD operations

### 6. AddressRepository

**Location:** `Bookstore.Data/Repositories/AddressRepository.cs`

**Key Methods:**
- `ListByCustomerIdAsync(int customerId)` - Get customer addresses
- Filter by active status
- Standard CRUD operations

### 7. ReferenceDataRepository

**Location:** `Bookstore.Data/Repositories/ReferenceDataRepository.cs`

**Key Methods:**
- `ListByTypeAsync(ReferenceDataType type)` - Get reference data by type
- `GetAllAsync()` - Get all reference data
- Create/Delete operations

---

## Database Schema

### Table Structure

#### 1. Book Table
```sql
CREATE TABLE Book (
    Id              INT IDENTITY(1,1) PRIMARY KEY,
    Name            NVARCHAR(MAX) NOT NULL,
    Author          NVARCHAR(MAX) NOT NULL,
    Year            INT NULL,
    ISBN            NVARCHAR(MAX) NULL,
    PublisherId     INT NOT NULL,
    BookTypeId      INT NOT NULL,
    GenreId         INT NOT NULL,
    ConditionId     INT NOT NULL,
    CoverImageUrl   NVARCHAR(MAX) NULL,
    Summary         NVARCHAR(MAX) NULL,
    Price           DECIMAL(18,2) NOT NULL,
    Quantity        INT NOT NULL,
    
    FOREIGN KEY (PublisherId) REFERENCES ReferenceData(Id),
    FOREIGN KEY (BookTypeId) REFERENCES ReferenceData(Id),
    FOREIGN KEY (GenreId) REFERENCES ReferenceData(Id),
    FOREIGN KEY (ConditionId) REFERENCES ReferenceData(Id)
);
```

#### 2. Customer Table
```sql
CREATE TABLE Customer (
    Id              INT IDENTITY(1,1) PRIMARY KEY,
    Sub             NVARCHAR(450) NOT NULL UNIQUE,
    Username        NVARCHAR(MAX) NULL,
    FirstName       NVARCHAR(MAX) NULL,
    LastName        NVARCHAR(MAX) NULL,
    Email           NVARCHAR(MAX) NULL,
    DateOfBirth     DATETIME2 NULL,
    Phone           NVARCHAR(MAX) NULL
);

CREATE UNIQUE INDEX IX_Customer_Sub ON Customer(Sub);
```

#### 3. Order Table
```sql
CREATE TABLE [Order] (
    Id              INT IDENTITY(1,1) PRIMARY KEY,
    CustomerId      INT NOT NULL,
    AddressId       INT NOT NULL,
    DeliveryDate    DATETIME2 NOT NULL,
    OrderStatus     INT NOT NULL,
    
    FOREIGN KEY (CustomerId) REFERENCES Customer(Id),
    FOREIGN KEY (AddressId) REFERENCES Address(Id)
);
```

#### 4. OrderItem Table
```sql
CREATE TABLE OrderItem (
    Id              INT IDENTITY(1,1) PRIMARY KEY,
    OrderId         INT NOT NULL,
    BookId          INT NOT NULL,
    Quantity        INT NOT NULL,
    
    FOREIGN KEY (OrderId) REFERENCES [Order](Id) ON DELETE CASCADE,
    FOREIGN KEY (BookId) REFERENCES Book(Id)
);
```

#### 5. ShoppingCart Table
```sql
CREATE TABLE ShoppingCart (
    Id              INT IDENTITY(1,1) PRIMARY KEY,
    CorrelationId   NVARCHAR(MAX) NOT NULL
);
```

#### 6. ShoppingCartItem Table
```sql
CREATE TABLE ShoppingCartItem (
    Id              INT IDENTITY(1,1),
    ShoppingCartId  INT NOT NULL,
    BookId          INT NOT NULL,
    Quantity        INT NOT NULL,
    WantToBuy       BIT NOT NULL,
    
    PRIMARY KEY (Id, ShoppingCartId),
    FOREIGN KEY (ShoppingCartId) REFERENCES ShoppingCart(Id) ON DELETE CASCADE,
    FOREIGN KEY (BookId) REFERENCES Book(Id)
);
```

#### 7. Offer Table
```sql
CREATE TABLE Offer (
    Id              INT IDENTITY(1,1) PRIMARY KEY,
    CustomerId      INT NOT NULL,
    BookName        NVARCHAR(MAX) NOT NULL,
    Author          NVARCHAR(MAX) NOT NULL,
    ISBN            NVARCHAR(MAX) NULL,
    BookTypeId      INT NOT NULL,
    ConditionId     INT NOT NULL,
    GenreId         INT NOT NULL,
    PublisherId     INT NOT NULL,
    BookPrice       DECIMAL(18,2) NOT NULL,
    FrontUrl        NVARCHAR(MAX) NULL,
    Summary         NVARCHAR(MAX) NULL,
    OfferStatus     INT NOT NULL,
    Comment         NVARCHAR(MAX) NULL,
    
    FOREIGN KEY (CustomerId) REFERENCES Customer(Id),
    FOREIGN KEY (PublisherId) REFERENCES ReferenceData(Id),
    FOREIGN KEY (BookTypeId) REFERENCES ReferenceData(Id),
    FOREIGN KEY (GenreId) REFERENCES ReferenceData(Id),
    FOREIGN KEY (ConditionId) REFERENCES ReferenceData(Id)
);
```

#### 8. Address Table
```sql
CREATE TABLE Address (
    Id              INT IDENTITY(1,1) PRIMARY KEY,
    CustomerId      INT NOT NULL,
    AddressLine1    NVARCHAR(MAX) NOT NULL,
    AddressLine2    NVARCHAR(MAX) NULL,
    City            NVARCHAR(MAX) NOT NULL,
    State           NVARCHAR(MAX) NOT NULL,
    Country         NVARCHAR(MAX) NOT NULL,
    ZipCode         NVARCHAR(MAX) NOT NULL,
    IsActive        BIT NOT NULL DEFAULT 1,
    
    FOREIGN KEY (CustomerId) REFERENCES Customer(Id)
);
```

#### 9. ReferenceData Table
```sql
CREATE TABLE ReferenceData (
    Id              INT IDENTITY(1,1) PRIMARY KEY,
    DataType        INT NOT NULL,
    Text            NVARCHAR(MAX) NOT NULL
);
```

#### 10. __MigrationHistory Table
```sql
CREATE TABLE __MigrationHistory (
    MigrationId     NVARCHAR(150) NOT NULL,
    ContextKey      NVARCHAR(300) NOT NULL,
    Model           VARBINARY(MAX) NOT NULL,
    ProductVersion  NVARCHAR(32) NOT NULL,
    
    PRIMARY KEY (MigrationId, ContextKey)
);
```

---

## Entity Framework Mappings

### Convention-Based Mappings

Entity Framework uses conventions for most mappings:

1. **Primary Keys:** Properties named `Id` or `<ClassName>Id`
2. **Foreign Keys:** Properties named `<NavigationProperty>Id`
3. **Data Types:** 
   - `string` → NVARCHAR(MAX)
   - `int` → INT
   - `decimal` → DECIMAL(18,2)
   - `DateTime` → DATETIME2
   - `bool` → BIT

### Fluent API Configurations

Custom configurations in `OnModelCreating`:

1. **Unique Constraints:** Customer.Sub
2. **Composite Keys:** ShoppingCartItem (Id, ShoppingCartId)
3. **Cascade Delete Rules:** Disabled for reference data relationships
4. **Table Names:** ReferenceDataItem → ReferenceData
5. **Identity Columns:** Explicitly configured for composite key scenarios

---

## Supporting Services

### 1. File Services

**Purpose:** Handle file storage (book covers, offer images)

#### LocalFileService

**Location:** `Bookstore.Data/FileServices/LocalFileService.cs`

- Stores files in `Content/` directory
- Used for development
- Synchronous file I/O

```csharp
public class LocalFileService : IFileService
{
    private readonly string webRootPath;
    
    public async Task<string> UploadFileAsync(string fileName, Stream fileStream)
    {
        var filePath = Path.Combine(webRootPath, "uploads", fileName);
        // Save file to disk
        return $"/Content/uploads/{fileName}";
    }
}
```

#### S3FileService

**Location:** `Bookstore.Data/FileServices/S3FileService.cs`

- Stores files in Amazon S3
- Used for production
- Async S3 operations
- Returns CloudFront URLs

```csharp
public class S3FileService : IFileService
{
    private readonly IAmazonS3 s3Client;
    private readonly string bucketName;
    
    public async Task<string> UploadFileAsync(string fileName, Stream fileStream)
    {
        await s3Client.PutObjectAsync(new PutObjectRequest
        {
            BucketName = bucketName,
            Key = fileName,
            InputStream = fileStream
        });
        
        return $"https://{cloudFrontDomain}/{fileName}";
    }
}
```

### 2. Image Resize Service

**Location:** `Bookstore.Data/ImageResizeService/ImageResizeService.cs`

**Purpose:** Resize uploaded images to standard dimensions

**Technology:** Magick.NET (ImageMagick for .NET)

```csharp
public class ImageResizeService : IImageResizeService
{
    public Stream ResizeImage(Stream imageStream, int width, int height)
    {
        using (var image = new MagickImage(imageStream))
        {
            image.Resize(width, height);
            var outputStream = new MemoryStream();
            image.Write(outputStream);
            outputStream.Position = 0;
            return outputStream;
        }
    }
}
```

### 3. Image Validation Services

#### LocalImageValidationService

**Location:** `Bookstore.Data/ImageValidationServices/LocalImageValidationService.cs`

- Basic validation (file type, size)
- No content moderation
- Synchronous validation

#### RekognitionImageValidationService

**Location:** `Bookstore.Data/ImageValidationServices/RekognitionImageValidationService.cs`

- Uses Amazon Rekognition
- Content moderation (adult content, violence, etc.)
- Async validation

```csharp
public async Task<bool> ValidateImageAsync(Stream imageStream)
{
    var response = await rekognitionClient.DetectModerationLabelsAsync(
        new DetectModerationLabelsRequest
        {
            Image = new Image { Bytes = imageStream }
        });
    
    return !response.ModerationLabels.Any(x => x.Confidence > 80);
}
```

---

## Configuration

### Connection Strings

**Development (Web.config):**
```xml
<connectionStrings>
    <add name="BookstoreDatabaseConnection" 
         connectionString="Server=(localdb)\MSSQLLocalDB;
                          Initial Catalog=BookStoreClassic;
                          MultipleActiveResultSets=true;
                          Integrated Security=SSPI;" 
         providerName="System.Data.SqlClient" />
</connectionStrings>
```

**Production (AWS):**
- Connection string retrieved from AWS Systems Manager Parameter Store
- Uses SQL Server authentication
- Points to RDS for SQL Server instance

### Entity Framework Configuration

**App.config / Web.config:**
```xml
<entityFramework>
    <providers>
        <provider invariantName="System.Data.SqlClient" 
                  type="System.Data.Entity.SqlServer.SqlProviderServices, EntityFramework.SqlServer" />
    </providers>
</entityFramework>
```

### Database Initialization

**Location:** `Bookstore.Data/BookstoreDbInitializer.cs`

- Seeds reference data (genres, publishers, conditions, book types)
- Creates initial admin user
- Populates sample books for development

```csharp
public class BookstoreDbInitializer : CreateDatabaseIfNotExists<ApplicationDbContext>
{
    protected override void Seed(ApplicationDbContext context)
    {
        // Seed reference data
        var genres = new List<ReferenceDataItem>
        {
            new ReferenceDataItem(ReferenceDataType.Genre, "Fiction"),
            new ReferenceDataItem(ReferenceDataType.Genre, "Non-fiction"),
            // ...
        };
        
        context.ReferenceData.AddRange(genres);
        context.SaveChanges();
        
        // Seed books, etc.
    }
}
```

---

## Performance Considerations

### N+1 Query Problem

**Problem:** Loading related entities in loops causes multiple queries

**Solution:** Use `.Include()` to eager load

```csharp
// Bad: N+1 queries
var books = await dbContext.Book.ToListAsync();
foreach (var book in books)
{
    var genre = book.Genre; // Lazy load - additional query!
}

// Good: Single query with join
var books = await dbContext.Book
    .Include(x => x.Genre)
    .Include(x => x.Publisher)
    .ToListAsync();
```

### Pagination

All list operations use `PaginatedList<T>` to limit result sets:

```csharp
public class PaginatedList<T> : IPaginatedList<T>
{
    private readonly IQueryable<T> query;
    private readonly int pageIndex;
    private readonly int pageSize;
    
    public async Task PopulateAsync()
    {
        TotalCount = await query.CountAsync();
        Items = await query
            .Skip(pageIndex * pageSize)
            .Take(pageSize)
            .ToListAsync();
    }
}
```

### Transaction Management

- Entity Framework manages transactions automatically
- Single `SaveChangesAsync()` call = one transaction
- Complex operations wrapped in single save operation

---

**Next:** 04-web-layer-api-documentation.md
