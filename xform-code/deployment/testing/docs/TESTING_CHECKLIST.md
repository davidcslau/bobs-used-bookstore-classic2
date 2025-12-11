# Bob's Used Bookstore - Testing Checklist

## Pre-Deployment Verification

### AWS Resources
- [ ] RDS PostgreSQL instance is running and accessible
- [ ] RDS security group allows inbound connections on port 5432
- [ ] S3 bucket exists and is accessible
- [ ] IAM user/role has required permissions
- [ ] CloudWatch log group exists
- [ ] AWS credentials are valid and configured

### Environment Configuration
- [ ] `.env` file created from template
- [ ] Database connection string configured correctly
- [ ] AWS credentials set in environment
- [ ] S3 bucket name configured
- [ ] Service configurations set as required
- [ ] All required environment variables are set

### Local Environment
- [ ] Docker is installed and running
- [ ] Docker Compose is available
- [ ] Port 8080 is available
- [ ] PostgreSQL client installed (optional but recommended)
- [ ] Sufficient disk space for Docker images

## Deployment Validation

### Container Health
- [ ] Container starts successfully
- [ ] Container status is "running"
- [ ] No restart loops detected
- [ ] Container health check passes
- [ ] No critical errors in container logs

### Database
- [ ] Database migrations completed successfully
- [ ] All tables created correctly
- [ ] Reference data seeded
- [ ] Sample books loaded
- [ ] Database indexes created
- [ ] Foreign key constraints working
- [ ] Application can connect to database
- [ ] Connection pooling working

