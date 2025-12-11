# Bob's Used Bookstore - Testing Environment

## Overview

This directory contains all the necessary artifacts for deploying and validating the Bob's Used Bookstore .NET 8.0 application in a testing environment on Linux with AWS services integration.

## Service Configuration

The testing environment uses a hybrid configuration:

| Service | Provider | Description |
|---------|----------|-------------|
| **Authentication** | Local | Cookie-based authentication for simplified testing |
| **Database** | AWS RDS | PostgreSQL database on Amazon RDS |
| **File Service** | AWS S3 | File storage and retrieval via Amazon S3 |
| **Image Validation** | Local | Basic image format and size validation |
| **Logging** | AWS CloudWatch | Centralized logging to AWS CloudWatch |

## Directory Structure

```
deployment/testing/
├── config/
│   ├── .env.template              # Environment variables template
│   └── appsettings.Testing.json   # Application settings for testing
├── migrations/
│   ├── 001_initial_schema.sql     # Database schema creation
│   └── 002_seed_reference_data.sql # Reference data and sample books
├── scripts/
│   ├── deploy.sh                  # Main deployment script
│   ├── migrate-db.sh              # Database migration script
│   └── validate.sh                # Deployment validation script
├── docs/
│   ├── DEPLOYMENT_GUIDE.md        # Complete deployment instructions
│   ├── CONFIGURATION_GUIDE.md     # Service configuration details
│   ├── TROUBLESHOOTING_GUIDE.md   # Common issues and solutions
│   └── TESTING_CHECKLIST.md       # Comprehensive testing checklist
├── docker-compose.testing.yml     # Docker Compose orchestration
└── README.md                      # This file
```

## Quick Start

### Prerequisites

1. **Docker and Docker Compose** installed
2. **AWS Resources** provisioned:
   - RDS PostgreSQL instance
   - S3 bucket for file storage
   - CloudWatch log group
   - IAM credentials with appropriate permissions
3. **Network Access** to AWS resources

### Deployment Steps

1. **Configure Environment:**
   ```bash
   cd /path/to/bobs-used-bookstore-classic2/xform-code/deployment/testing
   cp config/.env.template config/.env
   nano config/.env  # Edit with your AWS and database credentials
   ```

2. **Run Database Migrations:**
   ```bash
   ./scripts/migrate-db.sh
   ```

3. **Deploy Application:**
   ```bash
   ./scripts/deploy.sh
   ```

4. **Validate Deployment:**
   ```bash
   ./scripts/validate.sh
   ```

5. **Access Application:**
   - URL: http://localhost:8080
   - Admin: http://localhost:8080/Admin

## Configuration

### Required Environment Variables

Copy from `.env.template` and configure:

```bash
# Database (AWS RDS)
DB_HOST=your-rds-instance.region.rds.amazonaws.com
DB_PORT=5432
DB_NAME=bookstore
DB_USER=bookstore_user
DB_PASSWORD=your-secure-password

# AWS Credentials
AWS_REGION=us-east-1
AWS_ACCESS_KEY_ID=your-access-key
AWS_SECRET_ACCESS_KEY=your-secret-key

# S3 Configuration
Files__BucketName=bookstore-files-bucket
Files__CloudFrontDomain=your-cloudfront-domain.cloudfront.net

# Service Configuration
Services__Authentication=local
Services__Database=aws
Services__FileService=aws
Services__ImageValidationService=local
Services__LoggingService=aws
```

## Scripts

### deploy.sh
Main deployment script that:
- Validates environment configuration
- Builds Docker image
- Runs database migrations
- Starts application with Docker Compose
- Verifies deployment

**Usage:**
```bash
./scripts/deploy.sh
```

### migrate-db.sh
Database migration script that:
- Tests database connectivity
- Creates database schema
- Seeds reference data
- Loads sample books
- Verifies table creation

**Usage:**
```bash
./scripts/migrate-db.sh
```

### validate.sh
Comprehensive validation script that tests:
- Container health
- Application endpoints
- Database connectivity
- Service configurations
- AWS service integration
- Log analysis

**Usage:**
```bash
./scripts/validate.sh
```

## Database Migrations

### Schema Migration (001_initial_schema.sql)
Creates all required tables:
- Customer
- Address
- Book
- Order and OrderItem
- ShoppingCart and ShoppingCartItem
- Offer
- Wishlist
- ReferenceData

### Data Seeding (002_seed_reference_data.sql)
Seeds initial data:
- Book types (Hardcover, Paperback, etc.)
- Conditions (New, Like New, Good, Acceptable)
- Genres (Fiction, Mystery, Science Fiction, etc.)
- Publishers
- Sample books for testing

## Testing

### Manual Testing
Follow the comprehensive testing checklist in `docs/TESTING_CHECKLIST.md`

### Automated Validation
```bash
./scripts/validate.sh
```

