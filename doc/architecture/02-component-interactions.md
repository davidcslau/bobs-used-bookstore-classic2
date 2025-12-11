# Component Interactions and Dependencies

## Overview

This document describes how the different components of Bob's Used Bookstore Classic interact with each other, including dependency relationships, communication patterns, and data flow between layers.

## Project Dependencies

### Dependency Graph

```
Bookstore.Web
  ├── Bookstore.Domain
  ├── Bookstore.Data
  └── Bookstore.Common

Bookstore.Data
  ├── Bookstore.Domain
  └── Bookstore.Common

Bookstore.Domain
  └── Bookstore.Common

Bookstore.Common
  └── (no dependencies)

Bookstore.Cdk
  └── (independent - infrastructure only)
```

### Dependency Rules

1. **Web** can reference **Domain** and **Data**
2. **Data** can reference **Domain** but NOT **Web**
3. **Domain** should only reference **Common**
4. **Common** has no project dependencies
5. All layers can reference external NuGet packages

## Component Interaction Patterns

### 1. Controller → Service → Repository Pattern

**Pattern**: Standard layered architecture pattern for data operations

```
┌─────────────────┐
│   Controller    │  (Bookstore.Web)
└────────┬────────┘
         │ Depends on Interface
         ▼
┌─────────────────┐
│  Domain Service │  (Bookstore.Domain)
└────────┬────────┘
         │ Depends on Interface
         ▼
┌─────────────────┐
│   Repository    │  (Bookstore.Data)
└────────┬────────┘
         │ Uses
         ▼
┌─────────────────┐
│    DbContext    │  (Bookstore.Data)
└─────────────────┘
```

**Example: Book Listing**

```csharp
// 1. Controller (Bookstore.Web)
public class SearchController : Controller
{
    private readonly IBookService bookService; // Domain interface
    
    public async Task<ActionResult> Index(string query)
    {
        var books = await bookService.SearchBooksAsync(query);
        return View(books);
    }
}

// 2. Service (Bookstore.Domain)
public class BookService : IBookService
{
    private readonly IBookRepository repository; // Domain interface
    
    public async Task<IEnumerable<BookDto>> SearchBooksAsync(string query)
    {
        var books = await repository.ListAsync(query);
        return books.Select(b => new BookDto(b));
    }
}

// 3. Repository (Bookstore.Data)
public class BookRepository : IBookRepository
{
    private readonly ApplicationDbContext dbContext;
    
    public async Task<IPaginatedList<Book>> ListAsync(string query)
    {
        return await dbContext.Book
            .Where(b => b.Name.Contains(query))
            .ToListAsync();
    }
}
```

### 2. Service Interfaces and Implementations

**Pattern**: Interface in Domain, Implementation in Data

This pattern allows the Domain layer to define contracts without depending on implementation details.

```
Domain Layer (Bookstore.Domain)
  ├── IFileService (interface)
  ├── IImageValidationService (interface)
  └── IImageResizeService (interface)

Data Layer (Bookstore.Data)
  ├── LocalFileService (implementation)
  ├── S3FileService (implementation)
  ├── LocalImageValidationService (implementation)
  ├── RekognitionImageValidationService (implementation)
  └── ImageResizeService (implementation)
```

**Example: File Service Strategy**

```csharp
// Domain defines interface
public interface IFileService
{
    Task<string> SaveAsync(Stream contents, string filename);
    Task DeleteAsync(string filePath);
}

// Data layer provides implementations
public class LocalFileService : IFileService { /* ... */ }
public class S3FileService : IFileService { /* ... */ }

// Web layer configures via DI
if (config == "aws")
    builder.RegisterType<S3FileService>().As<IFileService>();
else
    builder.RegisterType<LocalFileService>().As<IFileService>();
```

## Key Interaction Flows

### 1. User Registration and Authentication

