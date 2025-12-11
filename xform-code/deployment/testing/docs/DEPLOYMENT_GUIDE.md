# Bob's Used Bookstore - Testing Environment Deployment Guide

## Overview

This guide provides step-by-step instructions for deploying the Bob's Used Bookstore .NET 8.0 application to the testing environment with the following service configuration:

- **Authentication**: Local (Cookie-based)
- **Database**: AWS (PostgreSQL on RDS)
- **File Service**: AWS (S3)
- **Image Validation**: Local
- **Logging**: AWS (CloudWatch)

## Prerequisites

### Required Software
- Docker (version 20.10 or later)
- Docker Compose (version 2.0 or later)
- PostgreSQL client (optional, for database verification)
- AWS CLI (optional, for AWS resource management)

### AWS Resources Required
1. **RDS PostgreSQL Instance**
   - PostgreSQL 14 or later
   - Publicly accessible or accessible from deployment environment
   - Security group configured to allow connections

2. **S3 Bucket**
   - For file storage
   - Optional: CloudFront distribution for CDN

3. **CloudWatch Log Group**
   - Log group: `/aws/bookstore/testing`

4. **IAM Credentials**
   - Access Key ID and Secret Access Key
   - Permissions required:
     - S3: `s3:PutObject`, `s3:GetObject`, `s3:DeleteObject`
     - CloudWatch: `logs:CreateLogStream`, `logs:PutLogEvents`

## Deployment Steps

### Step 1: Prepare Environment Configuration

1. Navigate to the deployment directory:
   ```bash
   cd /path/to/bobs-used-bookstore-classic2/xform-code/deployment/testing
   ```

2. Copy the environment template:
   ```bash
   cp config/.env.template config/.env
   ```

3. Edit the `.env` file with your configuration:
   ```bash
   nano config/.env  # or use your preferred editor
   ```

4. Configure the following critical settings:

   **Database Configuration:**
   ```bash
   DB_HOST=your-rds-instance.region.rds.amazonaws.com
   DB_PORT=5432
   DB_NAME=bookstore
   DB_USER=bookstore_user
   DB_PASSWORD=your-secure-password
   ```

   **AWS Configuration:**
   ```bash
   AWS_REGION=us-east-1
   AWS_ACCESS_KEY_ID=your-access-key-id
   AWS_SECRET_ACCESS_KEY=your-secret-access-key
   ```

   **S3 Configuration:**
   ```bash
   Files__BucketName=bookstore-files-bucket
   Files__CloudFrontDomain=your-cloudfront-domain.cloudfront.net
   ```

### Step 2: Verify AWS Resources

1. **Verify RDS Instance:**
   ```bash
   aws rds describe-db-instances --db-instance-identifier your-instance-name
   ```

2. **Verify S3 Bucket:**
   ```bash
   aws s3 ls s3://bookstore-files-bucket
   ```

3. **Test Database Connection:**
   ```bash
   psql -h your-rds-instance.region.rds.amazonaws.com -p 5432 -U bookstore_user -d bookstore -c "SELECT 1;"
   ```

### Step 3: Run Database Migrations

Execute the database migration script:

```bash
./scripts/migrate-db.sh
```

This script will:
- Create all required database tables
- Set up relationships and indexes
- Seed reference data (book types, conditions, genres, publishers)
- Load sample books

**Verify Migration:**
```bash
psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -c "\dt"
```

You should see tables: Address, Book, Customer, Offer, Order, OrderItem, ReferenceData, ShoppingCart, ShoppingCartItem, Wishlist

### Step 4: Build and Deploy Application

Run the deployment script:

```bash
./scripts/deploy.sh
```

This script will:
1. Validate environment configuration
2. Build the Docker image
3. Prompt for database migration (if not already run)
4. Start the application using Docker Compose
5. Verify the deployment

**Manual Deployment (Alternative):**

```bash
# Build Docker image
cd ../../  # Navigate to project root
docker build -t bookstore-web:testing -f Dockerfile .

# Start with Docker Compose
cd deployment/testing
docker-compose -f docker-compose.testing.yml --env-file config/.env up -d
```

### Step 5: Verify Deployment

Run the validation script:

```bash
./scripts/validate.sh
```

This will test:
- Container health
- Application endpoints
- Database connectivity
- Service configurations
- AWS service connectivity
- Log analysis

### Step 6: Access the Application

The application should now be available at:
- **URL**: http://localhost:8080
- **Admin Area**: http://localhost:8080/Admin

## Post-Deployment Tasks

### 1. Create Test Users

Since we're using local authentication, users can register through the application:
1. Navigate to http://localhost:8080/Authentication/Register
2. Create test accounts

