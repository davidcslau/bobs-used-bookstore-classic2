# Hosting Migration: IIS/Windows to Kestrel/Linux

## Current State: IIS on Windows

- Internet Information Services (IIS) 10+
- Windows Server 2016+
- In-process hosting model (System.Web)
- Windows-specific paths and APIs

## Target State: Kestrel on Linux

- Kestrel web server (built into ASP.NET Core)
- Linux (Ubuntu, Amazon Linux, Alpine)
- Self-hosted or containerized (Docker)
- Reverse proxy (Nginx or AWS ALB)

## Key Differences

### Web Server
**IIS**:
- Windows-only
- Requires Windows Server license
- Managed through IIS Manager GUI
- Application pools
- web.config for configuration

**Kestrel**:
- Cross-platform
- Lightweight, fast
- Configured in code
- Typically behind reverse proxy
- appsettings.json for configuration

### Hosting Model
**IIS (System.Web)**:
- In-process hosting
- HttpContext from System.Web
- Global.asax lifecycle
- Application domains

**Kestrel (ASP.NET Core)**:
- Self-hosted process
- Microsoft.AspNetCore.Http
- Program.cs entry point
- Cross-platform

### Path Handling
**Windows**:
- Backslashes: `C:\path\to\file`
- Case-insensitive file system
- Drive letters

**Linux**:
- Forward slashes: `/path/to/file`
- Case-sensitive file system
- No drive letters, root is /

## Code Changes Required

### 1. Path Construction
**Windows-specific**:
```csharp
var path = Path.Combine("C:\\app\\content", filename);
```

**Cross-platform**:
```csharp
var path = Path.Combine(contentPath, filename);
// Use Path.GetFullPath() for absolute paths
```

### 2. Environment Variables
**Windows**:
- Registry settings
- Windows-specific env vars

**Linux**:
- Environment variables
- /etc/environment or systemd

### 3. File Permissions
**Windows**: NTFS permissions
**Linux**: chmod/chown, user/group permissions

### 4. Line Endings
**Windows**: CRLF (\r\n)
**Linux**: LF (\n)

Use `.gitattributes` to ensure consistent line endings.

## Docker Containerization

### Dockerfile for .NET 8

```dockerfile
# Build stage
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src
COPY ["Bookstore.Web/Bookstore.Web.csproj", "Bookstore.Web/"]
COPY ["Bookstore.Domain/Bookstore.Domain.csproj", "Bookstore.Domain/"]
COPY ["Bookstore.Data/Bookstore.Data.csproj", "Bookstore.Data/"]
RUN dotnet restore "Bookstore.Web/Bookstore.Web.csproj"
COPY . .
WORKDIR "/src/Bookstore.Web"
RUN dotnet build "Bookstore.Web.csproj" -c Release -o /app/build
RUN dotnet publish "Bookstore.Web.csproj" -c Release -o /app/publish

# Runtime stage
FROM mcr.microsoft.com/dotnet/aspnet:8.0
WORKDIR /app
COPY --from=build /app/publish .
EXPOSE 80
EXPOSE 443
ENTRYPOINT ["dotnet", "Bookstore.Web.dll"]
```

### Docker Compose

```yaml
version: '3.8'

services:
  web:
    build:
      context: .
      dockerfile: Dockerfile
    ports:
      - "8080:80"
    environment:
      - ASPNETCORE_ENVIRONMENT=Development
      - ConnectionStrings__BookstoreDatabaseConnection=Host=db;Database=bookstore;Username=postgres;Password=password
    depends_on:
      - db

  db:
    image: postgres:15
    environment:
      - POSTGRES_DB=bookstore
      - POSTGRES_USER=postgres
      - POSTGRES_PASSWORD=password
    ports:
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data

volumes:
  postgres_data:
```

## Deployment Options

### 1. AWS ECS Fargate (Recommended)
- Serverless container orchestration
- Automatic scaling
- No server management
- Pay per use

**Architecture**:
```
Application Load Balancer
    ↓
ECS Service (Multiple Tasks)
    ↓
ECS Tasks (Containers)
    ↓
PostgreSQL RDS
```

