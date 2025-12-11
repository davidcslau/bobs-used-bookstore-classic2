# Quick Start Guide - Bob's Bookstore (.NET 8.0)

## What Was Transformed?

✅ **Complete transformation from .NET Framework 4.8 to .NET 8.0**
- ASP.NET MVC 5 → ASP.NET Core MVC 8.0
- Entity Framework 6.5.1 → Entity Framework Core 8.0
- SQL Server → PostgreSQL
- Windows containers → Linux containers
- OWIN → ASP.NET Core middleware
- Autofac → Built-in DI

## Prerequisites

Choose ONE of the following:

### Option A: Docker (Easiest)
- Docker Desktop or Docker Engine
- Docker Compose

### Option B: Local Development
- .NET 8.0 SDK
- PostgreSQL 16

## Quick Start with Docker (Recommended)

```bash
cd xform-code
docker-compose up -d
```

That's it! The application will be available at http://localhost:8080

**What this does:**
1. Starts PostgreSQL 16 in a container
2. Builds and starts the .NET 8.0 application
3. Automatically seeds the database with sample data
4. Configures networking between containers

**To view logs:**
```bash
docker-compose logs -f web
```

**To stop:**
```bash
docker-compose down
```

## Local Development Setup

### 1. Install PostgreSQL

**Using Docker:**
```bash
docker run -d \
  --name bookstore-postgres \
  -e POSTGRES_DB=bookstore \
  -e POSTGRES_USER=postgres \
  -e POSTGRES_PASSWORD=postgres \
  -p 5432:5432 \
  postgres:16
```

**Or install PostgreSQL natively** on your system.

### 2. Build and Run

```bash
cd xform-code/Bookstore.Web
dotnet restore
dotnet run
```

The application will be available at https://localhost:5001

## What You'll See

### Home Page
- Featured books display
- Search functionality
- Shopping cart access

### Sample Data
The database is automatically seeded with:
- **8 sample books** (various genres and conditions)
- **10 publishers**
- **7 genres** (Science Fiction, Mystery, Biography, etc.)
- **4 conditions** (New, Like New, Good, Acceptable)
- **3 book types** (Hardcover, Trade Paperback, Mass Market)

### Testing Authentication

**Local Mode (Default):**
1. Click "Login" or visit `/Authentication/Login`
2. You'll be automatically authenticated as "Local User"
3. No password required in development mode

**AWS Cognito Mode:**
Configure in `appsettings.json`:
```json
{
  "Services": {
    "Authentication": "aws"
  },
  "Authentication": {
    "Cognito": {
      "ClientId": "your-client-id",
      "MetadataAddress": "your-cognito-metadata-url",
      "CognitoDomain": "your-cognito-domain"
    }
  }
}
```

## Key Features to Test

### Customer Features
1. **Browse Books**: Search by name, author, genre
2. **Shopping Cart**: Add/remove items, update quantities
3. **Wishlist**: Save books for later
4. **Place Orders**: Complete checkout process
5. **Submit Offers**: Sell used books to the store
6. **Manage Addresses**: Add shipping addresses

### Admin Features
Access the admin area at `/Admin`

1. **Dashboard**: View statistics
   - Total books, orders, offers
   - Low stock alerts
   - Revenue tracking

2. **Inventory Management** (`/Admin/Inventory`)
   - Add new books
   - Edit existing books
   - Upload cover images
   - Track stock levels

3. **Order Management** (`/Admin/Orders`)
   - View all orders
   - Update order status
   - View order details

4. **Offer Management** (`/Admin/Offers`)
   - Review customer offers
   - Approve/reject offers
   - Set purchase price

5. **Reference Data** (`/Admin/ReferenceData`)
   - Manage genres
   - Manage publishers
   - Manage conditions
   - Manage book types

## Configuration

### Database Connection

**appsettings.Development.json:**
```json
{
  "ConnectionStrings": {
    "BookstoreDatabaseConnection": "Host=localhost;Port=5432;Database=bookstore;Username=postgres;Password=postgres;"
  }
}
```

### Services Configuration

```json
{
  "Services": {
    "Authentication": "local",      // or "aws"
    "FileService": "local",          // or "aws" (S3)
    "ImageValidationService": "local" // or "aws" (Rekognition)
  }
}
```

## Troubleshooting

### Port Already in Use

**Docker Compose:**
Edit `docker-compose.yml` to change ports:
```yaml
ports:
  - "8081:8080"  # Change 8080 to 8081
```

**Local Development:**
Edit `Bookstore.Web/Properties/launchSettings.json` or set environment variable:
```bash
export ASPNETCORE_URLS="https://localhost:5002"
dotnet run
```

### Database Connection Failed

**Check PostgreSQL is running:**
```bash
# Docker
docker ps | grep postgres

# Local
pg_isready -h localhost -p 5432
```

