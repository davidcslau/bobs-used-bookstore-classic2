# Migration Notes - .NET Framework 4.8 to .NET 8.0

## Summary of Changes

This document outlines all the changes made during the migration from .NET Framework 4.8 to .NET 8.0.

## Domain Layer (Bookstore.Domain)

### Changes Made
- ✅ Updated project to SDK-style `.csproj` format
- ✅ Changed target framework from `net48` to `net8.0`
- ✅ Minimal code changes (domain layer is mostly framework-agnostic)
- ✅ Removed `Properties/AssemblyInfo.cs` (handled by SDK-style projects)

### No Changes Required
- Domain entities remain unchanged
- Service interfaces remain unchanged
- DTOs remain unchanged
- Business logic remains unchanged

## Data Layer (Bookstore.Data)

### Major Changes

#### Entity Framework Migration
- **Old**: Entity Framework 6.5.1 (`System.Data.Entity`)
- **New**: Entity Framework Core 8.0 (`Microsoft.EntityFrameworkCore`)

#### Database Provider
- **Old**: SQL Server (`System.Data.SqlClient`)
- **New**: PostgreSQL (`Npgsql.EntityFrameworkCore.PostgreSQL`)

#### ApplicationDbContext
**Before:**
```csharp
public class ApplicationDbContext : DbContext
{
    public ApplicationDbContext(string connectionString) : base(connectionString) { }
    
    protected override void OnModelCreating(DbModelBuilder modelBuilder)
    {
        modelBuilder.Conventions.Remove<PluralizingTableNameConvention>();
        modelBuilder.Entity<Book>().HasRequired(x => x.Genre).WithMany()...
    }
}
```

**After:**
```csharp
public class ApplicationDbContext : DbContext
{
    public ApplicationDbContext(DbContextOptions<ApplicationDbContext> options) 
        : base(options) { }
    
    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.Entity<Book>().HasOne(x => x.Genre).WithMany()
            .OnDelete(DeleteBehavior.Restrict)...
    }
}
```

#### Repository Pattern
**Include changes:**
- **Old**: `.Include("Genre")` (string-based)
- **New**: `.Include(x => x.Genre)` (strongly-typed)

**Add method:**
- **Old**: `dbContext.Book.Add(book)` (synchronous)
- **New**: `await dbContext.Book.AddAsync(book)` (async)

#### Database Initialization
- **Old**: `Database.SetInitializer<T>()` in OnModelCreating
- **New**: `BookstoreDbInitializer.SeedAsync()` called from Program.cs

#### Data Type Mapping

| .NET Framework/SQL Server | .NET Core/PostgreSQL |
|---------------------------|----------------------|
| `nvarchar(450)` | `varchar(450)` |
| `int IDENTITY(1,1)` | `serial` or `ValueGeneratedOnAdd()` |
| `HasRequired()` | `HasOne()` |
| `WillCascadeOnDelete()` | `OnDelete(DeleteBehavior.Restrict)` |
| `HasDatabaseGeneratedOption()` | `ValueGeneratedOnAdd()` |

#### File Services
- Updated `LocalFileService` to use Linux-compatible paths
- Changed return path from `/Content/images/` to `/images/`
- Made compatible with ASP.NET Core's wwwroot structure

## Web Layer (Bookstore.Web)

### Project Structure Changes

**Old Structure:**
```
Bookstore.Web/
├── App_Start/          # Configuration classes
├── Controllers/
├── Models/
├── Views/
├── Content/           # Static files
├── Scripts/           # JavaScript
├── Global.asax        # Application startup
├── Web.config         # Configuration
└── packages.config    # NuGet packages
```

**New Structure:**
```
Bookstore.Web/
├── Controllers/
├── Models/
├── Views/
├── wwwroot/          # Static files (new location)
│   ├── css/
│   ├── js/
│   └── images/
├── Program.cs        # Application startup
├── appsettings.json  # Configuration
└── nlog.config       # Logging configuration
```

### Startup Configuration

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

**After (Program.cs):**
```csharp
var builder = WebApplication.CreateBuilder(args);

builder.Services.AddControllersWithViews();
builder.Services.AddDbContext<ApplicationDbContext>(options =>
    options.UseNpgsql(connectionString));

// Register services and repositories
builder.Services.AddScoped<IBookService, BookService>();
// ... more services

var app = builder.Build();

app.UseStaticFiles();
app.UseRouting();
app.UseAuthentication();
app.UseAuthorization();

app.MapControllerRoute(
    name: "default",
    pattern: "{controller=Home}/{action=Index}/{id?}");

app.Run();
```

### Configuration Changes

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
    "BookstoreDatabaseConnection": "Host=localhost;Port=5432;..."
  }
}
```

### Controller Changes

**Namespace changes:**
- `System.Web.Mvc` → `Microsoft.AspNetCore.Mvc`
- `System.Web` → `Microsoft.AspNetCore.Http`

**Return type changes:**
- `ActionResult` → `IActionResult`
- `Task<ActionResult>` → `Task<IActionResult>`

**File upload changes:**
- `HttpPostedFileBase` → `IFormFile`
- `file.InputStream` → `file.OpenReadStream()`

**Cookie changes:**
- `HttpContext.Response.Cookies.Add()` → `HttpContext.Response.Cookies.Append()`
- Different API for cookie options

### Authentication Changes

**Before (OWIN - Startup.cs):**
```csharp
public void Configuration(IAppBuilder app)
{
    app.UseCookieAuthentication(new CookieAuthenticationOptions());
    app.UseOpenIdConnectAuthentication(new OpenIdConnectAuthenticationOptions {...});
}
```

**After (Program.cs):**
```csharp
builder.Services
    .AddAuthentication(options =>
    {
        options.DefaultScheme = CookieAuthenticationDefaults.AuthenticationScheme;
        options.DefaultChallengeScheme = OpenIdConnectDefaults.AuthenticationScheme;
    })
    .AddCookie()
    .AddOpenIdConnect(options => {...});
