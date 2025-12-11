# Bob's Used Bookstore - Configuration Guide

## Service Configuration Overview

The application supports a flexible service configuration that allows mixing local and AWS services. The testing environment is configured with:

| Service | Provider | Purpose |
|---------|----------|---------|
| Authentication | Local | Cookie-based authentication |
| Database | AWS | PostgreSQL on RDS |
| File Service | AWS | S3 for file storage |
| Image Validation | Local | Basic image format validation |
| Logging | AWS | CloudWatch for centralized logging |

## Configuration Files

### 1. Environment Variables (.env)

Location: `deployment/testing/config/.env`

This is the primary configuration file for the testing environment.

#### Database Configuration
```bash
# AWS RDS PostgreSQL Instance
DB_HOST=your-rds-instance.region.rds.amazonaws.com
DB_PORT=5432
DB_NAME=bookstore
DB_USER=bookstore_user
DB_PASSWORD=your-secure-password
```

**Best Practices:**
- Use a dedicated database user with minimal required permissions
- Use strong passwords (20+ characters, mixed case, numbers, symbols)
- Enable SSL connections for production

#### AWS Configuration
```bash
AWS_REGION=us-east-1
AWS_ACCESS_KEY_ID=your-access-key-id
AWS_SECRET_ACCESS_KEY=your-secret-access-key
```

**Best Practices:**
- Use IAM roles when deploying to EC2
- Create a dedicated IAM user with minimal permissions
- Never commit credentials to version control
- Rotate credentials regularly

#### Service Toggles
```bash
Services__Authentication=local
Services__Database=aws
Services__FileService=aws
Services__ImageValidationService=local
Services__LoggingService=aws
```

**Available Values:**
- `local`: Use local implementation
- `aws`: Use AWS service implementation

### 2. Application Settings (appsettings.Testing.json)

Location: `deployment/testing/config/appsettings.Testing.json`

This file provides default configurations that can be overridden by environment variables.

```json
{
  "Services": {
    "Authentication": "local",
    "Database": "aws",
    "FileService": "aws",
    "ImageValidationService": "local",
    "LoggingService": "aws"
  }
}
```

### 3. Docker Compose Configuration

Location: `deployment/testing/docker-compose.testing.yml`

Orchestrates the application container and manages networking.

## Service-Specific Configuration

### Authentication Service

#### Local Authentication (Current Configuration)

**Configuration:**
```bash
Services__Authentication=local
```

**Features:**
- Cookie-based session management
- Forms-based login
- Local user registration
- Password stored as hash in database

**Endpoints:**
- Login: `/Authentication/Login`
- Register: `/Authentication/Register`
- Logout: `/Authentication/Logout`

**User Management:**
Users are stored in the `Customer` table with the `Sub` field containing a GUID identifier.

#### AWS Cognito Authentication (Alternative)

To switch to AWS Cognito:

1. Update service configuration:
   ```bash
   Services__Authentication=aws
   ```

2. Configure Cognito settings:
   ```bash
   Authentication__Cognito__ClientId=your-client-id
   Authentication__Cognito__MetadataAddress=https://cognito-idp.region.amazonaws.com/poolId/.well-known/openid-configuration
   Authentication__Cognito__CognitoDomain=https://your-domain.auth.region.amazoncognito.com
   ```

### Database Service

#### AWS RDS PostgreSQL (Current Configuration)

**Configuration:**
```bash
Services__Database=aws
ConnectionStrings__BookstoreDatabaseConnection=Host=${DB_HOST};Port=${DB_PORT};Database=${DB_NAME};Username=${DB_USER};Password=${DB_PASSWORD};
```

**Connection String Format:**
```
Host=hostname;Port=5432;Database=dbname;Username=user;Password=pass;
```

**Optional Parameters:**
- `SSL Mode=Require` - Enforce SSL connections
- `Timeout=30` - Connection timeout in seconds
- `Command Timeout=60` - Command timeout in seconds
- `Pooling=true` - Enable connection pooling
- `Minimum Pool Size=0` - Minimum pool size
- `Maximum Pool Size=100` - Maximum pool size

