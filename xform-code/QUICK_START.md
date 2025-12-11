# Quick Start Guide - .NET 8.0 Bookstore Application

## Prerequisites
- Docker and Docker Compose
- .NET 8.0 SDK (for local development without Docker)
- PostgreSQL 15+ (if not using Docker)

## Quick Start with Docker Compose (Recommended)

### 1. Start Everything
```bash
cd xform-code
docker-compose up -d
```

This will:
- Start PostgreSQL database
- Build and start the .NET 8 application
- Create necessary volumes
- Configure networking

### 2. Check Status
```bash
docker-compose ps
```

### 3. View Logs
```bash
# All services
docker-compose logs -f

# Just the web app
docker-compose logs -f bookstore-web

# Just the database
docker-compose logs -f postgres
```

### 4. Access the Application
Open your browser to: http://localhost:8080

### 5. Stop Everything
```bash
docker-compose down
```

### 6. Clean Up (Remove Volumes)
```bash
docker-compose down -v
```

## Local Development (Without Docker)

### 1. Install PostgreSQL
```bash
# Ubuntu/Debian
sudo apt-get install postgresql-15

# macOS
brew install postgresql@15

# Or use Docker for just the database
docker run -d \
  --name bookstore-postgres \
  -e POSTGRES_DB=BookStoreClassic \
  -e POSTGRES_USER=postgres \
  -e POSTGRES_PASSWORD=postgres \
  -p 5432:5432 \
  postgres:15-alpine
```

### 2. Update Connection String
Edit `app/Bookstore.Web/appsettings.Development.json`:
```json
{
  "ConnectionStrings": {
    "BookstoreDatabaseConnection": "Host=localhost;Database=BookStoreClassic;Username=postgres;Password=postgres"
  }
}
```

### 3. Run the Application
```bash
cd app/Bookstore.Web
dotnet restore
dotnet run
```

### 4. Access the Application
Open your browser to: https://localhost:5001 or http://localhost:5000

## Environment-Specific Configurations

### Development (appsettings.Development.json)
- Authentication: Local (no AWS Cognito needed)
- Database: Local PostgreSQL
- File Service: Local file system
- Image Validation: Local (no AWS Rekognition)
- Logging: Console and file

### Testing (appsettings.Testing.json)
- Authentication: Local
- Database: AWS RDS PostgreSQL
- File Service: AWS S3
- Image Validation: Local
- Logging: AWS CloudWatch

Required environment variables for testing:
```bash
export DB_HOST=your-rds-endpoint.rds.amazonaws.com
export DB_NAME=BookStoreClassic
export DB_USER=your-username
export DB_PASSWORD=your-password
export S3_BUCKET_NAME=your-bucket
export CLOUDFRONT_DOMAIN=your-domain.cloudfront.net
```

### Production
Configure all services to use AWS:
```bash
export ASPNETCORE_ENVIRONMENT=Production
export AppSettings__Services/Authentication=aws
export AppSettings__Services/Database=aws
export AppSettings__Services/FileService=aws
export AppSettings__Services/ImageValidationService=aws
export AppSettings__Services/LoggingService=aws
# Plus AWS credentials and region configuration
```

## Common Tasks

### Database Operations

#### Reset Database
```bash
# Using Docker Compose
docker-compose down -v
docker-compose up -d

# Or manually
docker exec -it bookstore-postgres psql -U postgres -c "DROP DATABASE BookStoreClassic;"
docker exec -it bookstore-postgres psql -U postgres -c "CREATE DATABASE BookStoreClassic;"
```

#### Access Database
```bash
# Using Docker Compose
docker-compose exec postgres psql -U postgres -d BookStoreClassic

# Or directly
psql -h localhost -U postgres -d BookStoreClassic
```

#### View Database Tables
```sql
\dt
```

#### Check Data
```sql
SELECT * FROM "ReferenceData";
SELECT * FROM "Book";
SELECT * FROM "Customer";
```

