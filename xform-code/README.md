# Bob's Used Bookstore - .NET 8.0 (Transformed)

This is the transformed version of Bob's Used Bookstore, migrated from .NET Framework 4.8 to .NET 8.0 for Linux deployment.

## Key Transformations

### Architecture Changes
- **Framework**: .NET Framework 4.8 → .NET 8.0
- **Web Framework**: ASP.NET MVC 5 → ASP.NET Core MVC 8.0
- **ORM**: Entity Framework 6.5.1 → Entity Framework Core 8.0
- **Database**: SQL Server → PostgreSQL
- **Database Provider**: System.Data.SqlClient → Npgsql.EntityFrameworkCore.PostgreSQL
- **Authentication**: OWIN → ASP.NET Core Authentication Middleware
- **Dependency Injection**: Autofac → Built-in ASP.NET Core DI
- **Configuration**: Web.config → appsettings.json + Program.cs

### Project Structure
```
xform-code/
├── Bookstore.Domain/       # Domain layer (.NET 8.0 class library)
├── Bookstore.Data/         # Data access layer (EF Core 8.0 + PostgreSQL)
├── Bookstore.Web/          # ASP.NET Core MVC web application
├── BobsBookstore.sln       # Solution file
├── Dockerfile              # Linux container definition
└── docker-compose.yml      # Docker Compose for local development
```

## Prerequisites

- .NET 8.0 SDK
- PostgreSQL 16 (or Docker)
- Docker and Docker Compose (optional, for containerized deployment)

## Running Locally

### Option 1: Using Docker Compose (Recommended)

```bash
cd xform-code
docker-compose up -d
```

The application will be available at http://localhost:8080

### Option 2: Manual Setup

1. Install PostgreSQL and create a database:
```sql
CREATE DATABASE bookstore;
```

2. Update the connection string in `appsettings.Development.json`

3. Run the application:
```bash
cd Bookstore.Web
dotnet restore
dotnet run
```

The application will be available at https://localhost:5001

## Database Migrations

The application automatically seeds the database on startup with reference data and sample books.

To create new migrations:
```bash
cd Bookstore.Web
dotnet ef migrations add MigrationName
dotnet ef database update
```

## Key Differences from Original

### Configuration
- Web.config → appsettings.json
- `ConfigurationManager.AppSettings["key"]` → `IConfiguration["key"]`

### Controllers
- `ActionResult` → `IActionResult`
- `HttpPostedFileBase` → `IFormFile`
- `System.Web.Mvc` → `Microsoft.AspNetCore.Mvc`

### Database Context
- Constructor takes `DbContextOptions<ApplicationDbContext>`
- Fluent API: `DbModelBuilder` → `ModelBuilder`
- String-based includes → Strongly-typed lambda includes
- `HasRequired()` → `HasOne()` with `OnDelete(DeleteBehavior.Restrict)`

### Static Files
- Content/Images → wwwroot/images
- Content/css → wwwroot/css
- Scripts → wwwroot/js

### Authentication
- OWIN middleware → ASP.NET Core authentication middleware
- Cookie authentication for local development
- OpenID Connect for AWS Cognito integration

## Linux Compatibility

All code is Linux-compatible:
- No Windows-specific APIs
- Path handling uses `Path.Combine()` for cross-platform compatibility
- ImageMagick (Magick.NET) works on Linux
- AWS SDK is cross-platform

## Testing

### Local Authentication
The application uses a simplified local authentication for development:
- Navigate to `/Authentication/Login` to authenticate
- No password required in local mode
- For production, configure AWS Cognito in appsettings.json

### Database Seeding
On first run, the application seeds:
- 4 Book Types (Hardcover, Trade Paperback, Mass Market Paperback)
- 4 Conditions (New, Like New, Good, Acceptable)
- 7 Genres
- 10 Publishers
- 8 Sample Books

## Deployment

### Docker
```bash
docker build -t bookstore:latest .
docker run -p 8080:8080 \
  -e ConnectionStrings__BookstoreDatabaseConnection="Host=postgres-host;Port=5432;Database=bookstore;Username=user;Password=pass" \
  bookstore:latest
```

### AWS ECS with Fargate (Linux)
Update the ECS task definition to use the Linux container:
- Base image: `mcr.microsoft.com/dotnet/aspnet:8.0`
- Platform: Linux/AMD64
- Database: RDS for PostgreSQL

## Environment Variables

Key environment variables:
- `ConnectionStrings__BookstoreDatabaseConnection`: PostgreSQL connection string
- `Services__Authentication`: `local` or `aws`
- `Services__FileService`: `local` or `aws`
- `Services__ImageValidationService`: `local` or `aws`
- `Authentication__Cognito__ClientId`: AWS Cognito client ID (if using AWS)
- `Authentication__Cognito__MetadataAddress`: Cognito metadata endpoint
- `Files__BucketName`: S3 bucket name (if using AWS)

## Known Limitations

1. Local authentication is simplified for development only
2. Image uploads are stored locally by default (use S3 for production)
3. No email service integration (preserved from original)

## Support

For issues or questions, refer to the original documentation in the `doc/` directory of the parent repository.