```
User Browser
    │
    ├─[1]─► AuthenticationController.Login()
    │           │
    │           ├─[2]─► AuthenticationSetup (OWIN Middleware)
    │           │         │
    │           │         ├─[3]─► AWS Cognito (if aws mode)
    │           │         │         │
    │           │         │         └─[4]─► Token Validation
    │           │         │
    │           │         └─[5]─► LocalAuthenticationMiddleware (if local)
    │           │
    │           └─[6]─► ICustomerService.CreateOrUpdateCustomerAsync()
    │                     │
    │                     └─[7]─► ICustomerRepository.AddOrUpdateAsync()
    │                               │
    │                               └─[8]─► ApplicationDbContext.SaveChanges()
    │
    └─[9]─► Redirect to Home with Auth Cookie
```

### 2. Book Search and Display

```
User Browser
    │
    ├─[1]─► SearchController.Index(query)
    │           │
    │           └─[2]─► IBookService.SearchBooksAsync(query, filters)
    │                     │
    │                     └─[3]─► IBookRepository.ListAsync(query, filters)
    │                               │
    │                               ├─[4]─► ApplicationDbContext.Book
    │                               │         │
    │                               │         └─[5]─► SQL Server Query
    │                               │
    │                               └─[6]─► Returns PaginatedList<Book>
    │
    └─[7]─► View renders SearchIndexViewModel
```

### 3. Shopping Cart Management

```
User Browser
    │
    ├─[1]─► ShoppingCartController.AddItem(bookId, quantity)
    │           │
    │           └─[2]─► IShoppingCartService.AddItemToCartAsync()
    │                     │
    │                     ├─[3]─► IShoppingCartRepository.GetByCorrelationId()
    │                     │         │
    │                     │         └─[4]─► ApplicationDbContext.ShoppingCart
    │                     │
    │                     ├─[5]─► ShoppingCart.AddItemToShoppingCart() (Domain Logic)
    │                     │
    │                     └─[6]─► IShoppingCartRepository.SaveChangesAsync()
    │                               │
    │                               └─[7]─► ApplicationDbContext.SaveChanges()
    │
    └─[8]─► Redirect to Cart Index
```

### 4. Order Processing

```
User Browser (Checkout)
    │
    ├─[1]─► CheckoutController.FinishCheckout(addressId)
    │           │
    │           ├─[2]─► ICustomerService.GetCustomerAsync()
    │           │         │
    │           │         └─[3]─► ICustomerRepository.GetBySubAsync()
    │           │
    │           ├─[4]─► IShoppingCartService.GetShoppingCartAsync()
    │           │         │
    │           │         └─[5]─► IShoppingCartRepository.GetByCorrelationId()
    │           │
    │           ├─[6]─► IOrderService.CreateOrderAsync()
    │           │         │
    │           │         ├─[7]─► IBookRepository.GetAsync() (for each cart item)
    │           │         │
    │           │         ├─[8]─► Create Order Entity (Domain Logic)
    │           │         │         │
    │           │         │         └─► Order.AddOrderItem() (Business Rule)
    │           │         │
    │           │         ├─[9]─► IOrderRepository.AddAsync()
    │           │         │
    │           │         ├─[10]─► Book.ReduceStockLevel() (Business Rule)
    │           │         │
    │           │         └─[11]─► IOrderRepository.SaveChangesAsync()
    │           │
    │           └─[12]─► IShoppingCartService.ClearCartAsync()
    │                     │
    │                     └─[13]─► IShoppingCartRepository.DeleteAsync()
    │
    └─[14]─► Display Order Confirmation
```

### 5. Book Upload with Image Processing

