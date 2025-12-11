# Bob's Used Bookstore - .NET 8.0 Transformation

This directory contains the transformed codebase migrated from .NET Framework 4.8 to .NET 8.0.

## Transformation Summary

### Platform Migration
- **From**: .NET Framework 4.8 on Windows Server with IIS
- **To**: .NET 8.0 on Linux with Kestrel web server

### Database Migration
- **From**: SQL Server with Entity Framework 6.x
- **To**: PostgreSQL with Entity Framework Core 8.0

### Key Changes

#### 1. Project Structure
All five projects have been converted to SDK-style format:
- `Bookstore.Common` - Utilities (net8.0)
- `Bookstore.Domain` - Business logic layer (net8.0)
- `Bookstore.Data` - Data access layer with EF Core (net8.0)
- `Bookstore.Web` - ASP.NET Core 8.0 MVC web application (net8.0)
- `Bookstore.Cdk` - Infrastructure as code (net8.0)

#### 2. Web Application Changes
- Converted from ASP.NET MVC 5 to ASP.NET Core 8.0 MVC
- Replaced `Global.asax.cs` and OWIN `Startup.cs` with modern `Program.cs`
- Converted `Web.config` to `appsettings.json` and `appsettings.{Environment}.json`
- Replaced Autofac with built-in ASP.NET Core dependency injection
- Updated authentication from OWIN to ASP.NET Core authentication middleware

#### 3. Entity Framework Migration
- Migrated from Entity Framework 6.x to Entity Framework Core 8.0
- Updated `ApplicationDbContext` to use `DbContextOptions<ApplicationDbContext>`
- Converted fluent API:
  - `HasRequired` → `HasOne`
  - `WillCascadeOnDelete` → `OnDelete(DeleteBehavior.Restrict)`
  - `HasIndex` remains similar
- Updated database initializer from `DropCreateDatabaseIfModelChanges` to static seeding method

#### 4. Database Provider Changes
- Changed from SQL Server to PostgreSQL
- Connection string format updated for Npgsql
- Column types updated (e.g., `nvarchar` → `varchar` for PostgreSQL)

#### 5. Service Updates
- **FileService**: Updated paths from `Content/` to `wwwroot/` structure
- **ImageResizeService**: Cross-platform compatible (Magick.NET already supported)
- **LocalAuthenticationMiddleware**: Converted from OWIN middleware to ASP.NET Core middleware

#### 6. Configuration Updates
- Created `appsettings.json` for base configuration
- Created `appsettings.Development.json` for local development
- Created `appsettings.Testing.json` with the required testing environment configuration:
  - Authentication: local
  - Database: aws (PostgreSQL on RDS)
  - FileService: aws (S3)
  - ImageValidationService: local
  - LoggingService: aws (CloudWatch)

#### 7. Logging
- Configured NLog for ASP.NET Core
- Added support for console, file, and AWS CloudWatch logging targets

## Building and Running

### Prerequisites
- .NET 8.0 SDK
- PostgreSQL 15+ (or use Docker Compose)
- Docker (optional, for containerized deployment)

### Local Development

1. **Using Docker Compose** (Recommended):
```bash
docker-compose up -d
```
The application will be available at http://localhost:8080

2. **Using .NET CLI** (requires PostgreSQL installed):
```bash
# Update connection string in appsettings.Development.json
cd app/Bookstore.Web
dotnet run
```

### Building the Docker Image
```bash
docker build -t bookstore:net8 .
```

### Running the Container
```bash
docker run -d -p 8080:80 \
  -e ConnectionStrings__BookstoreDatabaseConnection="Host=your-postgres-host;Database=BookStoreClassic;Username=postgres;Password=yourpassword" \
  bookstore:net8
```

## Testing Environment Configuration

The testing environment is configured with the following service mix:

| Service | Provider | Rationale |
|---------|----------|-----------|
| Authentication | Local | Simplified testing without Cognito dependency |
| Database | AWS RDS PostgreSQL | Matches production database for realistic testing |
| File Service | AWS S3 | Tests cloud file operations and CDN integration |
| Image Validation | Local | Reduces costs during testing cycles |
| Logging | AWS CloudWatch | Aggregates logs from test environment |

Environment variables needed for testing:
```bash
DB_HOST=your-rds-endpoint.rds.amazonaws.com
DB_PORT=5432
DB_NAME=BookStoreClassic
DB_USER=your-db-user
DB_PASSWORD=your-db-password
S3_BUCKET_NAME=your-s3-bucket
CLOUDFRONT_DOMAIN=your-cloudfront-domain.cloudfront.net
```

## Project References

### NuGet Packages (Key Changes)
- **Entity Framework**: `EntityFramework 6.5.1` → `Microsoft.EntityFrameworkCore 8.0.0`
- **PostgreSQL Provider**: Added `Npgsql.EntityFrameworkCore.PostgreSQL 8.0.0`
- **AWS SDK**: Updated to latest .NET 8 compatible versions
- **Authentication**: `Microsoft.Owin.Security.OpenIdConnect` → `Microsoft.AspNetCore.Authentication.OpenIdConnect 8.0.0`
- **Logging**: `NLog 5.4.0` → `NLog.Web.AspNetCore 5.3.0`

## Migration Notes

### Breaking Changes Handled
1. **System.Web namespace**: Removed, replaced with ASP.NET Core equivalents
2. **OWIN middleware**: Converted to ASP.NET Core middleware
3. **HttpContext access**: Updated to use `IHttpContextAccessor`
4. **File uploads**: Ready for `IFormFile` (interfaces use `Stream`)
5. **Configuration access**: Uses `IConfiguration` instead of `ConfigurationManager`

### Cross-Platform Considerations
- All file paths use `Path.Combine` for cross-platform compatibility
- Static file serving from `wwwroot` instead of `Content`
- Environment variables preferred over app settings for deployment

### Known Limitations
- Views and Controllers may need additional updates for full ASP.NET Core compatibility
- Some view helpers may need to be recreated or updated
- Bundle and minification may need to be reconfigured

## Next Steps for Full Migration

1. **Database Migration**: 
   - Export data from SQL Server
   - Import into PostgreSQL
   - Verify data integrity

2. **View Updates**:
   - Update any remaining HTML helpers
   - Update bundle references in layouts
   - Test all views for compatibility

3. **Testing**:
   - Unit test all repositories
   - Integration test all services
   - End-to-end testing of user workflows

4. **Performance Testing**:
   - Load testing on .NET 8
   - Compare with .NET Framework baseline
   - Optimize as needed

5. **Deployment**:
   - Set up ECS Fargate infrastructure
   - Configure Application Load Balancer
   - Set up CI/CD pipeline
   - Deploy to testing environment
   - Production deployment with blue-green strategy

## Support and Documentation

For detailed documentation about the original system, see the `/doc` directory in the repository root.

For questions or issues, refer to:
- `/doc/migration-analysis/` - Detailed migration strategy
- `/doc/tech_steering.json` - Comprehensive technology documentation
- Original code in `/app` directory for reference
