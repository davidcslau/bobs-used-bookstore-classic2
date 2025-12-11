# Bob's Used Bookstore - Troubleshooting Guide

## Quick Diagnostics

Run these commands first to gather information about your deployment:

```bash
# Check container status
docker ps -a | grep bookstore

# View recent logs
docker logs --tail 100 bookstore-web-testing

# Check environment variables
docker exec bookstore-web-testing printenv | grep -E "Services__|ConnectionStrings__|AWS_"

# Run validation script
./scripts/validate.sh
```

## Common Issues and Solutions

### 1. Container Issues

#### Container Won't Start

**Symptoms:**
- Container status shows "Exited" or "Restarting"
- Application not accessible

**Diagnosis:**
```bash
# Check container status
docker ps -a | grep bookstore-web-testing

# View logs
docker logs bookstore-web-testing

# Check for port conflicts
netstat -tuln | grep 8080
```

**Solutions:**

1. **Port already in use:**
   ```bash
   # Find process using port 8080
   lsof -i :8080
   
   # Kill the process or change port in docker-compose.yml
   kill -9 <PID>
   ```

2. **Configuration error:**
   ```bash
   # Verify .env file exists and is valid
   cat deployment/testing/config/.env
   
   # Check for syntax errors in docker-compose
   docker-compose -f deployment/testing/docker-compose.testing.yml config
   ```

3. **Image build failed:**
   ```bash
   # Rebuild image with verbose output
   docker build -t bookstore-web:testing -f Dockerfile . --no-cache
   ```

#### Container Keeps Restarting

**Symptoms:**
- Container restarts continuously
- Application crashes immediately after start

**Diagnosis:**
```bash
# View detailed logs
docker logs -f bookstore-web-testing

# Check container events
docker events --filter container=bookstore-web-testing
```

**Common Causes:**

1. **Database connection failure:**
   - Check RDS security group
   - Verify connection string
   - Test database connectivity:
     ```bash
     docker exec bookstore-web-testing ping -c 3 $DB_HOST
     ```

2. **Missing environment variables:**
   ```bash
   docker exec bookstore-web-testing printenv | sort
   ```

3. **Application exception:**
   - Look for stack traces in logs
   - Check for migration errors

### 2. Database Connection Issues

#### Cannot Connect to RDS

**Symptoms:**
- "Could not connect to server" error
- Connection timeout
- Authentication failures

**Diagnosis:**
```bash
# Test from Docker container
docker exec bookstore-web-testing nc -zv $DB_HOST 5432

# Test with psql
psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME
```

**Solutions:**

1. **Security Group Configuration:**
   ```bash
   # Check security group rules
   aws ec2 describe-security-groups --group-ids sg-xxxxx
   
   # Add your IP to security group
   aws ec2 authorize-security-group-ingress \
     --group-id sg-xxxxx \
     --protocol tcp \
     --port 5432 \
     --cidr your-ip/32
   ```

2. **Public Accessibility:**
   ```bash
   # Check if RDS is publicly accessible
   aws rds describe-db-instances \
     --db-instance-identifier your-instance \
     --query 'DBInstances[0].PubliclyAccessible'
   ```

3. **Credentials:**
   ```bash
   # Verify credentials in .env
   echo $DB_USER
   echo $DB_HOST
   
   # Test with correct credentials
   PGPASSWORD=$DB_PASSWORD psql -h $DB_HOST -U $DB_USER -d $DB_NAME -c "SELECT 1"
   ```

4. **Connection String Format:**
   ```bash
   # Correct format:
   Host=hostname;Port=5432;Database=dbname;Username=user;Password=pass;
   
   # NOT this format (common mistake):
   Server=hostname;Port=5432;Database=dbname;...
   ```

#### Database Migration Errors

**Symptoms:**
- Tables not created
- "Relation does not exist" errors
- Seed data missing

**Diagnosis:**
```bash
# Check if tables exist
psql -h $DB_HOST -U $DB_USER -d $DB_NAME -c "\dt"

# Check migration logs
./scripts/migrate-db.sh
```

**Solutions:**

1. **Re-run migrations:**
   ```bash
   ./scripts/migrate-db.sh
   ```

2. **Check for conflicting data:**
   ```bash
   # Drop and recreate database (CAUTION: This deletes all data)
   psql -h $DB_HOST -U postgres -c "DROP DATABASE IF EXISTS bookstore"
   psql -h $DB_HOST -U postgres -c "CREATE DATABASE bookstore"
   ./scripts/migrate-db.sh
   ```

3. **Verify migration files:**
   ```bash
   ls -la deployment/testing/migrations/
   ```

### 3. AWS Service Issues

#### S3 Access Denied

**Symptoms:**
- File uploads fail
- "Access Denied" errors
- 403 status codes

**Diagnosis:**
```bash
# Test S3 access
aws s3 ls s3://bookstore-files-bucket

# Check IAM permissions
aws iam get-user
aws sts get-caller-identity
```

**Solutions:**

1. **Verify bucket exists:**
   ```bash
   aws s3 ls | grep bookstore-files-bucket
   ```

