# External Service Dependencies

## AWS Services

### 1. Amazon S3
- **Purpose**: File storage for book cover images
- **SDK**: AWSSDK.S3 v3.7.416.5
- **Operations**: PutObject, GetObject, DeleteObject
- **Configuration**: Bucket name, CloudFront domain from Parameter Store

### 2. Amazon Rekognition
- **Purpose**: Image content moderation
- **SDK**: AWSSDK.Rekognition v3.7.400.129
- **Operations**: DetectModerationLabels
- **Configuration**: IAM role with appropriate permissions

### 3. Amazon CloudWatch Logs
- **Purpose**: Centralized logging
- **SDK**: AWSSDK.CloudWatchLogs v3.7.410.17
- **Operations**: PutLogEvents, CreateLogStream
- **Configuration**: Log group name

### 4. AWS Systems Manager Parameter Store
- **Purpose**: Configuration and secrets management
- **SDK**: AWSSDK.SimpleSystemsManagement v3.7.404.10
- **Operations**: GetParameter, GetParametersByPath
- **Parameters Stored**:
  - Connection strings
  - Cognito configuration
  - S3 bucket names
  - CloudFront domains

### 5. Amazon Cognito
- **Purpose**: User authentication
- **Protocol**: OpenID Connect
- **Configuration**: User pool, app clients, hosted UI

## Third-Party NuGet Packages

### Core
- EntityFramework 6.5.1
- Autofac 8.2.1
- Newtonsoft.Json 13.0.3
- NLog 5.4.0

### Microsoft
- Microsoft.AspNet.Mvc 5.3.0
- Microsoft.Owin 4.2.2
- Microsoft.IdentityModel.* 8.7.0

### Client-Side
- jQuery 3.7.1
- Bootstrap 5.x
- jQuery.Validation 1.21.0

## Service Availability Requirements

- **AWS Services**: Internet connectivity required
- **Database**: SQL Server (LocalDB dev, RDS prod)
- **CDN**: CloudFront for image delivery

## Fallback Strategies

- **File Service**: Automatic fallback to local storage if AWS unavailable
- **Image Validation**: Can disable by using local implementation
- **Logging**: Falls back to file logging if CloudWatch unavailable
- **Authentication**: Local mode for development

## Cost Considerations

- S3: Pay per GB stored + requests
- Rekognition: Pay per image analyzed
- CloudWatch Logs: Pay per GB ingested
- RDS: Hourly instance cost
- Cognito: Free tier available, then pay per MAU