### Building Docker Image

#### Build Locally
```bash
cd xform-code
docker build -t bookstore:net8 .
```

#### Run Built Image
```bash
docker run -d \
  --name bookstore-app \
  -p 8080:80 \
  -e ConnectionStrings__BookstoreDatabaseConnection="Host=host.docker.internal;Database=BookStoreClassic;Username=postgres;Password=postgres" \
  bookstore:net8
```

### Troubleshooting

#### Application Won't Start
1. Check logs: `docker-compose logs bookstore-web`
2. Verify database is running: `docker-compose ps postgres`
3. Check connection string in configuration
4. Ensure database is initialized

#### Database Connection Failed
1. Verify PostgreSQL is running
2. Check connection string format
3. Verify credentials
4. Check network connectivity: `docker-compose exec bookstore-web ping postgres`

#### Port Already in Use
```bash
# Find what's using the port
lsof -i :8080  # macOS/Linux
netstat -ano | findstr :8080  # Windows

# Change port in docker-compose.yml
# Change 8080:80 to 8081:80 for example
```

#### View Application Logs
```bash
# Real-time logs
docker-compose logs -f bookstore-web

# Logs in container
docker-compose exec bookstore-web tail -f /var/log/bookstore/*.log
```

## Development Workflow

### 1. Make Code Changes
Edit files in `app/` directory

### 2. Rebuild and Restart
```bash
docker-compose build bookstore-web
docker-compose up -d bookstore-web
```

### 3. Test Changes
Navigate to http://localhost:8080

### 4. View Logs for Issues
```bash
docker-compose logs -f bookstore-web
```

## Testing Features

### Local Authentication
1. Visit http://localhost:8080
2. Click on any secured page
3. You'll be automatically logged in as "bookstoreuser"

### Book Management
1. Navigate to Books section
2. Add/Edit/Delete books
3. Upload cover images
4. Search and filter

### Order Management
1. Add books to cart
2. View shopping cart
3. Place orders
4. View order history

### Offer Management
1. Create book offers (selling to store)
2. Review offers
3. Accept/Reject offers

## Performance Monitoring

### View Running Containers
```bash
docker stats
```

### Check Database Performance
```bash
docker-compose exec postgres psql -U postgres -d BookStoreClassic
```
```sql
-- Check table sizes
SELECT 
    schemaname,
    tablename,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) AS size
FROM pg_tables 
WHERE schemaname = 'public'
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;

-- Check query performance
SELECT * FROM pg_stat_statements ORDER BY total_exec_time DESC LIMIT 10;
```

## CI/CD Integration

### GitHub Actions Example
```yaml
name: Build and Test

on: [push, pull_request]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v2
    - name: Setup .NET
      uses: actions/setup-dotnet@v1
      with:
        dotnet-version: '8.0.x'
    - name: Restore
      run: dotnet restore app/Bookstore.Web
    - name: Build
      run: dotnet build app/Bookstore.Web --no-restore
    - name: Test
      run: dotnet test app/Bookstore.Web --no-build --verbosity normal
```

## Support

For detailed documentation:
- See `README.md` for comprehensive transformation details
- See `TRANSFORMATION_SUMMARY.md` for complete change list
- See `migrations/migration-notes.md` for database migration guide
- See `/doc` directory for original system documentation

## Tips

1. **Keep Docker Updated**: Ensure Docker and Docker Compose are on latest versions
2. **Use Volume Mounts for Development**: Mount source code for hot reload
3. **Environment Variables**: Use `.env` file for sensitive configuration (don't commit!)
4. **Database Backups**: Regular backups before making schema changes
5. **Log Rotation**: Configure log rotation in production
6. **Health Checks**: Monitor container health status
7. **Resource Limits**: Set memory and CPU limits in production

## Next Steps

After getting the application running:
1. Review all functionality
2. Run integration tests
3. Perform load testing
4. Security audit
5. Deploy to testing environment
6. Plan production deployment