```
Admin User (Upload Book)
    │
    ├─[1]─► InventoryController.Create(bookDto, imageFile)
    │           │
    │           ├─[2]─► IImageValidationService.ValidateImageAsync(imageFile)
    │           │         │
    │           │         ├─► LocalImageValidationService: Basic validation
    │           │         └─► RekognitionImageValidationService: AWS content moderation
    │           │
    │           ├─[3]─► IImageResizeService.ResizeImageAsync(imageFile)
    │           │         │
    │           │         └─► ImageResizeService: Resize to standard dimensions
    │           │
    │           ├─[4]─► IFileService.SaveAsync(imageStream, filename)
    │           │         │
    │           │         ├─► LocalFileService: Save to disk, return local path
    │           │         └─► S3FileService: Upload to S3, return CloudFront URL
    │           │
    │           ├─[5]─► IBookService.CreateBookAsync(bookDto, imageUrl)
    │           │         │
    │           │         ├─[6]─► IReferenceDataRepository.ValidateReferences()
    │           │         │
    │           │         ├─[7]─► Create Book Entity with validation
    │           │         │
    │           │         └─[8]─► IBookRepository.AddAsync()
    │           │                   │
    │           │                   └─[9]─► ApplicationDbContext.SaveChanges()
    │           │
    │           └─[10]─► Redirect to Inventory Index
```

### 6. Reference Data Management

```
Admin User (Manage Reference Data)
    │
    ├─[1]─► ReferenceDataController.Index()
    │           │
    │           └─[2]─► IReferenceDataService.GetAllAsync()
    │                     │
    │                     └─[3]─► IReferenceDataRepository.ListAsync()
    │                               │
    │                               └─[4]─► ApplicationDbContext.ReferenceData
    │
    ├─[5]─► User Creates New Genre
    │           │
    │           └─[6]─► ReferenceDataController.Create(dto)
    │                     │
    │                     └─[7]─► IReferenceDataService.CreateAsync(dto)
    │                               │
    │                               ├─[8]─► Validate business rules
    │                               │
    │                               └─[9]─► IReferenceDataRepository.AddAsync()
    │
    └─[10]─► Controllers access reference data
              │
              ├─► InventoryController needs Genres, Publishers, etc.
              └─► SearchController uses for filtering
```

## Dependency Injection Container Configuration

### Autofac Registration (DependencyInjectionSetup.cs)

```csharp
// Controllers
builder.RegisterControllers(typeof(MvcApplication).Assembly);

// Services (Domain Layer Interfaces → Domain Layer Implementations)
builder.RegisterType<BookService>().As<IBookService>();
builder.RegisterType<OrderService>().As<IOrderService>();
builder.RegisterType<CustomerService>().As<ICustomerService>();
builder.RegisterType<ShoppingCartService>().As<IShoppingCartService>();
builder.RegisterType<AddressService>().As<IAddressService>();
builder.RegisterType<OfferService>().As<IOfferService>();
builder.RegisterType<ReferenceDataService>().As<IReferenceDataService>();

// Repositories (Domain Interfaces → Data Layer Implementations)
builder.RegisterType<BookRepository>().As<IBookRepository>();
builder.RegisterType<OrderRepository>().As<IOrderRepository>();
builder.RegisterType<CustomerRepository>().As<ICustomerRepository>();
builder.RegisterType<ShoppingCartRepository>().As<IShoppingCartRepository>();
builder.RegisterType<AddressRepository>().As<IAddressRepository>();
builder.RegisterType<OfferRepository>().As<IOfferRepository>();
builder.RegisterType<ReferenceDataRepository>().As<IReferenceDataRepository>();

// DbContext (Per-Request Lifetime)
var connectionString = BookstoreConfiguration.GetConnectionString("BookstoreDatabaseConnection");
builder.RegisterType<ApplicationDbContext>()
    .WithParameter("connectionString", connectionString)
    .InstancePerRequest();

// Conditional Registrations (Strategy Pattern)
if (config["Services/FileService"] == "aws")
{
    builder.RegisterType<AmazonS3Client>().As<IAmazonS3>();
    builder.RegisterType<S3FileService>().As<IFileService>();
}
else
{
    builder.RegisterInstance(new LocalFileService(webRootPath)).As<IFileService>();
}

if (config["Services/ImageValidationService"] == "aws")
{
    builder.RegisterType<AmazonRekognitionClient>().As<IAmazonRekognition>();
    builder.RegisterType<RekognitionImageValidationService>().As<IImageValidationService>();
}
else
{
    builder.RegisterType<LocalImageValidationService>().As<IImageValidationService>();
}
```