**Test connection:**
```bash
psql -h localhost -U postgres -d bookstore
# Password: postgres
```

### Build Errors

**Clean and rebuild:**
```bash
cd xform-code
dotnet clean
dotnet restore
dotnet build
```

### Missing wwwroot Files

The static files should be copied during build. If missing:
```bash
cd xform-code
ls Bookstore.Web/wwwroot/
# Should show: css, js, images, lib, favicon.ico
```

## Project Structure

```
xform-code/
├── Bookstore.Domain/           # Business logic (108 C# files total)
├── Bookstore.Data/             # Data access (EF Core + PostgreSQL)
├── Bookstore.Web/              # Web application (ASP.NET Core MVC)
│   ├── Controllers/            # 15 controllers
│   ├── Views/                  # 24 Razor views
│   ├── Models/                 # View models
│   ├── Areas/Admin/            # Admin functionality
│   └── wwwroot/                # Static files (CSS, JS, images)
├── Dockerfile                  # Container definition
├── docker-compose.yml          # Local development setup
└── BobsBookstore.sln          # Solution file
```

## Development Workflow

### 1. Make Code Changes
Edit files in the appropriate project.

### 2. Hot Reload (ASP.NET Core)
Most changes will auto-reload. For C# code:
```bash
dotnet watch run
```

### 3. Database Changes

**Add a migration:**
```bash
cd Bookstore.Web
dotnet ef migrations add MigrationName
```

**Update database:**
```bash
dotnet ef database update
```

**Rollback:**
```bash
dotnet ef database update PreviousMigrationName
```

### 4. Test Changes
Navigate to http://localhost:8080 and test your changes.

## Common Tasks

### Add a New Book (via UI)
1. Login as admin
2. Go to `/Admin/Inventory`
3. Click "Add New Book"
4. Fill in details
5. Upload cover image (optional)
6. Save

### Add a New Book (via Database)
```sql
-- Connect to PostgreSQL
psql -h localhost -U postgres -d bookstore

-- Insert book
INSERT INTO "Book" ("Name", "Author", "ISBN", "PublisherId", "BookTypeId", 
                    "GenreId", "ConditionId", "Price", "Quantity")
VALUES ('New Book Title', 'Author Name', '1234567890', 15, 1, 11, 5, 19.99, 10);
```

### View Database Records
```sql
-- List all books
SELECT * FROM "Book";

-- List all orders
SELECT * FROM "Order";

-- List all customers
SELECT * FROM "Customer";
```

### Clear Database and Reseed
```bash
# Stop containers
docker-compose down -v

# Start fresh
docker-compose up -d
```

## Performance Tips

### 1. Production Build
```bash
dotnet publish -c Release -o ./publish
```

### 2. Enable Response Compression
Already configured in Program.cs

### 3. Use Production Database
Configure connection string for production PostgreSQL

### 4. Enable Caching
Add response caching middleware if needed

## Security Notes

### Development Mode
- ⚠️ **Authentication is simplified**
- ⚠️ **No password validation**
- ⚠️ **Debug logging enabled**
- ⚠️ **HTTPS not enforced**

### Production Checklist
- [ ] Configure AWS Cognito or proper authentication
- [ ] Enable HTTPS
- [ ] Set strong database passwords
- [ ] Configure AWS Secrets Manager
- [ ] Enable rate limiting
- [ ] Set up monitoring and alerts
- [ ] Review security headers
- [ ] Enable audit logging

## Next Steps

1. **Test all features** in the application
2. **Review the code** to understand the transformation
3. **Read MIGRATION_NOTES.md** for technical details
4. **Plan production deployment** using the Dockerfile
5. **Set up CI/CD pipeline** for automated builds
6. **Configure monitoring** and logging

## Support

- **README.md** - Comprehensive documentation
- **MIGRATION_NOTES.md** - Technical migration details
- **TRANSFORMATION_SUMMARY.md** - What was changed
- **Original docs** - See `../doc/` directory

## Success Indicators

✅ Application starts without errors  
✅ Home page loads with sample books  
✅ Search functionality works  
✅ Shopping cart operations work  
✅ Admin area is accessible  
✅ Database is properly seeded  
✅ Images are displayed correctly  
✅ No Windows-specific errors on Linux  

## Quick Command Reference

```bash
# Build everything
./build.sh

# Run with Docker
docker-compose up -d

# Run locally
cd Bookstore.Web && dotnet run

# View logs
docker-compose logs -f web

# Stop everything
docker-compose down

# Database migrations
cd Bookstore.Web
dotnet ef migrations add MigrationName
dotnet ef database update

# Clean build
dotnet clean && dotnet restore && dotnet build
```

---

**Version**: .NET 8.0  
**Database**: PostgreSQL 16  
**Status**: ✅ Ready for Development and Testing