### 2. Upload Test Images

Test the S3 file service:
1. Log in to the application
2. Navigate to the Resale section
3. Submit a book offer with an image
4. Verify the image is stored in S3

### 3. Monitor Logs

**View application logs:**
```bash
docker logs -f bookstore-web-testing
```

**View CloudWatch logs:**
```bash
aws logs tail /aws/bookstore/testing --follow
```

### 4. Test Key Features

- **Search**: Search for books by title, author, or ISBN
- **Shopping Cart**: Add books to cart and proceed to checkout
- **Orders**: Place and view orders
- **Wishlist**: Add books to wishlist
- **Resale**: Submit book resale offers
- **Admin Area**: Manage books, orders, and offers

## Troubleshooting

### Container Won't Start

1. **Check container logs:**
   ```bash
   docker logs bookstore-web-testing
   ```

2. **Verify environment variables:**
   ```bash
   docker exec bookstore-web-testing printenv | grep Services__
   ```

3. **Check container status:**
   ```bash
   docker ps -a | grep bookstore
   ```

### Database Connection Issues

1. **Verify RDS security group:**
   - Ensure your IP/CIDR is allowed on port 5432

2. **Test connection manually:**
   ```bash
   psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME
   ```

3. **Check connection string in container:**
   ```bash
   docker exec bookstore-web-testing printenv | grep ConnectionStrings
   ```

### AWS Service Issues

1. **Verify IAM permissions:**
   ```bash
   aws sts get-caller-identity
   ```

2. **Test S3 access:**
   ```bash
   aws s3 ls s3://bookstore-files-bucket
   ```

3. **Check CloudWatch logs:**
   ```bash
   aws logs describe-log-streams --log-group-name /aws/bookstore/testing
   ```

### Application Errors

1. **Check application logs for exceptions:**
   ```bash
   docker logs bookstore-web-testing 2>&1 | grep -i "exception\|error"
   ```

2. **Verify service configurations:**
   - Ensure Services__* environment variables are set correctly

3. **Test endpoints manually:**
   ```bash
   curl -v http://localhost:8080/
   curl -v http://localhost:8080/Search
   ```

## Updating the Application

To update the application after code changes:

```bash
# Rebuild the Docker image
cd ../../
docker build -t bookstore-web:testing -f Dockerfile .

# Restart the container
cd deployment/testing
docker-compose -f docker-compose.testing.yml restart
```

## Stopping the Application

```bash
cd deployment/testing
docker-compose -f docker-compose.testing.yml down
```

To also remove volumes:
```bash
docker-compose -f docker-compose.testing.yml down -v
```

## Backup and Restore

### Database Backup
```bash
pg_dump -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -F c -f bookstore_backup.dump
```

### Database Restore
```bash
pg_restore -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -c bookstore_backup.dump
```

### S3 Backup
```bash
aws s3 sync s3://bookstore-files-bucket ./backup-files/
```

## Security Considerations

1. **Never commit `.env` files to version control**
2. **Use IAM roles when deploying to EC2 instead of access keys**
3. **Enable encryption at rest for RDS**
4. **Use S3 bucket encryption**
5. **Implement CloudFront signed URLs for sensitive content**
6. **Rotate AWS credentials regularly**
7. **Use AWS Secrets Manager for production credentials**

## Monitoring

### Key Metrics to Monitor

1. **Application Health:**
   - HTTP response times
   - Error rates
   - Request counts

2. **Database:**
   - Connection count
   - Query performance
   - Storage usage

3. **AWS Services:**
   - S3 request counts
   - CloudWatch log volume
   - Lambda execution (if using Rekognition)

### Setting Up Alarms

```bash
# Example: Create CloudWatch alarm for application errors
aws cloudwatch put-metric-alarm \
  --alarm-name bookstore-testing-errors \
  --alarm-description "Alert when error rate is high" \
  --metric-name ErrorCount \
  --namespace BookstoreApp \
  --statistic Sum \
  --period 300 \
  --evaluation-periods 2 \
  --threshold 10 \
  --comparison-operator GreaterThanThreshold
```

## Additional Resources

- [Configuration Guide](./CONFIGURATION_GUIDE.md)
- [Troubleshooting Guide](./TROUBLESHOOTING_GUIDE.md)
- [Testing Checklist](./TESTING_CHECKLIST.md)
- [AWS Best Practices](https://docs.aws.amazon.com/wellarchitected/latest/framework/welcome.html)

## Support

For issues or questions:
1. Check the troubleshooting guide
2. Review application logs
3. Check AWS service status
4. Consult the .NET 8.0 documentation