2. **Check IAM permissions:**
   ```json
   {
     "Effect": "Allow",
     "Action": [
       "s3:PutObject",
       "s3:GetObject",
       "s3:DeleteObject",
       "s3:ListBucket"
     ],
     "Resource": [
       "arn:aws:s3:::bookstore-files-bucket",
       "arn:aws:s3:::bookstore-files-bucket/*"
     ]
   }
   ```

3. **Test upload:**
   ```bash
   echo "test" > test.txt
   aws s3 cp test.txt s3://bookstore-files-bucket/test/
   aws s3 ls s3://bookstore-files-bucket/test/
   ```

4. **Check bucket policy:**
   ```bash
   aws s3api get-bucket-policy --bucket bookstore-files-bucket
   ```

#### CloudWatch Logging Not Working

**Symptoms:**
- Logs not appearing in CloudWatch
- "Access Denied" errors
- Log streams not created

**Diagnosis:**
```bash
# Check log group exists
aws logs describe-log-groups --log-group-name-prefix /aws/bookstore

# List log streams
aws logs describe-log-streams --log-group-name /aws/bookstore/testing

# Check IAM permissions
aws iam get-user-policy --user-name bookstore-app --policy-name CloudWatchLogs
```

**Solutions:**

1. **Create log group:**
   ```bash
   aws logs create-log-group --log-group-name /aws/bookstore/testing
   ```

2. **Verify IAM permissions:**
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

3. **Check region:**
   ```bash
   # Ensure AWS_REGION matches log group region
   echo $AWS_REGION
   aws logs describe-log-groups --region $AWS_REGION
   ```

4. **Check application logs for errors:**
   ```bash
   docker logs bookstore-web-testing 2>&1 | grep -i cloudwatch
   ```

### 4. Application Errors

#### 500 Internal Server Error

**Symptoms:**
- Pages return 500 errors
- Application crashes
- Exceptions in logs

**Diagnosis:**
```bash
# View detailed error logs
docker logs bookstore-web-testing 2>&1 | grep -A 10 "Exception"

# Check application event log
docker exec bookstore-web-testing cat /app/logs/app.log
```

**Common Causes and Solutions:**

1. **Database connection:**
   - Verify connection string
   - Check database is accessible
   - Ensure migrations have run

2. **Missing configuration:**
   ```bash
   # Check all required environment variables are set
   docker exec bookstore-web-testing printenv | grep -E "Services__|ConnectionStrings__|Files__"
   ```

3. **AWS service configuration:**
   - Verify AWS credentials
   - Check service endpoints
   - Ensure IAM permissions are correct

#### Authentication Not Working

**Symptoms:**
- Cannot log in
- Session expires immediately
- Redirect loops

**Diagnosis:**
```bash
# Check authentication configuration
docker exec bookstore-web-testing printenv | grep Services__Authentication

# View authentication-related logs
docker logs bookstore-web-testing 2>&1 | grep -i "authentication\|login"
```

**Solutions:**

1. **For local authentication:**
   ```bash
   # Verify service is set to local
   Services__Authentication=local
   
   # Check if customer table exists
   psql -h $DB_HOST -U $DB_USER -d $DB_NAME -c "SELECT COUNT(*) FROM \"Customer\""
   ```

2. **Cookie issues:**
   - Clear browser cookies
   - Check if HTTPS is required
   - Verify AllowedHosts setting

#### File Upload Failures

**Symptoms:**
- Upload errors
- Files not appearing in S3
- Timeout errors

**Diagnosis:**
```bash
# Check S3 service configuration
docker exec bookstore-web-testing printenv | grep Files__

# Test S3 connectivity from container
docker exec bookstore-web-testing aws s3 ls s3://bookstore-files-bucket

# Check for size limit errors
docker logs bookstore-web-testing 2>&1 | grep -i "upload\|file"
```

**Solutions:**

1. **Increase upload size limit:**
   Add to appsettings.json:
   ```json
   {
     "Kestrel": {
       "Limits": {
         "MaxRequestBodySize": 52428800
       }
     }
   }
   ```

2. **Check S3 permissions:**
   ```bash
   aws s3api put-object --bucket bookstore-files-bucket --key test/test.txt --body test.txt
   ```

3. **Verify bucket configuration:**
   ```bash
   echo $Files__BucketName
   aws s3 ls s3://$Files__BucketName
   ```

### 5. Performance Issues

#### Slow Response Times

**Symptoms:**
- Pages load slowly
- Database queries timeout
- High CPU/memory usage

**Diagnosis:**
```bash
# Check container resources
docker stats bookstore-web-testing --no-stream

# Check database connections
psql -h $DB_HOST -U $DB_USER -d $DB_NAME -c "SELECT count(*) FROM pg_stat_activity"

# Monitor logs for slow queries
docker logs -f bookstore-web-testing | grep -i "slow\|timeout"
```

**Solutions:**

1. **Database connection pooling:**
   Update connection string:
   ```
   ...;Pooling=true;Minimum Pool Size=5;Maximum Pool Size=100;
   ```