### Application Startup
- [ ] Application starts without errors
- [ ] Homepage loads successfully (http://localhost:8080)
- [ ] Static files serve correctly (CSS, JS, images)
- [ ] No startup exceptions in logs
- [ ] NLog configuration working
- [ ] Entity Framework initialization successful

## Functional Testing

### 1. Homepage and Navigation
- [ ] Homepage loads and displays correctly
- [ ] Navigation menu works
- [ ] Logo and branding visible
- [ ] Footer displays correctly
- [ ] Search bar is present
- [ ] No broken links on homepage
- [ ] Responsive design works (mobile, tablet, desktop)

### 2. Search Functionality
- [ ] Basic search by title works
- [ ] Search by author works
- [ ] Search by ISBN works
- [ ] Search results display correctly
- [ ] Pagination works
- [ ] Filtering by genre works
- [ ] Filtering by condition works
- [ ] Filtering by book type works
- [ ] No results message displays correctly
- [ ] Search handles special characters

### 3. Authentication (Local)
- [ ] Registration page loads
- [ ] Can register new user
- [ ] Validation works on registration form
- [ ] Login page loads
- [ ] Can login with valid credentials
- [ ] Login fails with invalid credentials
- [ ] Logout works correctly
- [ ] Session persistence works
- [ ] Cookie authentication working
- [ ] Protected routes require login

**Test User Creation:**
```
Username: test@bookstore.com
Password: Test123!
First Name: Test
Last Name: User
```

### 4. Book Browsing
- [ ] Book list displays correctly
- [ ] Book details page loads
- [ ] Book images display (from database seed)
- [ ] Book information is accurate
- [ ] Price displays correctly
- [ ] Quantity on hand shows
- [ ] Related book information displays
- [ ] Book type, genre, condition display
- [ ] Publisher information shows

### 5. Shopping Cart
- [ ] Can add book to cart
- [ ] Cart icon shows item count
- [ ] Cart page displays items
- [ ] Can update quantities
- [ ] Can remove items
- [ ] Subtotal calculates correctly
- [ ] Cart persists across pages
- [ ] Cart clears after logout (if applicable)
- [ ] Multiple items in cart work
- [ ] Quantity validation works

### 6. Checkout Process
- [ ] Checkout page loads
- [ ] Shipping address form works
- [ ] Billing address form works
- [ ] Address validation works
- [ ] Can use same address for billing/shipping
- [ ] Order summary displays correctly
- [ ] Total calculation is accurate
- [ ] Can complete checkout
- [ ] Order is saved to database
- [ ] Cart clears after order

### 7. Order Management
- [ ] Order history page loads
- [ ] Past orders display correctly
- [ ] Order details page loads
- [ ] Order items display correctly
- [ ] Order status displays
- [ ] Order date and total display
- [ ] Can view order details
- [ ] Address information displays

### 8. Wishlist
- [ ] Can add book to wishlist
- [ ] Wishlist page loads
- [ ] Wishlist items display
- [ ] Can remove from wishlist
- [ ] Can add wishlist item to cart
- [ ] Wishlist persists across sessions

### 9. Address Management
- [ ] Address list page loads
- [ ] Can add new address
- [ ] Address validation works
- [ ] Can edit existing address
- [ ] Can delete address
- [ ] Can set default address
- [ ] Addresses display in checkout

### 10. Resale/Offer System
- [ ] Resale page loads
- [ ] Offer submission form works
- [ ] Can select book details (genre, publisher, etc.)
- [ ] Image upload works **(Tests AWS S3)**
- [ ] Form validation works
- [ ] Can submit offer
- [ ] Offer saves to database
- [ ] My offers page displays submitted offers
- [ ] Offer status displays

**Image Upload Test:**
- [ ] Upload JPEG image (should succeed)
- [ ] Upload PNG image (should succeed)
- [ ] Upload invalid file type (should fail with local validation)
- [ ] Upload oversized image (should fail)
- [ ] Verify image stored in S3 bucket
- [ ] Verify image URL accessible

### 11. Admin Area
- [ ] Admin dashboard loads
- [ ] Requires authentication
- [ ] Dashboard shows statistics
- [ ] Books management page loads
- [ ] Can view all books
- [ ] Can add new book
- [ ] Can edit book
- [ ] Can delete book (if permitted)
- [ ] Orders management works
- [ ] Can view all orders
- [ ] Can update order status
- [ ] Offers management works
- [ ] Can view all offers
- [ ] Can approve/reject offers

## Service-Specific Testing

### AWS S3 File Service
- [ ] Image uploads go to S3
- [ ] Can retrieve images from S3
- [ ] CloudFront URL works (if configured)
- [ ] Image URLs are accessible
- [ ] File permissions are correct
- [ ] Verify in S3 console that files exist

**Manual Verification:**
```bash
aws s3 ls s3://bookstore-files-bucket/ --recursive
```

### Local Image Validation Service
- [ ] Image format validation works
- [ ] Rejects invalid image types
- [ ] Size validation works
- [ ] Dimension validation works
- [ ] Error messages are clear

### AWS CloudWatch Logging
- [ ] Logs appear in CloudWatch
- [ ] Log streams created correctly
- [ ] Log format is correct
- [ ] Error logs capture exceptions
- [ ] Info logs capture normal operations
- [ ] Can query logs in CloudWatch

**Manual Verification:**
```bash
aws logs tail /aws/bookstore/testing --follow
```

### PostgreSQL Database (AWS RDS)
- [ ] Connection is stable
- [ ] Queries execute correctly
- [ ] No connection timeout issues
- [ ] Connection pooling works
- [ ] SSL connection working (if configured)
- [ ] Query performance is acceptable

## Performance Testing

### Response Times
- [ ] Homepage loads in < 2 seconds
- [ ] Search results in < 3 seconds
- [ ] Product details in < 2 seconds
- [ ] Checkout completes in < 5 seconds
- [ ] Image uploads in < 10 seconds

### Concurrent Users
- [ ] Test with 10 concurrent users
- [ ] Test with 50 concurrent users
- [ ] No errors under load
- [ ] Response times remain acceptable
- [ ] Database connections handled correctly

**Load Testing Script:**
```bash
# Using Apache Bench
ab -n 1000 -c 10 http://localhost:8080/

# Using curl in loop
for i in {1..100}; do
  curl -s http://localhost:8080/ > /dev/null &
done
wait
```

### Resource Usage
- [ ] Memory usage stable over time
- [ ] CPU usage reasonable
- [ ] No memory leaks detected
- [ ] Database connections released
- [ ] File handles not accumulating

## Security Testing

### Authentication
- [ ] Cannot access protected routes without login
- [ ] Session expires appropriately
- [ ] Password requirements enforced
- [ ] SQL injection prevented
- [ ] XSS attacks prevented
- [ ] CSRF tokens working

### Authorization
- [ ] Admin area requires admin role
- [ ] Users can only see their own orders
- [ ] Users can only edit their own data
- [ ] Cannot delete other users' data

### Data Validation
- [ ] All forms validate input
- [ ] SQL injection attempts blocked
- [ ] File upload restrictions work
- [ ] Email format validation
- [ ] Phone number validation
- [ ] Price validation (no negative prices)

### Network Security
- [ ] Database connection uses credentials
- [ ] AWS credentials not exposed
- [ ] No sensitive data in logs
- [ ] Error messages don't reveal system info

## Integration Testing

### Database Integration
- [ ] CRUD operations work correctly
- [ ] Transactions work properly
- [ ] Concurrent updates handled
- [ ] Referential integrity maintained
- [ ] Cascade deletes work correctly

### AWS Services Integration
- [ ] S3 upload/download works
- [ ] CloudWatch logging works
- [ ] Error handling for AWS failures
- [ ] Retry logic works
- [ ] Timeout handling appropriate

## Error Handling

### Application Errors
- [ ] 404 page displays for invalid routes
- [ ] 500 errors logged properly
- [ ] Friendly error messages shown to users
- [ ] Detailed errors in logs
- [ ] Error boundary catches exceptions

### Database Errors
- [ ] Connection failures handled gracefully
- [ ] Timeout errors handled
- [ ] Constraint violations show user-friendly messages
- [ ] Transaction rollback works

### AWS Service Errors
- [ ] S3 upload failures handled
- [ ] CloudWatch logging failures don't crash app
- [ ] Fallback mechanisms work
- [ ] Error messages are informative

## Monitoring and Logging

### Application Logs
- [ ] Info logs for normal operations
- [ ] Error logs for exceptions
- [ ] Warn logs for recoverable issues
- [ ] Debug logs available if needed
- [ ] Logs include context (user, timestamp, etc.)

### CloudWatch Integration
- [ ] Logs streaming to CloudWatch
- [ ] Log groups organized correctly
- [ ] Can query logs effectively
- [ ] Retention policy set correctly

### Metrics
- [ ] Request count tracking
- [ ] Error rate tracking
- [ ] Response time tracking
- [ ] Database query performance

## Backup and Recovery

### Database Backup
- [ ] RDS automated backups enabled
- [ ] Can create manual snapshot
- [ ] Snapshot restoration tested
- [ ] Point-in-time recovery available

### Application Recovery
- [ ] Container can restart successfully
- [ ] Data integrity after restart
- [ ] Sessions handle gracefully
- [ ] No data loss on restart

## Documentation Verification

- [ ] Deployment guide is accurate
- [ ] Configuration guide is complete
- [ ] Troubleshooting guide is helpful
- [ ] README is up to date
- [ ] Environment variables documented
- [ ] API endpoints documented (if applicable)

## Final Checks

### Before Going to Production
- [ ] All tests passed
- [ ] No critical errors in logs
- [ ] Performance acceptable
- [ ] Security review completed
- [ ] Backup strategy in place
- [ ] Monitoring configured
- [ ] Alerting configured
- [ ] Documentation complete
- [ ] Team trained on operations
- [ ] Rollback plan documented

### Sign-off
- [ ] Development team approval
- [ ] QA team approval
- [ ] Operations team approval
- [ ] Security team approval
- [ ] Product owner approval

## Testing Summary Template

```
Date: _______________
Tester: _______________
Version: _______________

Tests Passed: _____ / _____
Tests Failed: _____
Critical Issues: _____
Warnings: _____

Status: [ ] PASS [ ] FAIL [ ] CONDITIONAL PASS

Issues Found:
1. _______________________________
2. _______________________________
3. _______________________________

Notes:
_______________________________
_______________________________
_______________________________

Approved by: _______________
Date: _______________
```

## Automated Testing Script

Save this as `run-tests.sh`:

```bash
#!/bin/bash

echo "Running Testing Checklist..."
echo "============================"

PASSED=0
FAILED=0

# Test 1: Container Running
if docker ps | grep -q bookstore-web-testing; then
  echo "✓ Container is running"
  ((PASSED++))
else
  echo "✗ Container is not running"
  ((FAILED++))
fi

# Test 2: Homepage Accessible
if curl -s http://localhost:8080 > /dev/null; then
  echo "✓ Homepage is accessible"
  ((PASSED++))
else
  echo "✗ Homepage is not accessible"
  ((FAILED++))
fi

# Test 3: Search Endpoint
if curl -s http://localhost:8080/Search | grep -q "search"; then
  echo "✓ Search endpoint works"
  ((PASSED++))
else
  echo "✗ Search endpoint failed"
  ((FAILED++))
fi

# Add more tests...

echo ""
echo "============================"
echo "Passed: $PASSED"
echo "Failed: $FAILED"
echo "============================"
```

## Continuous Testing

For ongoing validation:

```bash
# Run every hour
0 * * * * /path/to/deployment/testing/scripts/validate.sh

# Alert on failures
0 * * * * /path/to/deployment/testing/scripts/validate.sh || echo "Validation failed!" | mail -s "Alert: Bookstore Validation Failed" admin@example.com
```