### Key Test Areas
1. ✅ Application startup and health
2. ✅ Database connectivity and migrations
3. ✅ User registration and authentication
4. ✅ Book search and browsing
5. ✅ Shopping cart and checkout
6. ✅ File upload to S3
7. ✅ Image validation
8. ✅ CloudWatch logging
9. ✅ Order management
10. ✅ Admin functionality

## Monitoring

### Application Logs
```bash
# Follow container logs
docker logs -f bookstore-web-testing

# View recent errors
docker logs bookstore-web-testing 2>&1 | grep -i error
```

### CloudWatch Logs
```bash
# Tail CloudWatch logs
aws logs tail /aws/bookstore/testing --follow

# Query for errors
aws logs filter-log-events \
  --log-group-name /aws/bookstore/testing \
  --filter-pattern "ERROR"
```

### Container Stats
```bash
docker stats bookstore-web-testing
```

## Common Operations

### View Running Containers
```bash
docker ps | grep bookstore
```

### Restart Application
```bash
cd deployment/testing
docker-compose -f docker-compose.testing.yml restart
```

### Stop Application
```bash
docker-compose -f docker-compose.testing.yml down
```

### Rebuild and Restart
```bash
# Navigate to project root
cd ../../
docker build -t bookstore-web:testing -f Dockerfile .

# Restart
cd deployment/testing
docker-compose -f docker-compose.testing.yml up -d
```

### Access Container Shell
```bash
docker exec -it bookstore-web-testing /bin/bash
```

### View Environment Variables
```bash
docker exec bookstore-web-testing printenv | grep -E "Services__|ConnectionStrings__"
```

## Troubleshooting

### Container Won't Start
```bash
# Check logs
docker logs bookstore-web-testing

# Check if port is in use
netstat -tuln | grep 8080

# Verify configuration
docker-compose -f docker-compose.testing.yml config
```

### Database Connection Issues
```bash
# Test connection
psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME

# Check security group
aws ec2 describe-security-groups --group-ids sg-xxxxx
```

### S3 Access Issues
```bash
# Test S3 access
aws s3 ls s3://bookstore-files-bucket

# Test upload
echo "test" > test.txt
aws s3 cp test.txt s3://bookstore-files-bucket/test/
```

### CloudWatch Logging Issues
```bash
# Check log group
aws logs describe-log-groups --log-group-name-prefix /aws/bookstore

# Verify IAM permissions
aws sts get-caller-identity
```

For detailed troubleshooting, see `docs/TROUBLESHOOTING_GUIDE.md`

## Security Considerations

1. **Never commit `.env` files** to version control
2. **Use strong passwords** for database
3. **Rotate AWS credentials** regularly
4. **Enable encryption** for RDS and S3
5. **Use IAM roles** when deploying to EC2
6. **Restrict security groups** to necessary IPs only
7. **Enable CloudTrail** for AWS API auditing
8. **Use AWS Secrets Manager** for production credentials

## Performance Tips

1. **Database Connection Pooling**: Configured in connection string
2. **CloudFront CDN**: Use for static assets and S3 files
3. **RDS Read Replicas**: For read-heavy workloads
4. **Container Resources**: Adjust in docker-compose.yml
5. **Database Indexes**: Already created in migration scripts

## Backup and Recovery

### Database Backup
```bash
# Create backup
pg_dump -h $DB_HOST -U $DB_USER -d $DB_NAME -F c -f backup.dump

# Restore backup
pg_restore -h $DB_HOST -U $DB_USER -d $DB_NAME -c backup.dump
```

### S3 Backup
```bash
# Sync S3 bucket locally
aws s3 sync s3://bookstore-files-bucket ./s3-backup/
```

## Documentation

- **[Deployment Guide](docs/DEPLOYMENT_GUIDE.md)**: Complete deployment instructions
- **[Configuration Guide](docs/CONFIGURATION_GUIDE.md)**: Detailed configuration options
- **[Troubleshooting Guide](docs/TROUBLESHOOTING_GUIDE.md)**: Common issues and solutions
- **[Testing Checklist](docs/TESTING_CHECKLIST.md)**: Comprehensive testing guide

## Architecture

```
┌─────────────────┐
│  User Browser   │
└────────┬────────┘
         │
         ▼
┌─────────────────┐     ┌──────────────────┐
│  Docker         │────▶│  AWS RDS         │
│  Container      │     │  PostgreSQL      │
│  (App Server)   │     └──────────────────┘
└────────┬────────┘
         │
         ├─────────────▶┌──────────────────┐
         │              │  AWS S3          │
         │              │  (File Storage)  │
         │              └──────────────────┘
         │
         └─────────────▶┌──────────────────┐
                        │  AWS CloudWatch  │
                        │  (Logging)       │
                        └──────────────────┘
```

## Support

For issues or questions:
1. Check the troubleshooting guide
2. Review application logs
3. Verify AWS service status
4. Check configuration settings

## Version Information

- **.NET**: 8.0
- **PostgreSQL**: 14+
- **Docker**: 20.10+
- **Docker Compose**: 2.0+

## License

See the main project LICENSE file.

## Contributing

See the main project CONTRIBUTING.md file.