## Cross-Component Communication

### 1. Domain Events (Implicit)

While not using a formal event system, business logic triggers related actions:

```csharp
// When order is created
Order order = new Order(customerId, addressId);

foreach (var item in cartItems)
{
    // Add order item
    order.AddOrderItem(book, quantity);
    
    // Reduce book stock (side effect)
    book.ReduceStockLevel(quantity);
}

await orderRepository.SaveChangesAsync();
```

### 2. Service Orchestration

Services coordinate between multiple repositories:

```csharp
public class OrderService : IOrderService
{
    private readonly IOrderRepository orderRepository;
    private readonly IBookRepository bookRepository;
    private readonly ICustomerRepository customerRepository;
    
    public async Task<OrderDto> CreateOrderAsync(CreateOrderDto dto)
    {
        // Orchestrate multiple repositories
        var customer = await customerRepository.GetAsync(dto.CustomerId);
        var books = await bookRepository.GetManyAsync(dto.BookIds);
        
        // Create order with business logic
        var order = new Order(customer.Id, dto.AddressId);
        
        foreach (var item in dto.Items)
        {
            var book = books.Single(b => b.Id == item.BookId);
            order.AddOrderItem(book, item.Quantity);
            book.ReduceStockLevel(item.Quantity);
        }
        
        await orderRepository.AddAsync(order);
        await orderRepository.SaveChangesAsync();
        
        return new OrderDto(order);
    }
}
```

### 3. Configuration-Driven Behavior

Components adjust behavior based on configuration:

```csharp
// Logging configuration
if (config["Services/LoggingService"] == "aws")
{
    // Use CloudWatch Logs
    logConfig.AddTarget(new AwsTarget { /* ... */ });
}
else
{
    // Use file logging
    logConfig.AddTarget(new FileTarget { /* ... */ });
}

// Authentication configuration
if (config["Services/Authentication"] == "aws")
{
    // Use AWS Cognito
    ConfigureCognitoAuthentication(app);
}
else
{
    // Use local authentication
    ConfigureLocalAuthentication(app);
}
```

## External Dependencies

### 1. AWS Services Integration

```
Bookstore.Data
    │
    ├─► Amazon.S3 (AWSSDK.S3)
    │     └─► S3FileService
    │
    ├─► Amazon.Rekognition (AWSSDK.Rekognition)
    │     └─► RekognitionImageValidationService
    │
    ├─► Amazon.CloudWatchLogs (AWSSDK.CloudWatchLogs)
    │     └─► NLog AWS Logger
    │
    └─► Amazon.SimpleSystemsManagement (AWSSDK.SimpleSystemsManagement)
          └─► BookstoreConfiguration (Parameter Store)
```

### 2. Entity Framework Integration

```
ApplicationDbContext
    │
    ├─► System.Data.Entity (EF 6.5.1)
    │     │
    │     ├─► DbSet<Book>
    │     ├─► DbSet<Customer>
    │     ├─► DbSet<Order>
    │     ├─► DbSet<ShoppingCart>
    │     ├─► DbSet<Address>
    │     ├─► DbSet<Offer>
    │     └─► DbSet<ReferenceDataItem>
    │
    └─► SQL Server Provider
          └─► System.Data.SqlClient
```

### 3. Authentication Integration

```
OWIN Pipeline
    │
    ├─► Microsoft.Owin
    │     │
    │     ├─► CookieAuthenticationMiddleware
    │     │     └─► Local authentication
    │     │
    │     └─► OpenIdConnectAuthenticationMiddleware
    │           └─► AWS Cognito integration
    │
    └─► Authentication Results
          └─► ClaimsPrincipal
                └─► User identity in controllers
```

## Component Lifecycle Management

### 1. Request Lifecycle