```

### Dependency Injection

**Before (Autofac):**
```csharp
var builder = new ContainerBuilder();
builder.RegisterType<BookService>().As<IBookService>().InstancePerRequest();
var container = builder.Build();
DependencyResolver.SetResolver(new AutofacDependencyResolver(container));
```

**After (Built-in DI):**
```csharp
builder.Services.AddScoped<IBookService, BookService>();
```

**Lifetime mapping:**
- `InstancePerRequest` → `Scoped`
- `SingleInstance` → `Singleton`
- `InstancePerDependency` → `Transient`

### View Changes

**Static file references:**
- `/Content/Images/` → `/images/`
- `/Content/css/` → `/css/`
- `/Scripts/` → `/js/`

**Model binding:**
- SelectListItem moved from `System.Web.Mvc` to `Microsoft.AspNetCore.Mvc.Rendering`

### Areas

Areas work similarly but are registered in Program.cs:
```csharp
app.MapAreaControllerRoute(
    name: "admin",
    areaName: "Admin",
    pattern: "Admin/{controller=Dashboard}/{action=Index}/{id?}");
```

## Database Migration

### Schema Changes for PostgreSQL

1. **String Types**: `nvarchar` → `varchar` (PostgreSQL doesn't distinguish)
2. **Identity Columns**: Use `serial` or `ValueGeneratedOnAdd()`
3. **Case Sensitivity**: PostgreSQL is case-sensitive by default
4. **Boolean Type**: `bit` → `boolean`

### Connection String

**Old (SQL Server):**
```
Server=(localdb)\MSSQLLocalDB;Initial Catalog=BookStoreClassic;Integrated Security=SSPI;
```

**New (PostgreSQL):**
```
Host=localhost;Port=5432;Database=bookstore;Username=postgres;Password=postgres;
```

### Data Migration

The original seed data has been preserved and migrated to the new `BookstoreDbInitializer.SeedAsync()` method.

## Linux Compatibility

All changes ensure Linux compatibility:

1. **Path Handling**: Uses `Path.Combine()` throughout
2. **File System**: No Windows-specific paths or drives
3. **Libraries**: 
   - Magick.NET works on Linux
   - AWS SDK is cross-platform
   - PostgreSQL driver is native to Linux

4. **Removed Windows Dependencies**:
   - System.Web
   - System.Configuration
   - Windows-specific OWIN components

## Testing Checklist

- [x] Domain layer compiles without errors
- [x] Data layer compiles without errors
- [x] Web layer compiles without errors
- [x] Solution file created
- [x] Database context uses PostgreSQL
- [x] All repositories updated for EF Core
- [x] Controllers updated for ASP.NET Core
- [x] Static files moved to wwwroot
- [x] Configuration migrated to appsettings.json
- [x] Authentication updated
- [x] Dependency injection configured
- [x] Dockerfile created for Linux deployment
- [x] docker-compose.yml created for testing

## Build and Verification

To build the transformed application:

```bash
cd xform-code
dotnet restore
dotnet build
```

To run with Docker:

```bash
docker-compose up -d
```

## Known Issues and Considerations

1. **Local Authentication**: Simplified for development. For production, configure AWS Cognito.

2. **Image Paths**: Updated to use `/images/` instead of `/Content/Images/`. Existing database records may need path updates.

3. **Bundling/Minification**: The original used `System.Web.Optimization`. Consider using:
   - WebOptimizer NuGet package
   - Client-side bundlers (Webpack, Vite)
   - Built-in ASP.NET Core bundling

4. **Session State**: ASP.NET Core uses distributed cache for sessions. For production, consider:
   - Redis
   - SQL Server distributed cache
   - In-memory cache (development only)

5. **AWS Integration**: All AWS SDK packages are compatible with .NET 8.0 and Linux.

## Performance Considerations

.NET 8.0 offers significant performance improvements over .NET Framework 4.8:
- 3-5x faster startup time
- 2-3x better throughput for web requests
- Lower memory usage
- Better garbage collection

PostgreSQL vs SQL Server:
- PostgreSQL generally performs better for read-heavy workloads
- Better concurrency handling
- No licensing costs

## Deployment Options

### 1. Docker Container (Linux)
```bash
docker build -t bookstore:latest .
docker run -p 8080:8080 bookstore:latest
```

### 2. AWS ECS with Fargate (Linux)
- Use the provided Dockerfile
- Deploy to Linux containers
- Connect to RDS for PostgreSQL

### 3. Azure App Service (Linux)
- Deploy as .NET 8.0 application
- Use Azure Database for PostgreSQL

### 4. Kubernetes
- Use the Dockerfile
- Deploy with Helm charts
- Scale horizontally

## Rollback Plan

If issues occur:
1. Keep the original .NET Framework 4.8 code running
2. Run new .NET 8.0 version in parallel
3. Use feature flags to gradually migrate traffic
4. Full database backup before migration

## Next Steps

1. **Testing**: Comprehensive testing of all features
2. **Performance Testing**: Load testing and benchmarking
3. **Security Review**: Authentication and authorization flows
4. **Documentation**: Update end-user documentation
5. **Training**: Team training on .NET 8.0 and ASP.NET Core
6. **Monitoring**: Set up monitoring and logging in production

## Conclusion

The migration from .NET Framework 4.8 to .NET 8.0 has been completed successfully with all business logic preserved. The application is now:
- Cross-platform (Linux compatible)
- Modern and maintainable
- Better performing
- Cost-effective (PostgreSQL + Linux containers)
- Future-proof with long-term support
