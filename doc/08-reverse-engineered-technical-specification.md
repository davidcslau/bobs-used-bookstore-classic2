# Reverse-Engineered Technical Specification

**Document Version:** 1.0  
**Date:** December 11, 2024  
**Application:** Bob's Used Bookstore Classic

---

## Table of Contents
1. [Technical Architecture](#technical-architecture)
2. [Technology Stack](#technology-stack)
3. [Database Design](#database-design)
4. [API Contracts](#api-contracts)
5. [Authentication and Authorization](#authentication-and-authorization)
6. [File Storage](#file-storage)
7. [Configuration Management](#configuration-management)
8. [Logging and Monitoring](#logging-and-monitoring)
9. [Deployment Architecture](#deployment-architecture)

---

## Technical Architecture

### Architecture Style
**Type:** 3-Tier Layered Monolithic Architecture

**Layers:**
1. **Presentation Layer** - ASP.NET MVC 5 (Bookstore.Web)
2. **Business Logic Layer** - Domain Models and Services (Bookstore.Domain)
3. **Data Access Layer** - Entity Framework 6.5.1 (Bookstore.Data)

### Design Patterns
- **Repository Pattern:** Data access abstraction
- **Service Layer:** Business logic encapsulation
- **Dependency Injection:** Autofac IoC container
- **Model-View-Controller:** Presentation pattern
- **Data Transfer Objects (DTOs):** Layer communication
- **Unit of Work:** Implicit via EF DbContext

---

## Technology Stack

### Runtime and Framework
- **.NET Framework:** 4.8
- **Language:** C# 7.3
- **Runtime:** CLR 4.0

### Web Framework
- **ASP.NET MVC:** 5.3.0
- **Razor View Engine:** 3.3.0
- **OWIN:** 4.2.2
- **IIS/IIS Express:** Web server

### Data Access
- **ORM:** Entity Framework 6.5.1
- **Database:** SQL Server (LocalDB / RDS)
- **Provider:** System.Data.SqlClient
- **Migration:** Code-First

### Dependency Injection
- **Container:** Autofac 8.2.1
- **Integration:** Autofac.Mvc5, Autofac.Owin

### Authentication
- **Framework:** OWIN Authentication Middleware
- **Protocols:** OpenID Connect, OAuth 2.0
- **Provider:** AWS Cognito (production) / Local (development)
- **Session:** Cookie-based

### Front-End
- **JavaScript:** jQuery 3.7.1
- **Validation:** jQuery Validation 1.21.0
- **CSS:** Bootstrap (via Content)
- **Bundling:** ASP.NET Web Optimization 1.1.3

### AWS Services (Optional)
- **S3:** File storage
- **Rekognition:** Image validation
- **Cognito:** Authentication
- **CloudWatch Logs:** Logging
- **Systems Manager:** Configuration
- **RDS:** SQL Server database

### Supporting Libraries
- **Logging:** NLog 5.4.0
- **Image Processing:** Magick.NET 14.6.0
- **JSON:** Newtonsoft.Json 13.0.3

---

## Database Design

### Database Type
- **Engine:** Microsoft SQL Server
- **Version:** 2019+ (Production), LocalDB (Development)
- **Edition:** Express / Standard (production)

### Connection Configuration
```
Development: Server=(localdb)\MSSQLLocalDB;Database=BookStoreClassic;Integrated Security=SSPI
Production: Retrieved from AWS Systems Manager Parameter Store
```

### Entity Framework Configuration
- **Approach:** Code-First
- **Migration:** Automatic via BookstoreDbInitializer
- **Initializer:** CreateDatabaseIfNotExists
- **Naming:** Table names match entity names (no pluralization)

### Tables (9 main tables)
1. Book - Inventory
2. Customer - User profiles
3. Order - Purchase orders
4. OrderItem - Order line items
5. ShoppingCart - Session carts
6. ShoppingCartItem - Cart contents
7. Offer - Resale offers
8. Address - Shipping addresses
9. ReferenceData - Lookup data

### Key Constraints
- **Primary Keys:** Identity columns (auto-increment)
- **Foreign Keys:** Enforced with no cascade on reference data
- **Unique Constraints:** Customer.Sub
- **Composite Keys:** ShoppingCartItem (Id, ShoppingCartId)

### Indexes
- **Clustered:** Primary keys
- **Non-Clustered:** Customer.Sub (unique), Foreign keys

---

## API Contracts

### Internal Service APIs

#### IBookService

```csharp
public interface IBookService
{
    Task<BookDto> GetBookAsync(int id);
    Task<BookSearchResultDto> SearchBooksAsync(
        BookFilters filters, int page, int pageSize);
    Task<BookDto> CreateBookAsync(CreateOrUpdateBookDto dto);
    Task<BookDto> UpdateBookAsync(int id, CreateOrUpdateBookDto dto);
    Task DeleteBookAsync(int id);
    Task<BookStatistics> GetBookStatisticsAsync();
}
```

**DTOs:**
```csharp
public class BookDto
{
    public int Id { get; set; }
    public string Name { get; set; }
    public string Author { get; set; }
    public int? Year { get; set; }
    public string ISBN { get; set; }
    public decimal Price { get; set; }
    public int Quantity { get; set; }
    public bool IsInStock { get; set; }
    public string CoverImageUrl { get; set; }
    public string Summary { get; set; }
    public ReferenceDataDto Publisher { get; set; }
    public ReferenceDataDto Genre { get; set; }
    public ReferenceDataDto BookType { get; set; }
    public ReferenceDataDto Condition { get; set; }
}

public class BookFilters
{
    public string Name { get; set; }
    public string Author { get; set; }
    public int? GenreId { get; set; }
    public int? PublisherId { get; set; }
    public int? BookTypeId { get; set; }
    public int? ConditionId { get; set; }
    public bool LowStock { get; set; }
}
```

#### IOrderService

```csharp
public interface IOrderService
{
    Task<OrderDto> GetOrderAsync(int id);
    Task<PaginatedResultDto<OrderDto>> ListOrdersAsync(
        OrderFilters filters, int page, int pageSize);
    Task<OrderDto> CreateOrderFromCartAsync(
        int customerId, int addressId, string correlationId);
    Task UpdateOrderStatusAsync(int orderId, OrderStatus status);
    Task<OrderStatistics> GetOrderStatisticsAsync();
}
```

**DTOs:**
```csharp
public class OrderDto
{
    public int Id { get; set; }
    public CustomerDto Customer { get; set; }
    public AddressDto Address { get; set; }
    public List<OrderItemDto> OrderItems { get; set; }
    public DateTime DeliveryDate { get; set; }
    public OrderStatus OrderStatus { get; set; }
    public decimal SubTotal { get; set; }
    public decimal Tax { get; set; }
    public decimal Total { get; set; }
}

public class OrderItemDto
{
    public int Id { get; set; }
    public BookDto Book { get; set; }
    public int Quantity { get; set; }
}

public enum OrderStatus
{
    Pending = 0,
    Processing = 1,
    Shipped = 2,
    Delivered = 3,
    Cancelled = 4
}
```

#### IOfferService

```csharp
public interface IOfferService
{
    Task<OfferDto> GetOfferAsync(int id);
    Task<PaginatedResultDto<OfferDto>> ListOffersAsync(
        OfferFilters filters, int page, int pageSize);
    Task<OfferDto> CreateOfferAsync(CreateOfferDto dto);
    Task UpdateOfferStatusAsync(int id, OfferStatus status, string comment);
    Task<OfferStatistics> GetOfferStatisticsAsync();
}
```

#### IShoppingCartService

```csharp
public interface IShoppingCartService
{
    Task<ShoppingCartDto> GetShoppingCartAsync(string correlationId);
    Task AddItemToCartAsync(string correlationId, int bookId, int quantity);
    Task AddItemToWishlistAsync(string correlationId, int bookId);
    Task MoveWishlistItemToCartAsync(string correlationId, int itemId);
    Task RemoveItemAsync(string correlationId, int itemId);
    Task<CartSummaryDto> GetCartSummaryAsync(string correlationId);
}
```

---

## Authentication and Authorization

### Authentication Mechanisms

#### Local Mode (Development)
**Implementation:** LocalAuthenticationMiddleware (OWIN)

```csharp
public class LocalAuthenticationMiddleware : OwinMiddleware
{
    public override async Task Invoke(IOwinContext context)
    {
        if (context.Request.Path.Value.Contains("/Authentication/Login"))
        {
            var identity = new ClaimsIdentity("Local");
            identity.AddClaim(new Claim(ClaimTypes.Name, "Admin"));
            identity.AddClaim(new Claim("sub", "local-admin"));
            
            context.Authentication.SignIn(identity);
            context.Response.Redirect("/");
            return;
        }
        
        await Next.Invoke(context);
    }
}
```

#### AWS Cognito Mode (Production)
**Implementation:** OpenID Connect Middleware

```csharp
app.UseOpenIdConnectAuthentication(new OpenIdConnectAuthenticationOptions
{
    ClientId = GetSetting("Authentication/Cognito/LocalClientId"),
    MetadataAddress = GetSetting("Authentication/Cognito/MetadataAddress"),
    ResponseType = OpenIdConnectResponseType.Code,
    RedeemCode = true,
    Scope = "openid profile",
    SignInAsAuthenticationType = CookieAuthenticationDefaults.AuthenticationType,
    TokenValidationParameters = new TokenValidationParameters
    {
        NameClaimType = "cognito:username",
        RoleClaimType = "cognito:groups"
    }
});
```

### Claims Structure

```csharp
ClaimsIdentity
{
    Claims:
    [
        { Type: "sub", Value: "<cognito-user-id>" },
        { Type: "cognito:username", Value: "username" },
        { Type: "given_name", Value: "John" },
        { Type: "family_name", Value: "Doe" },
        { Type: "email", Value: "john@example.com" }
    ]
}
```

### Authorization

**Attribute-Based:**
```csharp
[Authorize] // Requires authentication
public class CheckoutController : Controller { }
```

**Code-Based:**
```csharp
if (!User.Identity.IsAuthenticated)
    return RedirectToAction("Login", "Authentication");

var sub = User.Identity.GetSub();
var customer = await customerService.GetCustomerBySubAsync(sub);
```

---

## File Storage

### Storage Providers

#### LocalFileService (Development)
**Location:** Server file system at `wwwroot/Content/uploads`

```csharp
public class LocalFileService : IFileService
{
    private readonly string webRootPath;
    
    public async Task<string> UploadFileAsync(string fileName, Stream fileStream)
    {
        var uploadPath = Path.Combine(webRootPath, "uploads");
        Directory.CreateDirectory(uploadPath);
        
        var filePath = Path.Combine(uploadPath, fileName);
        using (var outputStream = File.Create(filePath))
        {
            await fileStream.CopyToAsync(outputStream);
        }
        
        return $"/Content/uploads/{fileName}";
    }
}
```

#### S3FileService (Production)
**Location:** Amazon S3 bucket

```csharp
public class S3FileService : IFileService
{
    private readonly IAmazonS3 s3Client;
    private readonly string bucketName;
    private readonly string cloudFrontDomain;
    
    public async Task<string> UploadFileAsync(string fileName, Stream fileStream)
    {
        var request = new PutObjectRequest
        {
            BucketName = bucketName,
            Key = fileName,
            InputStream = fileStream,
            ContentType = "image/jpeg"
        };
        
        await s3Client.PutObjectAsync(request);
        
        return $"https://{cloudFrontDomain}/{fileName}";
    }
}
```

### Image Processing

**Image Resizing:**
```csharp
public class ImageResizeService : IImageResizeService
{
    public Stream ResizeImage(Stream imageStream, int width, int height)
    {
        using (var image = new MagickImage(imageStream))
        {
            var size = new MagickGeometry(width, height)
            {
                IgnoreAspectRatio = false,
                FillArea = false
            };
            
            image.Resize(size);
            
            var outputStream = new MemoryStream();
            image.Write(outputStream, MagickFormat.Jpeg);
            outputStream.Position = 0;
            
            return outputStream;
        }
    }
}
```

**Standard Sizes:**
- Book covers: 300x450 pixels
- Offer images: 300x450 pixels

---

## Configuration Management

### Configuration Sources

#### Development (Web.config)
```xml
<appSettings>
    <add key="Services/Authentication" value="local" />
    <add key="Services/Database" value="local" />
    <add key="Services/FileService" value="local" />
    <add key="Services/ImageValidationService" value="local" />
    <add key="Services/LoggingService" value="local" />
</appSettings>

<connectionStrings>
    <add name="BookstoreDatabaseConnection" 
         connectionString="Server=(localdb)\MSSQLLocalDB;..." />
</connectionStrings>
```

#### Production (AWS Systems Manager Parameter Store)
```csharp
public static class BookstoreConfiguration
{
    public static string GetConnectionString(string name)
    {
        if (GetSetting("Services/Database") == "aws")
        {
            // Retrieve from SSM Parameter Store
            var ssmClient = new AmazonSimpleSystemsManagementClient();
            var request = new GetParameterRequest
            {
                Name = $"/bookstore/ConnectionStrings/{name}",
                WithDecryption = true
            };
            var response = ssmClient.GetParameterAsync(request).Result;
            return response.Parameter.Value;
        }
        
        return ConfigurationManager.ConnectionStrings[name].ConnectionString;
    }
}
```

### Configuration Keys

| Key | Development Value | Production Value | Purpose |
|-----|------------------|------------------|---------|
| Services/Authentication | local | aws | Auth provider |
| Services/Database | local | aws | DB connection |
| Services/FileService | local | aws | File storage |
| Services/ImageValidationService | local | aws | Image validation |
| Services/LoggingService | local | aws | Logging target |
| Authentication/Cognito/LocalClientId | N/A | From SSM | Cognito client |
| Authentication/Cognito/MetadataAddress | N/A | From SSM | OIDC metadata |
| Files/BucketName | N/A | From SSM | S3 bucket |
| Files/CloudFrontDomain | N/A | From SSM | CloudFront URL |

---

## Logging and Monitoring

### Logging Framework
**NLog 5.4.0** with dual targets

#### Development Logging
**Target:** File system

**NLog.config:**
```xml
<nlog>
    <targets>
        <target name="file" type="File" fileName="logs/bookstore-${shortdate}.log" />
    </targets>
    <rules>
        <logger name="*" minlevel="Info" writeTo="file" />
    </rules>
</nlog>
```

#### Production Logging
**Target:** AWS CloudWatch Logs

**Configuration:**
```csharp
builder.RegisterType<AWS.Logger.NLog.AWSTarget>()
    .WithParameter("logGroup", "/aws/ecs/bookstore")
    .WithParameter("region", "us-east-1");
```

### Log Levels
- **Fatal:** Application crashes
- **Error:** Exceptions and errors
- **Warn:** Warning conditions
- **Info:** General information (default)
- **Debug:** Detailed debugging (development)
- **Trace:** Very detailed (not used)

### Logged Events
- Application start/stop
- User authentication
- Order placement
- Exceptions and errors
- Database errors
- AWS service calls

---

## Deployment Architecture

### Development Deployment

```
Developer Workstation (Windows)
├── Visual Studio 2022 / Rider
├── IIS Express (HTTP, random port)
├── SQL Server LocalDB
├── Local file system (Content/)
└── Browser (https://localhost:44300)
```

**Requirements:**
- Windows 10/11
- .NET Framework 4.8 SDK
- Visual Studio 2022 or Rider
- SQL Server LocalDB (included with VS)

**Startup:**
1. Open solution in IDE
2. Set Bookstore.Web as startup project
3. Press F5
4. Application runs on IIS Express
5. Database auto-created on first run

---

### Production Deployment (AWS ECS)

```
Internet → ALB (Port 80/443)
         ↓
    ECS Fargate (Windows Containers)
    ├── Container: bookstore-web
    │   ├── Windows Server Core 2022
    │   ├── IIS 10.0
    │   ├── .NET Framework 4.8
    │   └── Bookstore.Web
    ↓
RDS for SQL Server (Private subnet)
Amazon S3 (Book covers)
Amazon Cognito (Authentication)
AWS Systems Manager (Configuration)
CloudWatch Logs (Logging)
```

**Requirements:**
- AWS Account
- ECS Cluster (Fargate)
- Application Load Balancer
- RDS for SQL Server
- S3 Bucket with CloudFront
- Cognito User Pool
- Systems Manager Parameter Store
- CloudWatch Log Group

**Container Specifications:**
- **Base Image:** mcr.microsoft.com/windows/servercore:ltsc2022
- **Platform:** windows/amd64
- **Memory:** 4GB
- **CPU:** 2 vCPU
- **Port:** 80 (HTTP)

**Dockerfile:**
```dockerfile
FROM mcr.microsoft.com/dotnet/framework/aspnet:4.8-windowsservercore-ltsc2022

WORKDIR /inetpub/wwwroot

COPY published-app/ .

EXPOSE 80

ENTRYPOINT ["C:\\ServiceMonitor.exe", "w3svc"]
```

---

### Production Deployment (Windows Server + IIS)

```
Windows Server 2019/2022
├── IIS 10.0
│   ├── Application Pool (.NET CLR v4.0)
│   └── Website (Port 80/443)
├── SQL Server 2019/2022
└── File System (Optional, or use S3)
```

**Requirements:**
- Windows Server 2019 or 2022
- IIS 10.0 with ASP.NET 4.8
- SQL Server 2019 or 2022
- .NET Framework 4.8
- SSL Certificate (for HTTPS)

**IIS Configuration:**
- Application Pool: .NET CLR v4.0, Integrated Pipeline
- Identity: ApplicationPoolIdentity or custom service account
- Bindings: Port 80 (HTTP), Port 443 (HTTPS)
- Physical path: C:\inetpub\bookstore\

**Deployment Steps:**
1. Publish application from Visual Studio
2. Copy published files to IIS directory
3. Create IIS application pool
4. Create IIS website
5. Configure connection strings
6. Set up SSL certificate
7. Grant file permissions to app pool identity
8. Create database on SQL Server
9. Test application

---

## Security Specifications

### Transport Security
- **HTTPS:** Required in production (TLS 1.2+)
- **HTTP:** Development only

### Data Protection
- **Passwords:** Managed by Cognito (not stored locally)
- **Connection Strings:** Encrypted in Parameter Store
- **Session Cookies:** HttpOnly, Secure flags in production
- **Anti-Forgery Tokens:** ValidateAntiForgeryToken on state-changing actions

### Input Validation
- **Server-Side:** DataAnnotations on view models
- **Client-Side:** jQuery Validation
- **SQL Injection:** Protected by EF parameterized queries
- **XSS:** Protected by Razor encoding
- **File Upload:** Type and size validation

### Image Upload Security
```csharp
[MaxFileSize(5 * 1024 * 1024)] // 5MB
[ImageTypes] // jpg, jpeg, png only
public HttpPostedFileBase CoverImage { get; set; }
```

**Content Validation (AWS Mode):**
- Amazon Rekognition moderates uploaded images
- Rejects inappropriate content
- Confidence threshold: 80%

---

## Performance Specifications

### Response Time Targets
- **Home Page:** < 1 second
- **Search Results:** < 2 seconds
- **Book Details:** < 1 second
- **Checkout:** < 2 seconds

### Database Performance
- **Eager Loading:** Uses .Include() to prevent N+1 queries
- **Pagination:** All list queries use pageSize and pageIndex
- **Indexes:** Foreign keys and unique constraints indexed
- **Connection Pooling:** Enabled by default

### Caching
- **Static Resources:** Bundling and minification
- **Images:** CloudFront CDN in AWS mode
- **No Application-Level Caching:** All data fetched from database

### Scalability
- **Stateless Design:** No in-memory session state
- **Horizontal Scaling:** Multiple IIS/container instances supported
- **Database:** Single SQL Server instance (vertical scaling)
- **File Storage:** S3 supports unlimited scale

---

**Next:** 09-migration-considerations.md