### 2. AWS EC2 with Docker
- More control
- Requires server management
- Cost-effective for steady workloads

### 3. AWS Elastic Beanstalk
- Platform as a Service
- Automatic deployment
- Limited customization

### 4. Self-Managed Linux Servers
- Full control
- Requires Linux administration
- Use systemd for service management

## Reverse Proxy Configuration

### Nginx Configuration

```nginx
server {
    listen 80;
    server_name bookstore.example.com;

    location / {
        proxy_pass http://localhost:5000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection keep-alive;
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

### AWS Application Load Balancer
- No additional configuration needed
- Built-in health checks
- Automatic SSL termination
- WebSocket support

## Systemd Service (Linux)

```ini
[Unit]
Description=Bob's Bookstore Web Application
After=network.target

[Service]
Type=notify
WorkingDirectory=/var/www/bookstore
ExecStart=/usr/bin/dotnet /var/www/bookstore/Bookstore.Web.dll
Restart=always
RestartSec=10
KillSignal=SIGINT
SyslogIdentifier=bookstore-web
User=www-data
Environment=ASPNETCORE_ENVIRONMENT=Production
Environment=DOTNET_PRINT_TELEMETRY_MESSAGE=false

[Install]
WantedBy=multi-user.target
```

## Configuration Management

### appsettings.json
```json
{
  "Kestrel": {
    "EndPoints": {
      "Http": {
        "Url": "http://0.0.0.0:80"
      },
      "Https": {
        "Url": "https://0.0.0.0:443"
      }
    }
  }
}
```

### Environment Variables
```bash
export ASPNETCORE_ENVIRONMENT=Production
export ConnectionStrings__BookstoreDatabaseConnection="Host=db;..."
export Services__Authentication=aws
```

## SSL/TLS Certificates

### Development
- Development certificate: `dotnet dev-certs https`

### Production
- AWS Certificate Manager (ACM) with ALB
- Let's Encrypt with certbot
- Purchase commercial certificate

## Performance Considerations

### Kestrel Advantages
- Faster than IIS for many workloads
- Lower memory footprint
- Better request throughput
- Native async support

### Tuning
```csharp
builder.WebHost.ConfigureKestrel(options =>
{
    options.Limits.MaxConcurrentConnections = 100;
    options.Limits.MaxRequestBodySize = 10 * 1024 * 1024; // 10MB
});
```

## Monitoring and Logging

### Linux Logging
- systemd journal: `journalctl -u bookstore-web`
- Application logs: CloudWatch Logs
- Metrics: CloudWatch Metrics or Prometheus

### Health Checks
```csharp
builder.Services.AddHealthChecks()
    .AddDbContextCheck<ApplicationDbContext>();

app.MapHealthChecks("/health");
```

## Security Considerations

### Linux Security
- Run as non-root user
- Use secrets management (AWS Secrets Manager)
- Keep base images updated
- Scan for vulnerabilities

### Network Security
- Security groups (AWS)
- Firewall rules
- Private subnets for databases
- VPC endpoints for AWS services

## Testing Strategy

### Local Linux Testing
```bash
# Using Docker
docker build -t bookstore:latest .
docker run -p 8080:80 bookstore:latest

# Test application
curl http://localhost:8080
```

### Cross-Platform Testing
- Test on Windows and Linux
- Verify path handling
- Check file permissions
- Test environment variable loading

## Migration Checklist

- [ ] Update code for cross-platform compatibility
- [ ] Create Dockerfile
- [ ] Test Docker build locally
- [ ] Configure Kestrel settings
- [ ] Set up reverse proxy (if needed)
- [ ] Configure systemd service (if not using containers)
- [ ] Set up SSL certificates
- [ ] Configure logging
- [ ] Set up health checks
- [ ] Security hardening
- [ ] Performance testing
- [ ] Deployment automation

## Effort Estimate

- **Dockerfile creation**: 4-6 hours
- **Code updates for cross-platform**: 4-8 hours
- **Deployment configuration**: 6-10 hours
- **Testing**: 10-15 hours
- **Documentation**: 3-5 hours
- **CI/CD setup**: 6-10 hours

**Total**: 33-54 hours
