# Validation Checklist - .NET 8.0 Transformation

## Pre-Deployment Validation

### Build Validation
- [ ] All projects build successfully with .NET 8.0 SDK
  ```bash
  cd xform-code
  dotnet build app/Bookstore.Common/Bookstore.Common.csproj
  dotnet build app/Bookstore.Domain/Bookstore.Domain.csproj
  dotnet build app/Bookstore.Data/Bookstore.Data.csproj
  dotnet build app/Bookstore.Web/Bookstore.Web.csproj
  dotnet build app/Bookstore.Cdk/Bookstore.Cdk.csproj
  ```
- [ ] No compilation errors
- [ ] No critical warnings
- [ ] All NuGet packages restore successfully

### Docker Validation
- [ ] Dockerfile builds successfully
  ```bash
  cd xform-code
  docker build -t bookstore:net8 -f Dockerfile .
  ```
- [ ] Docker image size is reasonable (< 500MB recommended)
- [ ] Docker Compose starts all services
  ```bash
  docker-compose up -d
  docker-compose ps
  ```
- [ ] Health checks pass

### Database Validation
- [ ] PostgreSQL container starts successfully
- [ ] Database is created automatically
- [ ] Tables are created by EF Core
- [ ] Seed data is inserted correctly
- [ ] Foreign key relationships are correct
- [ ] Indexes are created properly

SQL Verification:
```sql
-- Check tables exist
\dt

-- Verify reference data
SELECT * FROM "ReferenceData";

-- Check book data
SELECT * FROM "Book";

-- Verify relationships
SELECT b.*, g."Text" as Genre, p."Text" as Publisher 
FROM "Book" b 
JOIN "ReferenceData" g ON b."GenreId" = g."Id"
JOIN "ReferenceData" p ON b."PublisherId" = p."Id";
```

## Functional Testing

### Application Startup
- [ ] Application starts without errors
- [ ] Port 80 (or 8080) is accessible
- [ ] Home page loads correctly
- [ ] Static files (CSS, JS, images) load
- [ ] No console errors in browser

### Authentication Testing
#### Local Authentication Mode
- [ ] Accessing /Authentication/Login sets authentication cookie
- [ ] User is redirected to home page after login
- [ ] User claims are set correctly
- [ ] Customer record is created in database
- [ ] Secured pages are accessible after authentication
- [ ] Logout functionality works

#### AWS Cognito Mode (if configured)
- [ ] OpenID Connect flow initiates
- [ ] Redirect to Cognito works
- [ ] Callback from Cognito succeeds
- [ ] User claims are populated
- [ ] Customer record is created/updated
- [ ] Session persists across requests

### Book Management
- [ ] Book list page loads
- [ ] Books display with cover images
- [ ] Search functionality works
- [ ] Filtering works (by genre, publisher, condition)
- [ ] Sorting works (name, price)
- [ ] Pagination works correctly
- [ ] Book detail page loads
- [ ] Add new book form works
- [ ] Edit book form works
- [ ] Delete book functionality works
- [ ] Cover image upload works
  - Local file service mode
  - AWS S3 mode (if configured)
- [ ] Image validation works
  - Local mode
  - AWS Rekognition mode (if configured)
- [ ] Image resizing works

### Shopping Cart
- [ ] Add book to cart works
- [ ] Cart persists in session
- [ ] Update quantity works
- [ ] Remove from cart works
- [ ] Cart displays correct totals
- [ ] Checkout process initiates

### Order Management
- [ ] Place order works
- [ ] Order is saved to database
- [ ] Order items are created correctly
- [ ] Inventory is reduced
- [ ] Order confirmation page displays
- [ ] Order history page loads
- [ ] Order details page shows correct information
- [ ] Customer can view only their orders

### Offer Management
- [ ] Create offer form works
- [ ] Offer is saved to database
- [ ] Offer list page loads
- [ ] Filter offers works
- [ ] View offer details works
- [ ] Accept offer works
- [ ] Reject offer works
- [ ] Offer status updates correctly

### Customer Management
- [ ] Customer profile page loads
- [ ] Edit profile works
- [ ] Customer addresses display
- [ ] Add address works
- [ ] Edit address works
- [ ] Delete address works
- [ ] Default address selection works

### Search Functionality
- [ ] Global search works
- [ ] Search by book name works
- [ ] Search by author works
- [ ] Search by ISBN works
- [ ] Search by genre works
- [ ] Search by publisher works
- [ ] Search results display correctly

### Admin Functions (if applicable)
- [ ] Admin dashboard loads
- [ ] Statistics display correctly
- [ ] Low stock alerts work
- [ ] Out of stock indicators work
- [ ] Inventory management works

## Integration Testing

### AWS Services Integration (Testing Environment)

#### Database (AWS RDS PostgreSQL)
- [ ] Connection to RDS succeeds
- [ ] Connection pooling works
- [ ] SSL connection works (if configured)
- [ ] Query performance is acceptable
- [ ] Transactions work correctly

#### File Service (AWS S3)
- [ ] S3 bucket connection succeeds
- [ ] File upload to S3 works
- [ ] File download/retrieval works
- [ ] CloudFront URLs are generated correctly
- [ ] Pre-signed URLs work (if used)
- [ ] File deletion from S3 works

#### Image Validation (Local)
- [ ] Local validation service works
- [ ] Invalid images are rejected
- [ ] Valid images are accepted
- [ ] Response time is acceptable

#### Logging (AWS CloudWatch)
- [ ] Logs are sent to CloudWatch
- [ ] Log groups are created
- [ ] Log streams are organized correctly
- [ ] Log levels are correct
- [ ] Error logs include stack traces
- [ ] Performance logs are captured