**RDS Configuration Recommendations:**
- Instance Type: db.t3.medium or larger for testing
- Storage: 20GB GP3 minimum
- Backup: Enable automated backups
- Multi-AZ: Optional for testing, recommended for production
- Encryption: Enable encryption at rest

#### Local PostgreSQL (Alternative)

To use local PostgreSQL:

1. Uncomment the postgres service in docker-compose.testing.yml
2. Update connection string:
   ```bash
   ConnectionStrings__BookstoreDatabaseConnection=Host=postgres-local;Port=5432;Database=bookstore;Username=postgres;Password=postgres;
   ```

### File Service

#### AWS S3 (Current Configuration)

**Configuration:**
```bash
Services__FileService=aws
Files__BucketName=bookstore-files-bucket
Files__CloudFrontDomain=your-cloudfront-domain.cloudfront.net
```

**S3 Bucket Setup:**

1. Create S3 bucket:
   ```bash
   aws s3 mb s3://bookstore-files-bucket --region us-east-1
   ```

2. Configure bucket policy:
   ```json
   {
     "Version": "2012-10-17",
     "Statement": [
       {
         "Effect": "Allow",
         "Principal": {
           "AWS": "arn:aws:iam::ACCOUNT_ID:user/bookstore-app"
         },
         "Action": [
           "s3:PutObject",
           "s3:GetObject",
           "s3:DeleteObject"
         ],
         "Resource": "arn:aws:s3:::bookstore-files-bucket/*"
       }
     ]
   }
   ```

3. Enable versioning (optional):
   ```bash
   aws s3api put-bucket-versioning \
     --bucket bookstore-files-bucket \
     --versioning-configuration Status=Enabled
   ```

**CloudFront Setup (Optional but Recommended):**

1. Create CloudFront distribution
2. Set origin to S3 bucket
3. Update `Files__CloudFrontDomain` with distribution domain

**File Structure in S3:**
```
bookstore-files-bucket/
├── book-covers/
│   ├── original/
│   └── thumbnails/
├── offer-images/
│   ├── original/
│   └── thumbnails/
└── user-uploads/
```

#### Local File Service (Alternative)

To use local file storage:

1. Update configuration:
   ```bash
   Services__FileService=local
   ```

2. Files will be stored in: `/app/wwwroot/uploads/`

### Image Validation Service

#### Local Validation (Current Configuration)

**Configuration:**
```bash
Services__ImageValidationService=local
```

**Features:**
- Basic image format validation (JPEG, PNG, GIF)
- File size checks
- Image dimension validation
- No inappropriate content detection

**Validation Rules:**
- Max file size: 5MB
- Allowed formats: JPEG, PNG, GIF
- Max dimensions: 4096x4096 pixels

#### AWS Rekognition (Alternative)

To enable AWS Rekognition for content moderation:

1. Update configuration:
   ```bash
   Services__ImageValidationService=aws
   ```

2. Ensure IAM permissions include:
   ```json
   {
     "Effect": "Allow",
     "Action": [
       "rekognition:DetectModerationLabels"
     ],
     "Resource": "*"
   }
   ```

**Features with Rekognition:**
- Inappropriate content detection
- Violence detection
- Explicit content detection
- Confidence scoring

### Logging Service

#### AWS CloudWatch (Current Configuration)

**Configuration:**
```bash
Services__LoggingService=aws
Logging__CloudWatch__LogGroup=/aws/bookstore/testing
Logging__CloudWatch__Region=us-east-1
```

**CloudWatch Setup:**

1. Create log group:
   ```bash
   aws logs create-log-group --log-group-name /aws/bookstore/testing
   ```

2. Set retention policy:
   ```bash
   aws logs put-retention-policy \
     --log-group-name /aws/bookstore/testing \
     --retention-in-days 30
   ```

**IAM Permissions Required:**
```json
{
  "Effect": "Allow",
  "Action": [
    "logs:CreateLogGroup",
    "logs:CreateLogStream",
    "logs:PutLogEvents",
    "logs:DescribeLogStreams"
  ],
  "Resource": "arn:aws:logs:*:*:log-group:/aws/bookstore/testing:*"
}
```

**Log Levels:**
```json
{
  "Logging": {
    "LogLevel": {
      "Default": "Information",
      "Microsoft.AspNetCore": "Warning",
      "Microsoft.EntityFrameworkCore": "Information"
    }
  }
}
```