2. **Increase container resources:**
   Add to docker-compose.yml:
   ```yaml
   deploy:
     resources:
       limits:
         cpus: '2'
         memory: 2G
   ```

3. **Database indexes:**
   ```sql
   -- Check for missing indexes
   SELECT * FROM pg_stat_user_tables WHERE idx_scan = 0;
   ```

4. **Enable query logging:**
   ```json
   {
     "Logging": {
       "LogLevel": {
         "Microsoft.EntityFrameworkCore.Database.Command": "Information"
       }
     }
   }
   ```

#### Memory Leaks

**Symptoms:**
- Memory usage grows over time
- Container eventually crashes
- Out of memory errors

**Diagnosis:**
```bash
# Monitor memory over time
watch -n 5 'docker stats bookstore-web-testing --no-stream'

# Check for memory leaks in logs
docker logs bookstore-web-testing 2>&1 | grep -i "memory\|leak"
```

**Solutions:**

1. **Set memory limits:**
   ```yaml
   deploy:
     resources:
       limits:
         memory: 2G
   ```

2. **Restart container periodically:**
   ```bash
   docker restart bookstore-web-testing
   ```

3. **Check for unclosed connections:**
   - Review code for DbContext disposal
   - Ensure HttpClient is reused
   - Check for file handles not being closed

### 6. Network Issues

#### Cannot Access Application

**Symptoms:**
- Connection refused
- Timeout errors
- Port not accessible

**Diagnosis:**
```bash
# Check if container is listening
docker exec bookstore-web-testing netstat -tuln | grep 8080

# Check port mapping
docker port bookstore-web-testing

# Test locally
curl http://localhost:8080
```

**Solutions:**

1. **Check firewall:**
   ```bash
   # Allow port 8080
   sudo ufw allow 8080
   ```

2. **Verify ASPNETCORE_URLS:**
   ```bash
   docker exec bookstore-web-testing printenv | grep ASPNETCORE_URLS
   # Should be: http://+:8080
   ```

3. **Check Docker networking:**
   ```bash
   docker network ls
   docker network inspect bookstore-network
   ```

## Debugging Tips

### Enable Detailed Logging

1. Update appsettings.Testing.json:
   ```json
   {
     "Logging": {
       "LogLevel": {
         "Default": "Debug",
         "Microsoft.AspNetCore": "Debug",
         "Microsoft.EntityFrameworkCore": "Debug"
       }
     }
   }
   ```

2. Restart container:
   ```bash
   docker restart bookstore-web-testing
   ```

### Interactive Shell Access

```bash
# Access container shell
docker exec -it bookstore-web-testing /bin/bash

# Install debugging tools
apt-get update && apt-get install -y curl netcat-openbsd postgresql-client

# Test connectivity
curl http://localhost:8080
nc -zv $DB_HOST 5432
psql -h $DB_HOST -U $DB_USER -d $DB_NAME
```

### View All Environment Variables

```bash
docker exec bookstore-web-testing printenv | sort
```

### Check Application Health

```bash
# Application endpoints
curl -v http://localhost:8080/
curl -v http://localhost:8080/Search
curl -v http://localhost:8080/Authentication/Login

# Check response headers
curl -I http://localhost:8080/
```

## Getting Help

### Information to Gather

When seeking help, provide:

1. **Container logs:**
   ```bash
   docker logs bookstore-web-testing > container-logs.txt
   ```

2. **Container status:**
   ```bash
   docker ps -a | grep bookstore
   ```

3. **Environment configuration:**
   ```bash
   docker exec bookstore-web-testing printenv | grep -E "Services__|ConnectionStrings__" > config.txt
   ```

4. **Validation results:**
   ```bash
   ./scripts/validate.sh > validation-results.txt 2>&1
   ```

5. **Docker Compose config:**
   ```bash
   docker-compose -f deployment/testing/docker-compose.testing.yml config > compose-config.txt
   ```

### Log Collection Script

```bash
#!/bin/bash
# collect-logs.sh

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
LOG_DIR="troubleshooting_logs_$TIMESTAMP"

mkdir -p $LOG_DIR

echo "Collecting logs..."

docker logs bookstore-web-testing > $LOG_DIR/container-logs.txt 2>&1
docker ps -a > $LOG_DIR/container-status.txt
docker exec bookstore-web-testing printenv > $LOG_DIR/environment.txt 2>&1
docker stats bookstore-web-testing --no-stream > $LOG_DIR/stats.txt
./scripts/validate.sh > $LOG_DIR/validation.txt 2>&1

echo "Logs collected in: $LOG_DIR"
tar -czf $LOG_DIR.tar.gz $LOG_DIR
echo "Archive created: $LOG_DIR.tar.gz"
```

## Prevention Best Practices

1. **Always validate configuration before deployment**
2. **Test database connectivity before starting application**
3. **Use validation script after each deployment**
4. **Monitor CloudWatch logs regularly**
5. **Set up CloudWatch alarms for critical errors**
6. **Keep detailed deployment notes**
7. **Document any configuration changes**
8. **Regular backups of database**
9. **Test disaster recovery procedures**
10. **Review logs daily during initial deployment**
