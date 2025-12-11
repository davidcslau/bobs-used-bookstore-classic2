# Migration Considerations - .NET Framework 4.8 to .NET Core 8.0 and PostgreSQL

**Document Version:** 1.0  
**Date:** December 11, 2024  
**Source:** .NET Framework 4.8 + SQL Server  
**Target:** .NET Core 8.0 + PostgreSQL

---

## Table of Contents
1. [Executive Summary](#executive-summary)
2. [.NET Framework to .NET Core Migration](#net-framework-to-net-core-migration)
3. [SQL Server to PostgreSQL Migration](#sql-server-to-postgresql-migration)
4. [Breaking Changes and Challenges](#breaking-changes-and-challenges)
5. [Migration Strategy](#migration-strategy)
6. [Testing Requirements](#testing-requirements)
7. [Risk Assessment](#risk-assessment)

---

## Executive Summary

Migrating Bob's Used Bookstore Classic from .NET Framework 4.8 to .NET Core 8.0 and from SQL Server to PostgreSQL represents a significant modernization effort. This document identifies the key challenges, breaking changes, and recommendations for a successful migration.

**Migration Complexity:** Medium to High

**Estimated Effort:** 4-6 weeks (2 developers)

**Key Benefits:**
- Cross-platform support (Linux, Docker)
- Improved performance (5-10x in some scenarios)
- Modern development experience
- Reduced licensing costs (PostgreSQL is free)
- Better cloud-native support
- Long-term support and updates

---

## .NET Framework to .NET Core Migration

### Framework Compatibility

#### Compatible Components (Low Effort)

✅ **Domain Layer (Bookstore.Domain)**
- Pure C# classes with no framework dependencies
- No changes required for most domain entities
- DataAnnotations attributes compatible

✅ **Service Interfaces**
- Interface definitions unchanged
- DTOs compatible

✅ **Repository Pattern**
- Interface definitions unchanged
- Implementation requires EF Core changes

#### Incompatible Components (High Effort)

❌ **ASP.NET MVC 5 → ASP.NET Core MVC**
- Complete rewrite of web layer required
- Different project structure
- Different startup/configuration
- Different middleware pipeline

❌ **Entity Framework 6.5.1 → Entity Framework Core 8**
- Different API surface
- Migration strategy changes
- Some LINQ queries may need rewriting

❌ **OWIN → ASP.NET Core Middleware**
- Complete authentication rewrite
- Different middleware pipeline
- Built-in DI instead of Autofac (though Autofac still compatible)

❌ **System.Web Dependencies**
- HttpContext API changed
- No System.Web.Mvc
- No System.Web.HttpPostedFileBase

---

### ASP.NET MVC 5 to ASP.NET Core MVC Changes

#### Project Structure

**Before (.NET Framework):**
```
Bookstore.Web/
├── App_Start/
├── Areas/
├── Controllers/
├── Models/
├── Views/
├── Content/
├── Scripts/
├── Global.asax
├── Web.config
└── packages.config
```

**After (.NET Core):**
```
Bookstore.Web/
├── Controllers/
├── Models/
├── Views/
├── wwwroot/          ← Static files moved here
│   ├── css/
│   ├── js/
│   └── images/
├── Areas/
├── Program.cs        ← Replaces Global.asax
├── appsettings.json  ← Replaces Web.config
└── Startup.cs (or Program.cs with minimal hosting)
```

#### Configuration Changes

**Before (Web.config):**
```xml
<appSettings>
    <add key="Services/Authentication" value="local" />
</appSettings>

<connectionStrings>
    <add name="BookstoreDatabaseConnection" connectionString="..." />
</connectionStrings>
```

**After (appsettings.json):**
```json
{
  "Services": {
    "Authentication": "local"
  },
  "ConnectionStrings": {
    "BookstoreDatabaseConnection": "..."
  }
}
```

**Access Pattern Changes:**
```csharp
// Before
string value = ConfigurationManager.AppSettings["Services/Authentication"];

// After
string value = _configuration["Services:Authentication"];
```

#### Startup Changes

**Before (Global.asax.cs):**
```csharp
public class MvcApplication : System.Web.HttpApplication
{
    protected void Application_Start()
    {
        AreaRegistration.RegisterAllAreas();
        FilterConfig.RegisterGlobalFilters(GlobalFilters.Filters);
        RouteConfig.RegisterRoutes(RouteTable.Routes);
        BundleConfig.RegisterBundles(BundleTable.Bundles);
    }
}
```

**After (Program.cs - .NET 8 style):**
```csharp
var builder = WebApplication.CreateBuilder(args);

// Add services
builder.Services.AddControllersWithViews();
builder.Services.AddDbContext<ApplicationDbContext>(options =>
    options.UseNpgsql(builder.Configuration.GetConnectionString("BookstoreDatabaseConnection")));

// Add authentication
builder.Services.AddAuthentication(CookieAuthenticationDefaults.AuthenticationScheme)
    .AddCookie()
    .AddOpenIdConnect(options => { ... });

// Dependency injection
builder.Services.AddScoped<IBookService, BookService>();
builder.Services.AddScoped<IBookRepository, BookRepository>();

var app = builder.Build();

// Middleware pipeline
app.UseStaticFiles();
app.UseRouting();
app.UseAuthentication();
app.UseAuthorization();

app.MapControllerRoute(
    name: "default",
    pattern: "{controller=Home}/{action=Index}/{id?}");

app.Run();
```

#### Controller Changes

**Before:**
```csharp
public class SearchController : Controller
{
    private readonly IBookService bookService;
    
    public SearchController(IBookService bookService)
    {
        this.bookService = bookService;
    }
    
    public async Task<ActionResult> Index(BookFilters filters, int page = 1)
    {
        var results = await bookService.SearchBooksAsync(filters, page, 20);
        var vm = new SearchIndexViewModel { Books = results.Items };
        return View(vm);
    }
}
```

**After (minimal changes):**
```csharp
public class SearchController : Controller
{
    private readonly IBookService _bookService;
    
    public SearchController(IBookService bookService)
    {
        _bookService = bookService;
    }
    
    public async Task<IActionResult> Index(BookFilters filters, int page = 1)
    {
        var results = await _bookService.SearchBooksAsync(filters, page, 20);
        var vm = new SearchIndexViewModel { Books = results.Items };
        return View(vm);
    }
}
```

**Key Differences:**
- `ActionResult` → `IActionResult`
- Private readonly fields typically use `_` prefix
- Otherwise very similar!

#### File Upload Changes

**Before:**
```csharp
[HttpPost]
public async Task<ActionResult> Create(HttpPostedFileBase coverImage)
{
    if (coverImage != null)
    {
        var stream = coverImage.InputStream;
        var contentType = coverImage.ContentType;
        // Process file
    }
}
```

**After:**
```csharp
[HttpPost]
public async Task<IActionResult> Create(IFormFile coverImage)
{
    if (coverImage != null)
    {
        using var stream = coverImage.OpenReadStream();
        var contentType = coverImage.ContentType;
        // Process file
    }
}
```

**Changes:**
- `HttpPostedFileBase` → `IFormFile`
- `InputStream` → `OpenReadStream()`

#### HttpContext Changes

**Before:**
```csharp
var correlationId = HttpContext.Request.Cookies["CorrelationId"]?.Value;
HttpContext.Response.Cookies.Add(new HttpCookie("CorrelationId", guid));
```

**After:**
```csharp
var correlationId = HttpContext.Request.Cookies["CorrelationId"];
HttpContext.Response.Cookies.Append("CorrelationId", guid, new CookieOptions
{
    Expires = DateTimeOffset.Now.AddYears(1),
    HttpOnly = true,
    Secure = true
});
```

---

### Entity Framework 6 to Entity Framework Core 8

#### DbContext Changes

**Before (EF 6):**
```csharp
public class ApplicationDbContext : DbContext
{
    public ApplicationDbContext(string connectionString) : base(connectionString) { }
    
    public DbSet<Book> Book { get; set; }
    
    protected override void OnModelCreating(DbModelBuilder modelBuilder)
    {
        modelBuilder.Conventions.Remove<PluralizingTableNameConvention>();
        
        modelBuilder.Entity<Customer>()
            .Property(x => x.Sub)
            .HasColumnType("nvarchar")
            .HasMaxLength(450);
        
        modelBuilder.Entity<Customer>()
            .HasIndex(x => x.Sub)
            .IsUnique();
        
        Database.SetInitializer(new BookstoreDbInitializer());
    }
}
```

**After (EF Core 8):**
```csharp
public class ApplicationDbContext : DbContext
{
    public ApplicationDbContext(DbContextOptions<ApplicationDbContext> options) 
        : base(options) { }
    
    public DbSet<Book> Books { get; set; }  // Plural recommended
    
    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        // No pluralization convention to remove in EF Core
        
        modelBuilder.Entity<Customer>(entity =>
        {
            entity.Property(x => x.Sub)
                .HasColumnType("varchar(450)")
                .IsRequired();
            
            entity.HasIndex(x => x.Sub)
                .IsUnique();
        });
        
        // Database initialization done via migrations
    }
}
```

**Key Differences:**
- Constructor takes `DbContextOptions` instead of connection string
- `DbModelBuilder` → `ModelBuilder`
- `.HasColumnType("nvarchar")` → `.HasColumnType("varchar")` for PostgreSQL
- No `Database.SetInitializer()` - use migrations
- Fluent API slightly different syntax

#### Migration Strategy

**EF 6 Migrations:**
```bash
Enable-Migrations
Add-Migration InitialCreate
Update-Database
```

**EF Core Migrations:**
```bash
dotnet ef migrations add InitialCreate
dotnet ef database update
```

#### LINQ Query Changes

Most LINQ queries work unchanged, but some differences:

**Before (EF 6):**
```csharp
var books = await dbContext.Book
    .Include("Genre")           // String-based include
    .Include("Publisher")
    .ToListAsync();
```

**After (EF Core 8):**
```csharp
var books = await dbContext.Books
    .Include(x => x.Genre)      // Strongly-typed include (preferred)
    .Include(x => x.Publisher)
    .ToListAsync();
```

**Composite Key Definition:**

**Before (EF 6):**
```csharp
modelBuilder.Entity<ShoppingCartItem>()
    .HasKey(x => new { x.Id, x.ShoppingCartId });

modelBuilder.Entity<ShoppingCartItem>()
    .Property(x => x.Id)
    .HasDatabaseGeneratedOption(DatabaseGeneratedOption.Identity);
```

**After (EF Core 8):**
```csharp
modelBuilder.Entity<ShoppingCartItem>()
    .HasKey(x => new { x.Id, x.ShoppingCartId });

modelBuilder.Entity<ShoppingCartItem>()
    .Property(x => x.Id)
    .ValueGeneratedOnAdd();  // Identity behavior
```

---

### Authentication Changes

#### OWIN to ASP.NET Core Middleware

**Before (OWIN):**
```csharp
public void Configuration(IAppBuilder app)
{
    app.UseCookieAuthentication(new CookieAuthenticationOptions());
    
    app.UseOpenIdConnectAuthentication(new OpenIdConnectAuthenticationOptions
    {
        ClientId = "...",
        MetadataAddress = "...",
        ResponseType = OpenIdConnectResponseType.Code,
        // ...
    });
}
```

**After (ASP.NET Core):**
```csharp
builder.Services
    .AddAuthentication(options =>
    {
        options.DefaultScheme = CookieAuthenticationDefaults.AuthenticationScheme;
        options.DefaultChallengeScheme = OpenIdConnectDefaults.AuthenticationScheme;
    })
    .AddCookie()
    .AddOpenIdConnect(options =>
    {
        options.ClientId = "...";
        options.MetadataAddress = "...";
        options.ResponseType = OpenIdConnectResponseType.Code;
        // ...
    });

// In middleware pipeline
app.UseAuthentication();
app.UseAuthorization();
```

**Claims Access:**
```csharp
// Before
var sub = ((ClaimsIdentity)User.Identity).FindFirst("sub").Value;

// After (same)
var sub = User.FindFirst("sub")?.Value;
```

---

### Dependency Injection Changes

#### Autofac to Built-in DI

**Before (Autofac):**
```csharp
var builder = new ContainerBuilder();
builder.RegisterControllers(typeof(MvcApplication).Assembly);
builder.RegisterType<BookService>().As<IBookService>();
builder.RegisterType<ApplicationDbContext>().InstancePerRequest();

var container = builder.Build();
DependencyResolver.SetResolver(new AutofacDependencyResolver(container));
```

**After (Built-in DI):**
```csharp
builder.Services.AddScoped<IBookService, BookService>();
builder.Services.AddScoped<IBookRepository, BookRepository>();
builder.Services.AddDbContext<ApplicationDbContext>();
```

**Note:** Can still use Autofac if needed, but built-in DI is sufficient for this application.

**Lifetime Mappings:**
- `InstancePerRequest` → `Scoped`
- `SingleInstance` → `Singleton`
- `InstancePerDependency` → `Transient`

---

## SQL Server to PostgreSQL Migration

### Data Type Mapping

| SQL Server | PostgreSQL | Notes |
|------------|------------|-------|
| int IDENTITY(1,1) | serial or integer + sequence | Auto-increment |
| nvarchar(MAX) | text | Unlimited text |
| nvarchar(450) | varchar(450) | Fixed length |
| decimal(18,2) | numeric(18,2) | Same precision |
| datetime2 | timestamp | Similar behavior |
| bit | boolean | True/false |
| varbinary(MAX) | bytea | Binary data |

### Entity Framework Configuration Changes

**Before (SQL Server):**
```csharp
modelBuilder.Entity<Customer>()
    .Property(x => x.Sub)
    .HasColumnType("nvarchar")
    .HasMaxLength(450);
```

**After (PostgreSQL):**
```csharp
modelBuilder.Entity<Customer>()
    .Property(x => x.Sub)
    .HasColumnType("varchar")  // No 'n' prefix
    .HasMaxLength(450);
```

### Connection String Changes

**Before (SQL Server):**
```
Server=(localdb)\MSSQLLocalDB;Initial Catalog=BookStoreClassic;Integrated Security=SSPI;
```

**After (PostgreSQL):**
```
Host=localhost;Port=5432;Database=bookstore;Username=postgres;Password=password;
```

### SQL Syntax Differences

#### String Concatenation
```sql
-- SQL Server
SELECT FirstName + ' ' + LastName AS FullName

-- PostgreSQL
SELECT FirstName || ' ' || LastName AS FullName
```

#### Case Sensitivity
```sql
-- SQL Server (case-insensitive by default)
SELECT * FROM Book WHERE Name = 'test'

-- PostgreSQL (case-sensitive)
SELECT * FROM "Book" WHERE "Name" = 'test'  -- Exact case
SELECT * FROM book WHERE name ILIKE 'test'  -- Case-insensitive
```

**Recommendation:** Use lowercase table/column names in PostgreSQL

#### TOP vs LIMIT
```sql
-- SQL Server
SELECT TOP 10 * FROM Book

-- PostgreSQL
SELECT * FROM Book LIMIT 10
```

**Note:** EF Core abstracts this away

#### Identity Columns
```sql
-- SQL Server
Id int IDENTITY(1,1) PRIMARY KEY

-- PostgreSQL (two options)
Id serial PRIMARY KEY
-- or
Id integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY
```

### Database Migration Tools

#### Schema Migration
Use **pgLoader** or **AWS Schema Conversion Tool** for initial schema conversion

```bash
# pgLoader example
pgloader mssql://server/BookStoreClassic postgresql://localhost/bookstore
```

#### Data Migration
1. Export SQL Server data to CSV
2. Import to PostgreSQL using COPY command

```sql
-- Export from SQL Server (using bcp or SSMS)
bcp "SELECT * FROM Book" queryout books.csv -c -t,

-- Import to PostgreSQL
COPY book FROM '/path/to/books.csv' DELIMITER ',' CSV HEADER;
```

---

## Breaking Changes and Challenges

### High-Risk Areas

#### 1. Entity Framework Query Translations

**Challenge:** Some LINQ queries that work in EF 6 may not translate in EF Core

**Example:**
```csharp
// May not work in EF Core
var books = await context.Books
    .Where(x => x.Name.Contains(search) || x.Author.Contains(search))
    .ToListAsync();
```

**Solution:** Test all queries, use .AsEnumerable() for client evaluation if needed

#### 2. Transaction Handling

**Before (EF 6):**
```csharp
using (var transaction = dbContext.Database.BeginTransaction())
{
    // Operations
    transaction.Commit();
}
```

**After (EF Core):**
```csharp
using (var transaction = await dbContext.Database.BeginTransactionAsync())
{
    // Operations
    await transaction.CommitAsync();
}
```

#### 3. Lazy Loading

**Before (EF 6):** Lazy loading enabled by default

**After (EF Core):** Lazy loading disabled by default, must enable explicitly

```csharp
// Enable lazy loading in EF Core
builder.Services.AddDbContext<ApplicationDbContext>(options =>
    options.UseNpgsql(connectionString)
           .UseLazyLoadingProxies());  // Requires Microsoft.EntityFrameworkCore.Proxies
```

**Recommendation:** Use explicit eager loading with `.Include()` instead

#### 4. Image Processing

**Magick.NET:** Works on both .NET Framework and .NET Core

**No changes needed** for image processing code

#### 5. AWS SDK

**AWS SDK:** Same packages work on .NET Core

**No changes needed** for AWS integrations

---

### Medium-Risk Areas

#### 1. Bundling and Minification

**Before:** Microsoft.AspNet.Web.Optimization

**After:** Multiple options:
- **WebOptimizer** (NuGet package)
- **Built-in bundling** in .NET 6+
- **Webpack, Vite** (client-side tools)

**Recommendation:** Use WebOptimizer for minimal changes

#### 2. Areas

**Before:** Areas registered in App_Start

**After:** Areas work similarly but registered in Program.cs

```csharp
app.MapAreaControllerRoute(
    name: "admin",
    areaName: "Admin",
    pattern: "Admin/{controller=Dashboard}/{action=Index}/{id?}");
```

#### 3. Custom Validation Attributes

**MaxFileSizeAttribute, ImageTypesAttribute:** Work unchanged

Minor changes needed for `IFormFile` instead of `HttpPostedFileBase`

---

### Low-Risk Areas

✅ **Domain Models:** No changes  
✅ **Service Interfaces:** No changes  
✅ **DTOs:** No changes  
✅ **Business Logic:** No changes  
✅ **Repository Interfaces:** No changes  
✅ **Enums:** No changes  

---

## Migration Strategy

### Recommended Approach: Incremental Migration

#### Phase 1: Preparation (1 week)
1. **Document Current State**
   - ✅ Complete (this documentation)

2. **Set Up Target Environment**
   - Install .NET 8 SDK
   - Set up PostgreSQL development instance
   - Install EF Core tools
   ```bash
   dotnet tool install --global dotnet-ef
   ```

3. **Create New Solution Structure**
   - Create .NET 8 solution
   - Migrate project structure
   - Update .csproj files

4. **Migrate Domain Layer**
   - Copy domain entities
   - Update namespaces
   - Compile and fix any issues (should be minimal)

#### Phase 2: Data Layer Migration (1-2 weeks)
1. **Migrate to EF Core**
   - Install Npgsql.EntityFrameworkCore.PostgreSQL
   - Update ApplicationDbContext for EF Core
   - Convert Fluent API configurations
   - Update data types for PostgreSQL

2. **Create Initial Migration**
   ```bash
   dotnet ef migrations add InitialCreate
   ```

3. **Migrate Repositories**
   - Update repository implementations
   - Update LINQ queries
   - Test all data access operations

4. **Database Migration**
   - Run schema conversion
   - Migrate data from SQL Server to PostgreSQL
   - Verify data integrity

#### Phase 3: Web Layer Migration (1-2 weeks)
1. **Set Up ASP.NET Core Project**
   - Create new ASP.NET Core project
   - Configure Program.cs / Startup.cs
   - Set up appsettings.json

2. **Migrate Controllers**
   - Copy controllers
   - Update ActionResult → IActionResult
   - Update file upload code
   - Update HttpContext usage

3. **Migrate Views**
   - Copy Razor views
   - Update view references
   - Move static files to wwwroot

4. **Migrate Authentication**
   - Set up ASP.NET Core authentication
   - Configure OpenID Connect
   - Update authentication logic

5. **Migrate Areas**
   - Copy admin area
   - Register routes
   - Test admin functionality

#### Phase 4: Testing and Validation (1 week)
1. **Unit Testing**
   - Test domain logic
   - Test repositories
   - Test services

2. **Integration Testing**
   - Test controllers
   - Test database operations
   - Test authentication

3. **End-to-End Testing**
   - Test all user workflows
   - Test admin workflows
   - Performance testing

4. **Migration Testing**
   - Verify data migration accuracy
   - Test with production-like data volume

#### Phase 5: Deployment (1 week)
1. **Update Infrastructure**
   - Migrate to Linux containers (optional)
   - Set up PostgreSQL RDS
   - Update ECS task definitions

2. **Deploy to Staging**
   - Deploy application
   - Run smoke tests
   - Performance validation

3. **Production Cutover**
   - Migrate production data
   - Deploy to production
   - Monitor for issues

---

## Testing Requirements

### Unit Tests
- Test all service methods
- Test repository methods with in-memory provider
- Test domain model business logic

### Integration Tests
- Test database operations with PostgreSQL
- Test authentication flows
- Test file upload/storage

### End-to-End Tests
- User registration and login
- Book browsing and search
- Shopping cart operations
- Checkout process
- Order management
- Offer submission and approval
- Admin functions

### Performance Tests
- Load testing with expected user volume
- Database query performance
- Image processing performance
- Compare with .NET Framework baseline

### Compatibility Tests
- Browser compatibility
- Mobile responsiveness
- AWS services integration

---

## Risk Assessment

### High Risks

| Risk | Impact | Mitigation |
|------|--------|------------|
| Data migration errors | High | Extensive validation, rollback plan |
| EF Core query incompatibilities | High | Thorough testing of all queries |
| Breaking changes in authentication | High | Parallel testing environment |
| Production downtime | High | Blue-green deployment |

### Medium Risks

| Risk | Impact | Mitigation |
|------|--------|------------|
| Performance regressions | Medium | Performance testing, benchmarking |
| Unexpected API changes | Medium | Comprehensive integration tests |
| Third-party package compatibility | Medium | Test early, find alternatives |

### Low Risks

| Risk | Impact | Mitigation |
|------|--------|------------|
| View rendering differences | Low | Visual regression testing |
| Configuration issues | Low | Configuration validation |
| Static file serving | Low | Standard patterns |

---

## Estimated Costs

### Development Costs
- **Developer Time:** 4-6 weeks × 2 developers = 8-12 weeks
- **Testing:** 1 week × QA engineer

### Infrastructure Costs
**SQL Server → PostgreSQL Savings:**
- RDS SQL Server: ~$200-500/month
- RDS PostgreSQL: ~$50-150/month
- **Annual Savings:** ~$1,800-4,200

**Windows Containers → Linux Containers (Optional):**
- Windows container: ~$150-300/month
- Linux container: ~$50-100/month
- **Annual Savings:** ~$1,200-2,400

**Total Potential Annual Savings:** $3,000-6,600

---

## Rollback Plan

### Pre-Migration
1. **Full Backup**
   - SQL Server database backup
   - Application code backup
   - Configuration backup

2. **Parallel Environment**
   - Keep .NET Framework version running
   - Run .NET Core in separate environment
   - Blue-green deployment

### Post-Migration Issues

**Critical Issues (within 24 hours):**
1. Switch traffic back to .NET Framework version
2. Investigate issues
3. Fix and re-deploy

**Non-Critical Issues:**
1. Fix in .NET Core version
2. Deploy updates
3. Monitor

---

## Recommendations

### Do's
✅ Migrate in phases  
✅ Maintain backward compatibility where possible  
✅ Write comprehensive tests  
✅ Use feature flags for gradual rollout  
✅ Keep .NET Framework version as backup initially  
✅ Monitor performance metrics  
✅ Document all changes  

### Don'ts
❌ Don't migrate everything at once  
❌ Don't skip testing  
❌ Don't delete .NET Framework code until stable  
❌ Don't ignore warnings and deprecations  
❌ Don't migrate without stakeholder buy-in  

---

## Conclusion

Migration from .NET Framework 4.8 to .NET Core 8.0 and SQL Server to PostgreSQL is achievable with careful planning and execution. The well-structured codebase with clear separation of concerns makes this migration more manageable than it might otherwise be.

**Key Success Factors:**
1. Comprehensive documentation (this document)
2. Incremental migration approach
3. Thorough testing at each phase
4. Rollback capability
5. Monitoring and validation

**Expected Outcome:**
- Modern, cross-platform application
- Improved performance
- Reduced infrastructure costs
- Better maintainability
- Future-proof technology stack

---

**End of Migration Documentation**