**Viewing Logs:**
```bash
# Tail logs
aws logs tail /aws/bookstore/testing --follow

# Filter for errors
aws logs filter-log-events \
  --log-group-name /aws/bookstore/testing \
  --filter-pattern "ERROR"
```

#### Local Logging (Alternative)

To use local file logging:

1. Configure NLog (already set up in nlog.config)
2. Logs will be written to: `/app/logs/`

## Environment-Specific Configurations

### Development
- All services: `local`
- Database: Local PostgreSQL
- No AWS credentials required

### Testing (Current)
- Authentication: `local`
- Database: `aws` (RDS)
- FileService: `aws` (S3)
- ImageValidation: `local`
- Logging: `aws` (CloudWatch)

### Production (Recommended)
- All services: `aws`
- Enhanced security
- Multi-AZ deployment
- CloudFront CDN
- WAF protection

## Configuration Validation

Run the validation script to verify configuration:

```bash
./scripts/validate.sh
```

This checks:
- Environment variables are set
- AWS credentials are valid
- Database is accessible
- S3 bucket exists
- CloudWatch log group exists

## Configuration Priority

Configuration values are loaded in this order (later overrides earlier):

1. appsettings.json
2. appsettings.{Environment}.json
3. Environment variables
4. Docker Compose environment section
5. .env file

**Example:**
If `ConnectionStrings__BookstoreDatabaseConnection` is set in both appsettings.json and .env, the .env value will be used.

## Security Best Practices

### 1. Environment Variables
- Never commit .env files
- Use different credentials for each environment
- Rotate credentials regularly

### 2. AWS Credentials
- Use IAM roles when possible
- Follow principle of least privilege
- Enable MFA for IAM users
- Use AWS Secrets Manager for production

### 3. Database
- Use SSL/TLS connections
- Restrict network access via security groups
- Use strong passwords
- Enable audit logging

### 4. S3
- Enable bucket encryption
- Use bucket policies to restrict access
- Enable versioning for important data
- Configure lifecycle policies

### 5. Application
- Keep dependencies updated
- Use HTTPS in production
- Implement rate limiting
- Enable CORS appropriately

## Troubleshooting Configuration Issues

### Issue: Application can't connect to RDS

**Check:**
1. Security group allows inbound on port 5432
2. RDS instance is publicly accessible (if needed)
3. Connection string is correct
4. Credentials are valid

### Issue: S3 operations fail

**Check:**
1. IAM permissions are correct
2. Bucket exists and is in the correct region
3. Bucket name is correct in configuration
4. AWS credentials are valid

### Issue: CloudWatch logs not appearing

**Check:**
1. IAM permissions include `logs:CreateLogStream` and `logs:PutLogEvents`
2. Log group exists
3. Region is correct
4. AWS credentials are valid

### Issue: Service configuration not taking effect

**Check:**
1. Environment variables are set correctly
2. Application has been restarted after config change
3. Docker Compose was reloaded
4. Check container environment: `docker exec bookstore-web-testing printenv`

## Advanced Configuration

### Custom Connection Pooling
```bash
ConnectionStrings__BookstoreDatabaseConnection=Host=${DB_HOST};Port=${DB_PORT};Database=${DB_NAME};Username=${DB_USER};Password=${DB_PASSWORD};Pooling=true;Minimum Pool Size=5;Maximum Pool Size=100;
```

### SSL Database Connection
```bash
ConnectionStrings__BookstoreDatabaseConnection=Host=${DB_HOST};Port=${DB_PORT};Database=${DB_NAME};Username=${DB_USER};Password=${DB_PASSWORD};SSL Mode=Require;Trust Server Certificate=true;
```

### Custom Log Retention
```json
{
  "Logging": {
    "CloudWatch": {
      "LogGroup": "/aws/bookstore/testing",
      "RetentionInDays": 30
    }
  }
}
```

### S3 Server-Side Encryption
Configure S3 client to use encryption (handled automatically by AWS SDK).

## Configuration Templates

Complete configuration templates are provided in:
- `config/.env.template` - Environment variables template
- `config/appsettings.Testing.json` - Application settings template