```
HTTP Request Arrives
    │
    ├─► OWIN Middleware Pipeline
    │     ├─► Authentication Middleware
    │     ├─► Autofac Middleware (DI Scope Creation)
    │     └─► MVC Middleware
    │
    ├─► Route Matching
    │
    ├─► Controller Creation (DI Resolution)
    │     └─► Dependencies Injected
    │           ├─► Services (Singleton/Transient)
    │           ├─► Repositories (Transient)
    │           └─► DbContext (InstancePerRequest)
    │
    ├─► Action Execution
    │     └─► Business Logic
    │
    ├─► View Rendering
    │
    └─► Response Sent
          │
          └─► DI Scope Disposed
                ├─► DbContext.Dispose()
                └─► Other disposables cleaned up
```

### 2. Application Lifecycle

```
Application Start (Global.asax.Application_Start)
    │
    ├─► Area Registration
    ├─► Filter Configuration
    ├─► Route Configuration
    ├─► Bundle Configuration
    │
    └─► OWIN Startup (Startup.cs)
          │
          ├─► Logging Setup
          ├─► Configuration Setup
          ├─► Dependency Injection Setup
          └─► Authentication Setup

Application Running
    ├─► Handle Requests
    └─► Log Errors (Application_Error)

Application End
    └─► Cleanup
```

## Data Flow Patterns

### 1. Read Operations (Query)

```
Controller → Service → Repository → DbContext → Database
                                                    │
Database → Entity → Repository → DTO → Service → ViewModel → View
```

### 2. Write Operations (Command)

```
Controller → Service → Repository → DbContext
                │                      │
                ├─► Business Logic     │
                ├─► Validation         │
                └─► Entity Creation    ├─► SaveChanges() → Database
```

### 3. File Operations

```
Controller → Validation Service → Resize Service → File Service → Storage
                                                                      │
Storage (Local/S3) → URL → Controller → Service → Repository → Database (URL saved)
```

## Inter-Layer Contracts

### 1. Controller ↔ Service

**Contract**: DTOs (Data Transfer Objects)
- Input: CreateBookDto, UpdateBookDto, SearchFiltersDto
- Output: BookDto, OrderDto, CustomerDto

### 2. Service ↔ Repository

**Contract**: Domain Entities
- Book, Customer, Order, ShoppingCart, Address, Offer, ReferenceDataItem

### 3. Repository ↔ Database

**Contract**: Entity Framework Entities
- Same as domain entities (code-first approach)
- DbSet<T> collections
- LINQ queries

### 4. Controller ↔ View

**Contract**: ViewModels
- HomeIndexViewModel, SearchIndexViewModel, CheckoutViewModel
- Tailored for specific views
- May aggregate multiple DTOs

## Error Handling Flow

```
Exception Occurs
    │
    ├─► Repository Level
    │     └─► DbUpdateException, SqlException
    │           └─► Logged and re-thrown
    │
    ├─► Service Level
    │     └─► Business Logic Exceptions
    │           └─► Logged and wrapped in ServiceException
    │
    ├─► Controller Level
    │     └─► Try-Catch blocks
    │           ├─► Log error
    │           ├─► Add ModelState error
    │           └─► Return error view
    │
    └─► Global Error Handler (Application_Error)
          ├─► Log unhandled exceptions
          └─► Display generic error page
```

## Summary

The component interactions in Bob's Used Bookstore Classic follow clean architecture principles with clear boundaries between layers. Controllers depend on service interfaces, services orchestrate business logic using repositories, and repositories abstract data access. The dependency injection container manages component lifecycles and enables configuration-driven behavior selection for file storage, image validation, and authentication services.

Key patterns:
- **Dependency Inversion**: High-level components depend on abstractions
- **Strategy Pattern**: Multiple implementations selected via configuration
- **Repository Pattern**: Centralized data access
- **Service Layer**: Business logic orchestration
- **DTO Pattern**: Decoupled data transfer between layers