#### Authentication (Local)
- [ ] Local authentication works in testing
- [ ] User sessions persist
- [ ] Claims are set correctly
- [ ] Customer records sync properly

## Performance Testing

### Response Times
- [ ] Home page loads < 2 seconds
- [ ] Book list page loads < 3 seconds
- [ ] Search results load < 2 seconds
- [ ] Image upload completes < 5 seconds
- [ ] Order placement completes < 3 seconds

### Load Testing
- [ ] 10 concurrent users - no errors
- [ ] 50 concurrent users - acceptable performance
- [ ] 100 concurrent users - system handles load
- [ ] Database connection pool sufficient
- [ ] Memory usage stable under load
- [ ] No memory leaks detected

### Database Performance
- [ ] Query execution times acceptable
- [ ] No N+1 query issues
- [ ] Eager loading works correctly
- [ ] Indexes are being used
- [ ] Connection pooling working

## Security Testing

### Authentication & Authorization
- [ ] Unauthenticated users redirected to login
- [ ] Authenticated users can access secured pages
- [ ] Users can only access their own data
- [ ] Admin functions restricted to admin users
- [ ] Session timeout works
- [ ] CSRF protection enabled

### Input Validation
- [ ] SQL injection prevented (parameterized queries)
- [ ] XSS prevention works
- [ ] File upload restrictions work
- [ ] Max file size enforced
- [ ] Allowed file types enforced
- [ ] Malicious file content blocked

### Data Protection
- [ ] Sensitive data not logged
- [ ] Connection strings not exposed
- [ ] Error messages don't reveal internals
- [ ] Stack traces not shown to users (production)
- [ ] HTTPS enforced (if configured)
- [ ] Secure cookies used

### Dependency Scanning
- [ ] No known vulnerable packages
- [ ] All packages up to date
- [ ] License compliance checked

## Cross-Platform Testing

### Linux Compatibility
- [ ] Application runs on Linux
- [ ] File paths work correctly (forward slashes)
- [ ] Case-sensitive file system handled
- [ ] Line endings correct
- [ ] Permissions correct

### Container Testing
- [ ] Runs in Docker container
- [ ] Environment variables work
- [ ] Volume mounts work
- [ ] Network connectivity works
- [ ] Health checks respond correctly
- [ ] Graceful shutdown works

## Error Handling & Logging

### Error Scenarios
- [ ] Database connection failure handled
- [ ] S3 connection failure handled
- [ ] Invalid input handled gracefully
- [ ] 404 errors display properly
- [ ] 500 errors logged and displayed properly
- [ ] Validation errors display correctly

### Logging
- [ ] Info logs created for normal operations
- [ ] Warning logs created for recoverable issues
- [ ] Error logs created for exceptions
- [ ] Logs include correlation IDs
- [ ] Logs are structured (if using structured logging)
- [ ] Log levels configurable per environment

## Data Migration Testing

### Schema Migration
- [ ] EF Core migrations create correct schema
- [ ] All tables created
- [ ] All columns correct types
- [ ] Foreign keys created
- [ ] Indexes created
- [ ] Constraints applied

### Data Migration (if migrating existing data)
- [ ] All records migrated
- [ ] Data integrity maintained
- [ ] Relationships preserved
- [ ] No data loss
- [ ] Data types converted correctly
- [ ] Special characters handled
- [ ] Timestamps converted correctly

## Rollback Testing

### Rollback Procedures
- [ ] Rollback plan documented
- [ ] Database backup created
- [ ] Previous container image available
- [ ] Rollback tested in non-prod
- [ ] Rollback time acceptable

## Documentation Validation

### Technical Documentation
- [ ] README.md reviewed
- [ ] TRANSFORMATION_SUMMARY.md reviewed
- [ ] QUICK_START.md tested
- [ ] Migration guide reviewed
- [ ] All commands tested and work
- [ ] Environment variables documented

### Code Documentation
- [ ] Complex logic commented
- [ ] API endpoints documented
- [ ] Configuration options documented
- [ ] Database schema documented

## Sign-Off Checklist

### Development Team
- [ ] Code review completed
- [ ] All tests passing
- [ ] No known critical bugs
- [ ] Performance acceptable
- [ ] Security review completed

### QA Team
- [ ] Functional testing complete
- [ ] Integration testing complete
- [ ] Performance testing complete
- [ ] Security testing complete
- [ ] Test results documented

### DevOps Team
- [ ] Infrastructure ready
- [ ] Monitoring configured
- [ ] Alerts configured
- [ ] Backup strategy in place
- [ ] Rollback plan tested

### Product Owner
- [ ] Feature parity confirmed
- [ ] User acceptance testing complete
- [ ] Business requirements met
- [ ] Go-live approved

## Post-Deployment Monitoring

### First 24 Hours
- [ ] Monitor error rates
- [ ] Monitor response times
- [ ] Monitor database performance
- [ ] Monitor resource utilization
- [ ] Check logs for errors
- [ ] Verify backup jobs running

### First Week
- [ ] User feedback collected
- [ ] Performance trends analyzed
- [ ] Error patterns identified
- [ ] Optimization opportunities noted
- [ ] Capacity planning reviewed

## Notes

Date: _________________

Tester: _________________

Environment: _________________

Issues Found:
_____________________________________________________________
_____________________________________________________________
_____________________________________________________________

Additional Comments:
_____________________________________________________________
_____________________________________________________________
_____________________________________________________________
